#!/usr/bin/env python3
import os
import sys
import shutil
import glob
import subprocess
from pathlib import Path

# ANSI color codes
RESET = "\033[0m"
BOLD = "\033[1m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
GRAY = "\033[90m"

def run_tuist_clean(root_dir: Path) -> bool:
    print(f"{CYAN}🧹 [1/4] Membersihkan cache Tuist ('tuist clean')...{RESET}")
    res = subprocess.run(["tuist", "clean"], cwd=root_dir, capture_output=True, text=True)
    if res.returncode == 0:
        print(f"   {GREEN}✅ Tuist cache berhasil dibersihkan.{RESET}")
        return True
    else:
        print(f"   {YELLOW}⚠️  Peringatan saat tuist clean: {res.stderr.strip() or res.stdout.strip()}{RESET}")
        return False

def clean_derived_data() -> int:
    print(f"{CYAN}🧹 [2/4] Membersihkan Xcode DerivedData untuk MyTuistProject...{RESET}")
    home = Path.home()
    dd_pattern = str(home / "Library/Developer/Xcode/DerivedData/MyTuistProject*")
    matches = glob.glob(dd_pattern)
    count = 0
    for path_str in matches:
        p = Path(path_str)
        try:
            if p.is_dir():
                shutil.rmtree(p)
            else:
                p.unlink()
            print(f"   {GREEN}✅ Dihapus: {p.name}{RESET}")
            count += 1
        except Exception as e:
            print(f"   {YELLOW}⚠️  Gagal menghapus {p.name}: {e}{RESET}")

    if count == 0:
        print(f"   {GRAY}ℹ️  Tidak ada DerivedData MyTuistProject yang ditemukan.{RESET}")
    return count

def clean_local_artifacts(root_dir: Path) -> int:
    print(f"{CYAN}🧹 [3/4] Membersihkan file project lokal (Derived/, .xcodeproj, .xcworkspace)...{RESET}")
    count = 0

    # 1. Derived directory
    derived_dir = root_dir / "Derived"
    if derived_dir.exists():
        try:
            shutil.rmtree(derived_dir)
            print(f"   {GREEN}✅ Dihapus: Derived/{RESET}")
            count += 1
        except Exception as e:
            print(f"   {YELLOW}⚠️  Gagal menghapus Derived/: {e}{RESET}")

    # 2. *.xcodeproj and *.xcworkspace in root
    for item in root_dir.iterdir():
        if item.is_dir() and (item.name.endswith(".xcodeproj") or item.name.endswith(".xcworkspace")):
            try:
                shutil.rmtree(item)
                print(f"   {GREEN}✅ Dihapus: {item.name}{RESET}")
                count += 1
            except Exception as e:
                print(f"   {YELLOW}⚠️  Gagal menghapus {item.name}: {e}{RESET}")

    # 3. .build folder if any
    build_dir = root_dir / ".build"
    if build_dir.exists():
        try:
            shutil.rmtree(build_dir)
            print(f"   {GREEN}✅ Dihapus: .build/{RESET}")
            count += 1
        except Exception as e:
            print(f"   {YELLOW}⚠️  Gagal menghapus .build/: {e}{RESET}")

    return count

def run_tuist_install(root_dir: Path) -> bool:
    print(f"\n{CYAN}📦 [4/5] Mengunduh dependensi external ('tuist install')...{RESET}")
    res = subprocess.run(["tuist", "install"], cwd=root_dir, capture_output=True, text=True)
    if res.returncode == 0:
        print(f"   {GREEN}✅ External dependencies berhasil diunduh.{RESET}")
        return True
    else:
        print(f"   {RED}❌ 'tuist install' gagal (Kode: {res.returncode}):{RESET}")
        err = res.stderr.strip() or res.stdout.strip()
        for line in err.splitlines():
            print(f"      {line}")
        return False

def main():
    root_dir = Path(__file__).resolve().parent.parent
    no_generate = "--no-generate" in sys.argv or "-n" in sys.argv

    print(f"\n{BOLD}{CYAN}======================================================={RESET}")
    print(f"{BOLD}{CYAN}🧼 MyTuistProject Deep Clean & Reset Cache{RESET}")
    print(f"{BOLD}{CYAN}======================================================={RESET}\n")

    # 1. Tuist Clean
    run_tuist_clean(root_dir)

    # 2. DerivedData
    clean_derived_data()

    # 3. Local generated artifacts
    clean_local_artifacts(root_dir)

    # 4. Install dependencies & Regenerate
    if not no_generate:
        if not run_tuist_install(root_dir):
            print(f"\n{BOLD}{RED}❌ Gagal mengunduh dependensi setelah clean.{RESET}\n")
            sys.exit(1)

        print(f"\n{CYAN}📦 [5/5] Regenerasi project bersih ('tuist generate --no-open')...{RESET}")
        from make_feature import run_tuist_generate
        success = run_tuist_generate(root_dir)
        if success:
            print(f"\n{BOLD}{GREEN}✨ Deep clean dan regenerasi project selesai dengan sukses!{RESET}\n")
            sys.exit(0)
        else:
            print(f"\n{BOLD}{RED}❌ Gagal melakukan regenerasi project setelah clean.{RESET}\n")
            sys.exit(1)
    else:
        print(f"\n{GRAY}ℹ️  Install dan regenerasi dilewati (--no-generate).{RESET}")
        print(f"\n{BOLD}{GREEN}✨ Deep clean selesai!{RESET}\n")
        sys.exit(0)

if __name__ == "__main__":
    main()
