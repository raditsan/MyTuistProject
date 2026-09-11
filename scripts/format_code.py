#!/usr/bin/env python3
import os
import sys
import subprocess
from pathlib import Path
from typing import List

# ANSI color codes
RESET = "\033[0m"
BOLD = "\033[1m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
GRAY = "\033[90m"

DEFAULT_DIRS = [
    "Features",
    "Core",
    "Modules",
    "MyTuistProject/Sources",
    "Project.swift"
]

def check_swift_format_available() -> bool:
    try:
        res = subprocess.run(["swift", "format", "--version"], capture_output=True, text=True)
        return res.returncode == 0
    except Exception:
        return False

def main():
    root_dir = Path(__file__).resolve().parent.parent
    is_check_only = any(arg in ["--check", "-c", "check=true", "CHECK=1"] for arg in sys.argv[1:])
    target_path = None

    for arg in sys.argv[1:]:
        if arg.startswith("path=") or arg.startswith("PATH="):
            target_path = arg.split("=", 1)[1].strip()
        elif arg.startswith("file=") or arg.startswith("FILE="):
            target_path = arg.split("=", 1)[1].strip()
        elif not arg.startswith("-") and "check" not in arg.lower() and target_path is None:
            target_path = arg.strip()

    print(f"\n{BOLD}{CYAN}======================================================={RESET}")
    print(f"{BOLD}{CYAN}🎨 Swift Code Style & Formatting Engine{RESET}")
    print(f"{BOLD}{CYAN}======================================================={RESET}\n")

    if not check_swift_format_available():
        print(f"{RED}❌ 'swift format' tidak ditemukan di environment saat ini.{RESET}")
        print(f"💡 Pastikan Xcode Command Line Tools telah terpasang ('xcode-select --install').")
        sys.exit(1)

    # Determine targets
    if target_path:
        p = root_dir / target_path
        if not p.exists():
            print(f"{RED}❌ Path '{target_path}' tidak ditemukan di {p}{RESET}")
            sys.exit(1)
        targets = [str(p)]
    else:
        targets = [str(root_dir / d) for d in DEFAULT_DIRS if (root_dir / d).exists()]

    mode_label = "Checking Style (Lint Mode)" if is_check_only else "Formatting Code (In-Place Mode)"
    print(f"  • {BOLD}Mode{RESET}    : {YELLOW if is_check_only else GREEN}{mode_label}{RESET}")
    print(f"  • {BOLD}Targets{RESET} : {GRAY}{', '.join([Path(t).relative_to(root_dir).as_posix() for t in targets])}{RESET}\n")

    if is_check_only:
        # Lint mode
        cmd = ["swift", "format", "lint", "--recursive"] + targets
        res = subprocess.run(cmd, cwd=root_dir, capture_output=True, text=True)
        if res.returncode == 0:
            print(f"{BOLD}{GREEN}✅ Format check PASSED: Seluruh file Swift memenuhi standar penulisan kode!{RESET}\n")
            sys.exit(0)
        else:
            print(f"{BOLD}{YELLOW}⚠️  Ditemukan isu style/indentasi pada kode:{RESET}")
            errors = res.stderr.strip() or res.stdout.strip()
            lines = errors.splitlines()
            for l in lines[:30]:
                print(f"   {l}")
            if len(lines) > 30:
                print(f"   {GRAY}... dan {len(lines) - 30} baris lainnya.{RESET}")
            print(f"\n💡 Jalankan 'make format' untuk otomatis memperbaiki masalah di atas.\n")
            sys.exit(1)
    else:
        # In-place format mode
        cmd = ["swift", "format", "format", "--in-place", "--recursive"] + targets
        res = subprocess.run(cmd, cwd=root_dir, capture_output=True, text=True)
        if res.returncode == 0:
            print(f"{BOLD}{GREEN}🎉 Formatting selesai: Seluruh file Swift berhasil dirapikan secara konsisten!{RESET}\n")
            sys.exit(0)
        else:
            print(f"{RED}❌ Gagal melakukan formatting:{RESET}")
            print(res.stderr or res.stdout)
            sys.exit(1)

if __name__ == "__main__":
    main()
