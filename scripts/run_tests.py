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
    target = None
    for arg in sys.argv[1:]:
        for prefix in ["target=", "TARGET=", "feature=", "FEATURE=", "name=", "NAME=", "module=", "MODULE="]:
            if arg.startswith(prefix):
                target = arg.split("=", 1)[1].strip()
                break
        if target:
            break
        elif not arg.startswith("-") and target is None:
            target = arg.strip()

    if target and target.lower() in ["all", "semua", "true", "1"]:
        return "all"
    return target if target else "all"

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

import shutil

def print_coverage_report(xcresult_path: Path, scheme: str):
    if not xcresult_path.exists():
        return
    try:
        res = subprocess.run(
            ["xcrun", "xccov", "view", "--report", "--json", str(xcresult_path)],
            capture_output=True,
            text=True
        )
        if res.returncode != 0:
            return
        data = json.loads(res.stdout)
        targets = data.get("targets", [])

        # Filter relevant targets (exclude test bundles and external SPM packages)
        excluded_prefixes = ["Moya", "Alamofire", "FactoryKit"]
        relevant_targets = []
        for t in targets:
            name = t.get("name", "")
            if name.endswith(".xctest"):
                continue
            if any(name.startswith(p) for p in excluded_prefixes):
                continue
            # Also exclude targets with 0 executable lines
            if t.get("executableLines", 0) > 0:
                relevant_targets.append(t)

        if not relevant_targets:
            return

        print("\n" + "-" * 55)
        print(f"📈 Laporan Code Coverage: {scheme}")
        print("-" * 55)

        # Separate primary target from dependency targets
        primary_targets = []
        dependency_targets = []

        norm_scheme = scheme.lower().replace("-", "").replace("_", "")
        for t in relevant_targets:
            raw_name = t.get("name", "")
            clean_name = raw_name.replace(".framework", "").replace(".app", "").lower().replace("-", "").replace("_", "")
            if clean_name == norm_scheme:
                primary_targets.append(t)
            else:
                dependency_targets.append(t)

        # Fallback: if no exact match, try matching substring or treat first as primary
        if not primary_targets and relevant_targets:
            for t in relevant_targets:
                raw_name = t.get("name", "")
                clean_name = raw_name.replace(".framework", "").replace(".app", "").lower()
                if norm_scheme in clean_name or clean_name in norm_scheme:
                    primary_targets.append(t)
                else:
                    dependency_targets.append(t)
            if not primary_targets:
                primary_targets = [relevant_targets[0]]
                dependency_targets = relevant_targets[1:]

        # 1. Print Primary Target(s)
        for t in primary_targets:
            t_name = t.get("name", "")
            cov_pct = t.get("lineCoverage", 0.0) * 100
            cov_lines = t.get("coveredLines", 0)
            tot_lines = t.get("executableLines", 0)

            status_badge = "✅ PASSED (>80%)" if cov_pct >= 80.0 else ("⚠️ CUKUP (>50%)" if cov_pct >= 50.0 else "❌ PERLU DITINGKATKAN")
            print(f"🎯 Target Utama: {t_name}")
            print(f"   Coverage : {cov_pct:.1f}% ({cov_lines}/{tot_lines} baris) [{status_badge}]")

            files = t.get("files", [])
            if files:
                print("   Rincian File:")
                for f in sorted(files, key=lambda x: x.get("name", "")):
                    f_name = f.get("name", "")
                    f_cov = f.get("lineCoverage", 0.0) * 100
                    f_cov_lines = f.get("coveredLines", 0)
                    f_tot_lines = f.get("executableLines", 0)
                    f_icon = "  ✅" if f_cov >= 80.0 else ("  ⚠️" if f_cov >= 50.0 else "  ❌")
                    print(f"   {f_icon} {f_cov:>5.1f}%  {f_name:<28} ({f_cov_lines}/{f_tot_lines} baris)")

        # 2. Print Dependency Targets (as informative secondary section)
        if dependency_targets:
            print("\n" + "·" * 55)
            print("📦 Dependensi Terkait (Indirect / Terpanggil Parsial):")
            for t in dependency_targets:
                t_name = t.get("name", "")
                cov_pct = t.get("lineCoverage", 0.0) * 100
                cov_lines = t.get("coveredLines", 0)
                tot_lines = t.get("executableLines", 0)
                clean_target = t_name.replace(".framework", "").replace(".app", "")

                print(f"   🔹 {t_name}")
                print(f"      Coverage Terpanggil : {cov_pct:.1f}% ({cov_lines}/{tot_lines} baris)")
                print(f"      Status             : [ℹ️ DEPENDENCY - Coverage penuh diuji di 'make test {clean_target}']")
            print("·" * 55)

        print("-" * 55 + "\n")
    except Exception:
        pass

def main():
    root_dir = Path(__file__).resolve().parent.parent
    workspace_path = root_dir / "MyTuistProject.xcworkspace"
    raw_target = parse_args()

    dest, sim_name = get_best_simulator()
    all_schemes = get_workspace_schemes(workspace_path)

    # Exclude non-testable / utility schemes
    excluded_schemes = {
        "Generate Project",
        "MyTuistProject-Workspace",
        "MyTuistProject-Dev",
        "MyTuistProject-Prod",
        "MyTuistProject-UAT"
    }

    schemes_to_test = []

    if raw_target == "all":
        # Group and sort testable schemes in logical clean architecture order:
        # Core -> Domain -> Data -> Feature -> App
        core = [s for s in all_schemes if s.startswith("Core") and s not in excluded_schemes]
        domain = [s for s in all_schemes if s.startswith("Domain") and s not in excluded_schemes]
        data = [s for s in all_schemes if s.startswith("Data") and s not in excluded_schemes]
        feature = [s for s in all_schemes if s.startswith("Feature") and s not in excluded_schemes]
        app = [s for s in all_schemes if s == "MyTuistProject"]
        schemes_to_test = sorted(core) + sorted(domain) + sorted(data) + sorted(feature) + app
        print(f"\n🧪 Menjalankan pengujian untuk SEMUA modul ({len(schemes_to_test)} schemes)...")
    else:
        target_name = to_pascal_case(raw_target)
        candidates = [
            raw_target,
            target_name,
            f"Domain{target_name}",
            f"Data{target_name}",
            f"Feature{target_name}",
            f"Core{target_name}",
        ]
        # Include schemes containing target_name (e.g. FeatureProductDetail if raw_target is Product)
        for s in all_schemes:
            if s not in excluded_schemes and target_name.lower() in s.lower() and s not in candidates:
                candidates.append(s)

        matched = []
        for c in candidates:
            if c in all_schemes and c not in matched and c not in excluded_schemes:
                matched.append(c)
        schemes_to_test = matched

        if not schemes_to_test:
            available = [s for s in all_schemes if s not in excluded_schemes]
            print(f"⚠️ Tidak ditemukan scheme untuk '{raw_target}'. Scheme yang tersedia:\n{', '.join(available)}")
            sys.exit(1)
        print(f"\n🧪 Menjalankan pengujian untuk target '{raw_target}' ({len(schemes_to_test)} schemes)...")

    print(f"📱 Target Simulator: {sim_name} ({dest})")
    print(f"🎯 Schemes yang akan di-test: {', '.join(schemes_to_test)}\n")

    temp_dir = Path("/tmp/tuist_test_results")
    temp_dir.mkdir(parents=True, exist_ok=True)

    results = []
    for scheme in schemes_to_test:
        print(f"⏳ Testing scheme '{scheme}'...")
        start_time = time.time()
        result_bundle = temp_dir / f"{scheme}.xcresult"
        if result_bundle.exists():
            shutil.rmtree(result_bundle, ignore_errors=True)

        cmd = [
            "xcodebuild", "test",
            "-workspace", str(workspace_path),
            "-scheme", scheme,
            "-destination", dest,
            "-enableCodeCoverage", "YES",
            "-resultBundlePath", str(result_bundle)
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

        # Print code coverage report
        print_coverage_report(result_bundle, scheme)

        # Cleanup result bundle
        if result_bundle.exists():
            shutil.rmtree(result_bundle, ignore_errors=True)

    # Summary
    print("=" * 55)
    print("📊 Ringkasan Hasil Pengujian Unit Test")
    print("=" * 55)
    all_passed = True
    for scheme, passed, duration in results:
        status_icon = "✅ PASSED" if passed else "❌ FAILED"
        if not passed:
            all_passed = False
        print(f"  {status_icon:<10} {scheme:<25} ({duration:.1f}s)")
    print("=" * 55)

    if all_passed:
        print("🎉 Semua pengujian BERHASIL lulus!\n")
        sys.exit(0)
    else:
        print("⚠️ Ada pengujian yang GAGAL. Silakan periksa log di atas.\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
