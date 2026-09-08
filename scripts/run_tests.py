#!/usr/bin/env python3
import os
import sys
import json
import time
import subprocess
from pathlib import Path

# Add script directory to sys.path to import helpers
sys.path.append(str(Path(__file__).resolve().parent))
from make_feature import to_pascal_case

def parse_args():
    feature = None
    for arg in sys.argv[1:]:
        if arg.startswith("feature=") or arg.startswith("FEATURE="):
            feature = arg.split("=", 1)[1]
        elif not arg.startswith("-") and feature is None:
            feature = arg
    return feature

def get_best_simulator():
    try:
        res = subprocess.run(["xcrun", "simctl", "list", "devices", "available", "-j"], capture_output=True, text=True)
        if res.returncode == 0:
            data = json.loads(res.stdout)
            devices = data.get("devices", {})

            # 1. Prioritize currently Booted iOS Simulator
            for runtime, dev_list in devices.items():
                if "iOS" in runtime:
                    for dev in dev_list:
                        if dev.get("state") == "Booted" and dev.get("isAvailable"):
                            return f"id={dev.get('udid')}", dev.get("name")

            # 2. Prioritize modern iPhones (17, 16, 15)
            preferred_names = ["iPhone 17", "iPhone 16", "iPhone 15", "iPhone 14"]
            for pref in preferred_names:
                for runtime in sorted(devices.keys(), reverse=True):
                    if "iOS" in runtime:
                        for dev in devices[runtime]:
                            if dev.get("name") == pref and dev.get("isAvailable"):
                                return f"id={dev.get('udid')}", dev.get("name")

            # 3. Any available iPhone
            for runtime in sorted(devices.keys(), reverse=True):
                if "iOS" in runtime:
                    for dev in devices[runtime]:
                        if "iPhone" in dev.get("name", "") and dev.get("isAvailable"):
                            return f"id={dev.get('udid')}", dev.get("name")
    except Exception as e:
        pass

    # Fallback default
    return "platform=iOS Simulator,name=iPhone 17", "iPhone 17 (Default)"

def get_workspace_schemes(workspace_path: Path):
    try:
        res = subprocess.run(["xcodebuild", "-workspace", str(workspace_path), "-list", "-json"], capture_output=True, text=True)
        if res.returncode == 0:
            data = json.loads(res.stdout)
            return data.get("workspace", {}).get("schemes", [])
    except Exception:
        pass

    # Text fallback
    res = subprocess.run(["xcodebuild", "-workspace", str(workspace_path), "-list"], capture_output=True, text=True)
    schemes = []
    recording = False
    for line in res.stdout.splitlines():
        if "Schemes:" in line:
            recording = True
            continue
        if recording:
            line_str = line.strip()
            if line_str and not line_str.startswith("Information about"):
                schemes.append(line_str)
    return schemes

def main():
    root_dir = Path(__file__).resolve().parent.parent
    workspace_path = root_dir / "MyTuistProject.xcworkspace"
    raw_feature = parse_args()

    dest, sim_name = get_best_simulator()
    all_schemes = get_workspace_schemes(workspace_path)

    schemes_to_test = []

    if raw_feature:
        feature_name = to_pascal_case(raw_feature)
        candidates = [
            raw_feature,
            feature_name,
            f"Domain{feature_name}",
            f"Data{feature_name}",
            f"Feature{feature_name}",
            f"Core{feature_name}",
        ]
        # Preserve order while deduplicating
        matched = []
        for c in candidates:
            if c in all_schemes and c not in matched:
                matched.append(c)
        schemes_to_test = matched
        if not schemes_to_test:
            print(f"⚠️ Tidak ditemukan scheme untuk '{raw_feature}'. Scheme yang tersedia:\n{', '.join(all_schemes)}")
            sys.exit(1)
        print(f"\n🧪 Menjalankan pengujian untuk '{raw_feature}'...")
    else:
        # Default run all feature/domain/data and app schemes
        if "MyTuistProject" in all_schemes:
            schemes_to_test = ["MyTuistProject"]
        else:
            schemes_to_test = [s for s in all_schemes if s.startswith("Feature") or s.startswith("Domain") or s.startswith("Data")]
        print(f"\n🧪 Menjalankan pengujian untuk target aplikasi...")

    print(f"📱 Target Simulator: {sim_name} ({dest})")
    print(f"🎯 Schemes yang akan di-test: {', '.join(schemes_to_test)}\n")

    results = []
    for scheme in schemes_to_test:
        print(f"⏳ Testing scheme '{scheme}'...")
        start_time = time.time()
        cmd = [
            "xcodebuild", "test",
            "-workspace", str(workspace_path),
            "-scheme", scheme,
            "-destination", dest
        ]
        proc = subprocess.run(cmd, cwd=root_dir, capture_output=True, text=True)
        duration = time.time() - start_time

        if proc.returncode == 0:
            print(f"  ✅ {scheme}: PASSED ({duration:.1f}s)")
            results.append((scheme, True, duration))
        else:
            print(f"  ❌ {scheme}: FAILED ({duration:.1f}s)")
            # Print brief error snippet
            for line in proc.stdout.splitlines()[-25:]:
                print(f"     {line}")
            results.append((scheme, False, duration))

    # Summary
    print("\n" + "=" * 50)
    print("📊 Hasil Pengujian Unit Test")
    print("=" * 50)
    all_passed = True
    for scheme, passed, duration in results:
        status_icon = "✅ PASSED" if passed else "❌ FAILED"
        if not passed:
            all_passed = False
        print(f"  {status_icon:<10} {scheme:<25} ({duration:.1f}s)")
    print("=" * 50)

    if all_passed:
        print("🎉 Semua pengujian BERHASIL lulus!\n")
        sys.exit(0)
    else:
        print("⚠️ Ada pengujian yang GAGAL. Silakan periksa log di atas.\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
