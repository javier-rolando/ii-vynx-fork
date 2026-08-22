//! Per-client GPU engine time, read from `/proc/<pid>/fdinfo/*`.
//!
//! The `xe` driver publishes `drm-cycles-<engine>` (this client) alongside
//! `drm-total-cycles-<engine>` (a free-running reference clock shared by every
//! client). The ratio of the two deltas is the client's share of that engine.
//!
//! Every other driver in practice — `amdgpu`, `i915`, nouveau — instead publishes
//! `drm-engine-<engine>: <n> ns`, a monotonic count of nanoseconds this client's
//! context spent active on that engine. Unlike `drm-cycles`, there is no shared
//! reference clock to divide by: the unit is already wall time, so a client's
//! share is its ns delta over the sampler's own interval instead. Summed across
//! engines the same way `drm-cycles-*` is, so a client busy on several engines at
//! once can read past 100% of the interval — `main.rs` clamps that the same way
//! it already does for the cycles path.
//!
//! A DRM client can be visible through several file descriptors and several
//! processes, so accounting is keyed on `(drm-pdev, drm-client-id)` rather than on
//! fds — otherwise a browser's shared render context is counted once per tab.

use std::collections::{HashMap, HashSet};
use std::fs;

pub struct Client {
    pub pid: u32,
    pub key: (String, u64),
    pub cycles: u64,
    /// Sum of every `drm-engine-<engine>: n ns` field, for drivers that report
    /// busy time this way instead of `drm-cycles-<engine>`.
    pub engine_ns: u64,
}

pub struct Scan {
    pub clients: Vec<Client>,
    /// The reference clock — the denominator for every share. All engines report the
    /// same free-running value, so this is a max and not a sum: summing would make
    /// the denominator depend on how many engines happened to be seen this scan,
    /// and a partial scan would then produce a nonsensical delta.
    pub total_cycles: u64,
    /// Which fds of which pids turned out to be DRM fds. A full scan has to open
    /// every fd of every process to find these; keeping the map lets the next
    /// several scans open only the two or three per process that matter, which is
    /// the difference between reading ~8000 fdinfo files and reading ~40.
    pub gpu_fds: HashMap<u32, Vec<u32>>,
}

fn parse_fdinfo(text: &str) -> Option<(String, u64, u64, u64, HashMap<String, u64>)> {
    let mut pdev = String::new();
    let mut client_id = None;
    let mut cycles = 0u64;
    let mut engine_ns = 0u64;
    let mut totals: HashMap<String, u64> = HashMap::new();

    for line in text.lines() {
        let Some((k, v)) = line.split_once(':') else {
            continue;
        };
        let v = v.trim();
        match k {
            "drm-pdev" => pdev = v.to_string(),
            "drm-client-id" => client_id = v.parse::<u64>().ok(),
            _ if k.starts_with("drm-total-cycles-") => {
                let engine = k["drm-total-cycles-".len()..].to_string();
                totals.insert(engine, v.parse().unwrap_or(0));
            }
            _ if k.starts_with("drm-cycles-") => {
                cycles += v.parse::<u64>().unwrap_or(0);
            }
            // drm-engine-capacity-<engine> is an instance count, not a duration —
            // it never carries a " ns" suffix, so the strip_suffix rejects it too,
            // but the prefix check keeps the intent obvious.
            _ if k.starts_with("drm-engine-") && !k.starts_with("drm-engine-capacity-") => {
                if let Some(ns) = v.strip_suffix(" ns") {
                    engine_ns += ns.trim().parse::<u64>().unwrap_or(0);
                }
            }
            _ => {}
        }
    }

    Some((pdev, client_id?, cycles, engine_ns, totals))
}

struct Acc {
    seen: HashSet<(String, u64)>,
    clients: Vec<Client>,
    engines: HashMap<String, u64>,
    gpu_fds: HashMap<u32, Vec<u32>>,
}

fn read_fd(acc: &mut Acc, pid: u32, fd: u32) {
    let Ok(text) = fs::read_to_string(format!("/proc/{pid}/fdinfo/{fd}")) else {
        return;
    };
    // Cheapest possible reject: fdinfo for a pipe or socket is three lines.
    if !text.contains("drm-client-id") {
        return;
    }
    let Some((pdev, id, cycles, engine_ns, totals)) = parse_fdinfo(&text) else {
        return;
    };

    for (engine, total) in totals {
        let slot = acc.engines.entry(engine).or_insert(0);
        *slot = (*slot).max(total);
    }
    acc.gpu_fds.entry(pid).or_default().push(fd);

    let key = (pdev, id);
    if acc.seen.insert(key.clone()) {
        acc.clients.push(Client { pid, key, cycles, engine_ns });
    }
}

/// Find every DRM client on the system, opening every fd of every process.
fn scan_full(acc: &mut Acc) {
    let Ok(procs) = fs::read_dir("/proc") else { return };
    for entry in procs.flatten() {
        let name = entry.file_name();
        let Some(pid) = name.to_str().and_then(|n| n.parse::<u32>().ok()) else {
            continue;
        };
        let Ok(fds) = fs::read_dir(format!("/proc/{pid}/fdinfo")) else {
            continue;
        };
        for fd in fds.flatten() {
            let name = fd.file_name();
            let Some(fd) = name.to_str().and_then(|n| n.parse::<u32>().ok()) else {
                continue;
            };
            read_fd(acc, pid, fd);
        }
    }
}

/// Re-read only the fds a previous full scan identified as DRM fds.
///
/// An fd that has since been closed simply fails to read, and one whose number was
/// recycled for something else no longer contains `drm-client-id` — both drop out of
/// the map on their own. A DRM fd opened *since* the last full scan is missed until
/// the next one, which is why a new window forces a full scan.
fn scan_known(acc: &mut Acc, known: &HashMap<u32, Vec<u32>>) {
    for (&pid, fds) in known {
        for &fd in fds {
            read_fd(acc, pid, fd);
        }
    }
}

pub fn scan(known: &HashMap<u32, Vec<u32>>, full: bool) -> Scan {
    let mut acc = Acc {
        seen: HashSet::new(),
        clients: Vec::new(),
        engines: HashMap::new(),
        gpu_fds: HashMap::new(),
    };

    if full {
        scan_full(&mut acc);
    } else {
        scan_known(&mut acc, known);
    }

    Scan {
        clients: acc.clients,
        total_cycles: acc.engines.values().copied().max().unwrap_or(0),
        gpu_fds: acc.gpu_fds,
    }
}
