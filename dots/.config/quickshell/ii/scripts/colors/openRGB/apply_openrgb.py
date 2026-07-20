from openrgb import OpenRGBClient
from openrgb.utils import RGBColor
from scipy.interpolate import interp1d
import os
from time import sleep
import argparse
from subprocess import Popen
import psutil
import json

parser = argparse.ArgumentParser(description="Apply color on OpenRGB devices with a smooth transition")
parser.add_argument(
    "--duration",
    "-d",
    type=float,
    default=0.5,
    help="Duraton of color swap animation",
)
parser.add_argument(
    "--interpolation-steps",
    "-i",
    type=int,
    default=100,
    help="Number of steps to swap the colors (lower=choppyer, higher=smoother)",
)
parser.add_argument(
    "--color",
    "-c",
    type=str,
    help="HEX color to transition to",

)
args = parser.parse_args()

def hexToRGB(hexColor) -> list[int]:
    hexColor = hexColor.removeprefix("#")
    hexColor = [hexColor[i : i + 2] for i in range(0, 6, 2)]  # Split hex values
    intColor = [int(hexValue, 16) for hexValue in hexColor]  # Convert to int
    return intColor


def is_openrgb_running() -> bool:
    return any(p.name() == "openrgb" for p in psutil.process_iter())


def get_client(name: str = "quickshell") -> OpenRGBClient:
    for attempt in range(MAX_SEVER_START_ATTEMPTS):
        try:
            return OpenRGBClient(name=name)
        except ConnectionRefusedError:
            if not is_openrgb_running():
                Popen(["openrgb", "--server", "--startminimized"])
            sleep(SERVER_START_RETRY_DELAY)
    raise RuntimeError(f"Could not connect to OpenRGB after {MAX_SEVER_START_ATTEMPTS} attempts")


TRANSITION_DURATION = args.duration
INTERPOLATION_STEPS = args.interpolation_steps

MAX_SEVER_START_ATTEMPTS = 10
SERVER_START_RETRY_DELAY = 0.5

xdg_state_home = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
xdg_config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
state_dir = os.path.join(xdg_state_home, "quickshell")

config_path = os.path.join(xdg_config_home, "illogical-impulse", "config.json")
with open(config_path, "r") as f:
    config = json.load(f)

client = get_client()
devices = config["appearance"]["openrgb"]["devices"]

color_file = os.path.join(state_dir, "user", "generated", "color.txt")
with open(color_file, "r") as f:
    new_color = hexToRGB(f.read())

if args.color != None:
    new_color = hexToRGB(args.color)

# Build name→index map for name-based lookup
name_to_idx = {d.name: i for i, d in enumerate(client.devices)}

resolved = []
for dev in devices:
    if not dev["enabled"]:
        continue
    name = dev.get("name")
    if name:
        idx = name_to_idx.get(name)
        if idx is None:
            print(f"Warning: device '{name}' not found, skipping")
            continue
    else:
        idx = dev["id"]
        if idx >= len(client.devices):
            print(f"Warning: device id {idx} out of range, skipping")
            continue
    resolved.append((dev, idx))

for dev, idx in resolved:
    if client.devices[idx].active_mode == 1:  # 1 = Off
        old_color = [0, 0, 0]
    else:
        old_color = [
            client.devices[idx].leds[0].colors[0].red,
            client.devices[idx].leds[0].colors[0].green,
            client.devices[idx].leds[0].colors[0].blue,
        ]
    dev["interpolation"] = interp1d([0, 1], [old_color, new_color], axis=0)
    dev["_idx"] = idx

for i in range(INTERPOLATION_STEPS):
    t = i / (INTERPOLATION_STEPS - 1)
    for dev, idx in resolved:
        interp_color = [int(c) for c in dev["interpolation"](t)]
        client.devices[idx].set_color(RGBColor(*interp_color), True)
        if client.devices[idx].active_mode != 0:
            client.devices[idx].set_mode(mode=0)
    sleep(TRANSITION_DURATION/INTERPOLATION_STEPS)
