"""Takes the App Store screenshots on three simulators.

Usage:  python3 scripts/ios_screenshots.py [folder ...]
Needs Xcode and `pip install pillow`. With no folder names, takes every set.

Writes ios/AppStore/screenshots/<device>/<n>-<screen>.png, replacing what was there.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

IOS = Path(__file__).resolve().parent.parent / "ios"
OUTPUT = IOS / "AppStore" / "screenshots"
# folder name -> simulator name
DEVICES = {
    "iphone-large": "iPhone 17 Pro Max",
    "iphone-medium": "iPhone 17 Pro",
    "ipad-13": "iPad Pro 13-inch (M5)",
}


def run(*command, **options):
    return subprocess.run(command, check=True, capture_output=True, text=True, **options)


def udid_of(name):
    devices = json.loads(run("xcrun", "simctl", "list", "devices", "available", "-j").stdout)["devices"]
    return next(d["udid"] for group in devices.values() for d in group if d["name"] == name)


def restart(udid):
    subprocess.run(["xcrun", "simctl", "shutdown", udid], capture_output=True)
    run("xcrun", "simctl", "boot", udid)
    run("xcrun", "simctl", "bootstatus", udid, "-b")


def full_screen_apps(udid, on):
    """iPadOS draws a window resize handle over apps unless they run full screen."""
    for key in ("SBChamoisWindowingEnabled", "SBMedusaMultitaskingEnabled"):
        change = ["write", "com.apple.springboard", key, "-bool", "false"] if on else ["delete", "com.apple.springboard", key]
        subprocess.run(["xcrun", "simctl", "spawn", udid, "defaults", *change], capture_output=True, check=on)
    restart(udid)


def take(folder, name, work):
    udid = udid_of(name)
    restart(udid)
    ipad = folder.startswith("ipad")
    if ipad:
        full_screen_apps(udid, True)
    run("xcrun", "simctl", "status_bar", udid, "override", "--time", "9:41", "--batteryState", "charged",
        "--batteryLevel", "100", "--wifiBars", "3", "--cellularBars", "4")
    result = work / f"{folder}.xcresult"
    try:
        run("xcodebuild", "test", "-project", "Vocab.xcodeproj", "-scheme", "Vocab",
            "-destination", f"id={udid}", "-derivedDataPath", str(work / "build"),
            "-only-testing:VocabUITests/StoreScreenshots", "-resultBundlePath", str(result),
            "-parallel-testing-enabled", "NO",  # a cloned simulator would lose the status bar
            cwd=IOS, env={**os.environ, "TEST_RUNNER_STORE_SCREENSHOTS": "1"})
    except subprocess.CalledProcessError as failure:
        errors = [line for line in failure.stdout.splitlines() if "error:" in line]
        raise SystemExit("\n".join(errors[-5:] or failure.stdout.splitlines()[-20:]))
    finally:
        run("xcrun", "simctl", "status_bar", udid, "clear")
        if ipad:
            full_screen_apps(udid, False)
        subprocess.run(["xcrun", "simctl", "shutdown", udid], capture_output=True)

    exported = work / folder
    run("xcrun", "xcresulttool", "export", "attachments", "--path", str(result), "--output-path", str(exported))
    target = OUTPUT / folder
    shutil.rmtree(target, ignore_errors=True)
    target.mkdir(parents=True)
    for test in json.loads((exported / "manifest.json").read_text()):
        for item in test["attachments"]:
            name_part = item["suggestedHumanReadableName"].split("_")[0]
            # App Store Connect rejects images with an alpha channel.
            Image.open(exported / item["exportedFileName"]).convert("RGB").save(target / f"{name_part}.png")
    for image in sorted(target.glob("*.png")):
        print(f"  {folder}/{image.name} {Image.open(image).size}")


def main():
    wanted = sys.argv[1:] or list(DEVICES)
    with tempfile.TemporaryDirectory() as temporary:
        for folder in wanted:
            print(DEVICES[folder], flush=True)
            take(folder, DEVICES[folder], Path(temporary))


if __name__ == "__main__":
    main()
