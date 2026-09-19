#!/usr/bin/env python3
import sys
import os
import subprocess
import argparse
import json
import re

parser = argparse.ArgumentParser(description="Apply color on OpenRGB devices")
parser.add_argument("--duration", "-d", type=float, default=0.5, help="Unused, kept for compatibility")
parser.add_argument("--interpolation-steps", "-i", type=int, default=100, help="Unused, kept for compatibility")
parser.add_argument("--color", "-c", type=str, help="HEX color to apply")
args = parser.parse_args()

xdg_state_home = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
xdg_config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
state_dir = os.path.join(xdg_state_home, "quickshell")

config_path = os.path.join(xdg_config_home, "illogical-impulse", "config.json")
if not os.path.exists(config_path):
    config_path = os.path.join(xdg_config_home, "immaterial-impulse", "config.json")
if not os.path.exists(config_path):
    sys.exit(0)

try:
    with open(config_path, "r") as f:
        config = json.load(f)
except Exception:
    sys.exit(0)

openrgb_opts = config.get("appearance", {}).get("openrgb", {})
if not openrgb_opts.get("enable", False):
    sys.exit(0)

devices = openrgb_opts.get("devices", [])
if not any(d.get("enabled", False) for d in devices):
    sys.exit(0)

color = args.color
if color is None:
    color_file = os.path.join(state_dir, "user", "generated", "color.txt")
    if not os.path.exists(color_file):
        sys.exit(0)
    try:
        with open(color_file, "r") as f:
            color = f.read().strip()
    except Exception:
        sys.exit(0)

color = color.lstrip("#")

try:
    result = subprocess.run(["openrgb", "--list-devices"], capture_output=True, text=True, timeout=10)
    name_to_id = {}
    for line in result.stdout.splitlines():
        m = re.match(r"^(\d+):\s+(.+)$", line.strip())
        if m:
            name_to_id[m.group(2).strip()] = int(m.group(1))
except Exception:
    sys.exit(0)

for dev in devices:
    if not dev.get("enabled", False):
        continue
    name = dev.get("name")
    mode = dev.get("mode", 1)
    if name:
        dev_id = name_to_id.get(name)
        if dev_id is None:
            print(f"Warning: device '{name}' not found, skipping")
            continue
    elif dev.get("id") is not None:
        dev_id = dev["id"]
    else:
        continue

    mode_name = "static" if mode == 1 else "direct"
    subprocess.run(
        ["openrgb", "--device", str(dev_id), "--mode", mode_name, "--color", color],
        capture_output=True, timeout=10
    )
