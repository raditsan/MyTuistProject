#!/usr/bin/env python3
import os
import sys
import json
import time
import subprocess
from pathlib import Path
from typing import Optional, Tuple, Dict

# ANSI color codes
RESET = "\033[0m"
BOLD = "\033[1m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
GRAY = "\033[90m"
MAGENTA = "\033[35m"

CONFIGS = {
    "dev": {
        "scheme": "MyTuistProject-Dev",
        "bundle_id": "dev.tuist.MyTuistProject.dev",
        "name": "MyTuist (Dev)"
    },
    "uat": {
        "scheme": "MyTuistProject-UAT",
        "bundle_id": "dev.tuist.MyTuistProject.uat",
        "name": "MyTuist (UAT)"
    },
    "prod": {
        "scheme": "MyTuistProject-Prod",
        "bundle_id": "dev.tuist.MyTuistProject",
        "name": "MyTuist"
    }
}

def get_simulator(device_override: Optional[str] = None) -> Tuple[str, str, bool]:
    """Returns (udid, device_name, is_booted)"""
    res = subprocess.run(["xcrun", "simctl", "list", "devices", "available", "-j"], capture_output=True, text=True)
    if res.returncode != 0:
        return "", "", False

    data = json.loads(res.stdout)
    devices = data.get("devices", {})

    # 1. If override provided
    if device_override:
        clean_override = device_override.lower()
        for runtime, dev_list in devices.items():
            if "iOS" in runtime:
                for dev in dev_list:
                    if clean_override in dev.get("name", "").lower() or clean_override == dev.get("udid", "").lower():
                        return dev.get("udid"), dev.get("name"), (dev.get("state") == "Booted")

    # 2. Prioritize currently Booted iOS Simulator
    for runtime, dev_list in devices.items():
        if "iOS" in runtime:
            for dev in dev_list:
                if dev.get("state") == "Booted" and dev.get("isAvailable"):
                    return dev.get("udid"), dev.get("name"), True

    # 3. Prioritize modern iPhones
    preferred_names = ["iPhone 17", "iPhone 16", "iPhone 15", "iPhone 14"]
    for pref in preferred_names:
        for runtime in sorted(devices.keys(), reverse=True):
            if "iOS" in runtime:
                for dev in devices[runtime]:
                    if dev.get("name") == pref and dev.get("isAvailable"):
                        return dev.get("udid"), dev.get("name"), (dev.get("state") == "Booted")

    # 4. Fallback to any available iPhone
    for runtime in sorted(devices.keys(), reverse=True):
        if "iOS" in runtime:
            for dev in devices[runtime]:
                if "iPhone" in dev.get("name", "") and dev.get("isAvailable"):
                    return dev.get("udid"), dev.get("name"), (dev.get("state") == "Booted")

    return "", "", False

def boot_simulator(udid: str, is_booted: bool, open_simulator: bool = True):
    if not is_booted:
        print(f"📱 Menyalakan Simulator (UDID: {udid})...")
        subprocess.run(["xcrun", "simctl", "boot", udid], capture_output=True)
        # Give simulator a moment to boot
        time.sleep(2)
    else:
        print(f"📱 Simulator sudah dalam kondisi aktif (Booted).")

    if open_simulator:
        subprocess.run(["open", "-a", "Simulator"], capture_output=True)

def parse_args():
    env = "dev"
    device = None
    build_only = False
    no_open = False

    for arg in sys.argv[1:]:
        if arg.startswith("env=") or arg.startswith("ENV="):
            val = arg.split("=", 1)[1].strip().lower()
            if val in CONFIGS:
                env = val
        elif arg.startswith("device=") or arg.startswith("DEVICE="):
            device = arg.split("=", 1)[1].strip()
        elif arg in ["--build-only", "-b", "build"]:
            build_only = True
        elif arg in ["--no-open"]:
            no_open = True
        elif not arg.startswith("-") and arg.lower() in CONFIGS:
            env = arg.lower()

    return env, device, build_only, no_open

def build_app(root_dir: Path, scheme: str, udid: str) -> Optional[Path]:
    derived_data = root_dir / ".build" / "DerivedData"
    cmd = [
        "xcodebuild",
        "-workspace", "MyTuistProject.xcworkspace",
        "-scheme", scheme,
        "-destination", f"id={udid}",
        "-derivedDataPath", str(derived_data),
        "build"
    ]

    print(f"\n🔨 Membangun scheme '{scheme}' untuk Simulator...")
    start_time = time.time()
    
    proc = subprocess.Popen(cmd, cwd=root_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    build_failed = False
    last_lines = []

    for line in proc.stdout:
        last_lines.append(line.rstrip())
        if len(last_lines) > 25:
            last_lines.pop(0)
        if "error:" in line.lower() or "fatal error:" in line.lower():
            print(f"   {RED}{line.strip()}{RESET}")
            build_failed = True

    proc.wait()
    duration = time.time() - start_time

    if proc.returncode != 0 or build_failed:
        print(f"\n{RED}❌ Kompilasi GAGAL ({duration:.1f}s):{RESET}")
        for l in last_lines[-15:]:
            print(f"   {GRAY}{l}{RESET}")
        return None

    print(f"   {GREEN}✅ Kompilasi BERHASIL ({duration:.1f}s)!{RESET}")

    # Find .app in products directory dynamically
    products_dir = derived_data / "Build" / "Products"
    apps = list(products_dir.glob("*-iphonesimulator/*.app"))
    if not apps:
        print(f"{RED}❌ File .app tidak ditemukan di {products_dir}{RESET}")
        return None

    # Sort by modification time (most recent first)
    apps.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return apps[0]

def get_bundle_identifier(app_path: Path) -> Optional[str]:
    info_plist = app_path / "Info.plist"
    if not info_plist.exists():
        return None
    res = subprocess.run(["plutil", "-extract", "CFBundleIdentifier", "raw", str(info_plist)], capture_output=True, text=True)
    if res.returncode == 0 and res.stdout.strip():
        return res.stdout.strip()
    return None

def main():
    root_dir = Path(__file__).resolve().parent.parent
    env, device, build_only, no_open = parse_args()
    cfg = CONFIGS[env]

    print(f"\n{BOLD}{CYAN}======================================================={RESET}")
    print(f"{BOLD}{CYAN}🚀 MyTuistProject App Runner{RESET}")
    print(f"{BOLD}{CYAN}======================================================={RESET}")
    print(f"  • {BOLD}Environment{RESET} : {GREEN}{cfg['name']}{RESET} ({cfg['scheme']})")
    print(f"  • {BOLD}Bundle ID{RESET}   : {GRAY}{cfg['bundle_id']}{RESET}")

    # 1. Resolve Simulator
    udid, dev_name, is_booted = get_simulator(device)
    if not udid:
        print(f"\n{RED}❌ Tidak menemukan iOS Simulator yang tersedia.{RESET}")
        sys.exit(1)

    print(f"  • {BOLD}Target Device{RESET} : {CYAN}{dev_name}{RESET} (id={udid})")

    # 2. Build App
    app_path = build_app(root_dir, cfg["scheme"], udid)
    if not app_path:
        sys.exit(1)

    if build_only:
        print(f"\n{GREEN}✨ Build berhasil! File: {app_path.relative_to(root_dir)}{RESET}\n")
        sys.exit(0)

    # 3. Boot & Launch
    print(f"\n🚀 Menyiapkan Simulator dan menjalankan aplikasi...")
    boot_simulator(udid, is_booted, open_simulator=not no_open)

    # Install
    print(f"📦 Menginstal aplikasi ({app_path.name})...")
    inst_res = subprocess.run(["xcrun", "simctl", "install", udid, str(app_path)], capture_output=True, text=True)
    if inst_res.returncode != 0:
        print(f"{RED}❌ Gagal menginstal ke Simulator: {inst_res.stderr.strip()}{RESET}")
        sys.exit(1)

    # Launch
    bundle_id = get_bundle_identifier(app_path) or cfg["bundle_id"]
    print(f"▶️  Menjalankan {bundle_id}...")
    launch_res = subprocess.run(["xcrun", "simctl", "launch", udid, bundle_id], capture_output=True, text=True)
    if launch_res.returncode == 0:
        print(f"\n{BOLD}{GREEN}🎉 Aplikasi '{cfg['name']}' berhasil berjalan di Simulator {dev_name}!{RESET}\n")
    else:
        print(f"{RED}❌ Gagal menjalankan aplikasi: {launch_res.stderr.strip()}{RESET}")
        sys.exit(1)

if __name__ == "__main__":
    main()
