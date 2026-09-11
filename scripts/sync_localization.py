#!/usr/bin/env python3
import sys
import re
from pathlib import Path
from typing import Dict, List, Tuple, Set, Optional

# ANSI color codes
RESET = "\033[0m"
BOLD = "\033[1m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
GRAY = "\033[90m"
MAGENTA = "\033[35m"

def parse_strings_file(file_path: Path) -> Tuple[Dict[str, str], List[Tuple[int, str]], List[Tuple[int, str]]]:
    """
    Parses a .strings file.
    Returns (entries_dict, duplicates_list, syntax_errors_list)
    """
    entries = {}
    duplicates = []
    syntax_errors = []

    content = file_path.read_text(encoding="utf-8")
    lines = content.splitlines()

    in_multiline_comment = False

    for idx, line in enumerate(lines, start=1):
        stripped = line.strip()

        # Handle multi-line comments /* ... */
        if "/*" in stripped:
            in_multiline_comment = True
        if "*/" in stripped:
            in_multiline_comment = False
            continue
        if in_multiline_comment:
            continue

        # Skip empty lines and single-line comments
        if not stripped or stripped.startswith("//"):
            continue

        # Match "key" = "value";
        # Supports escaped quotes
        pattern = r'^"((?:[^"\\]|\\.)+)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;'
        m = re.match(pattern, stripped)
        if m:
            key = m.group(1)
            val = m.group(2)
            if key in entries:
                duplicates.append((idx, key))
            entries[key] = val
        else:
            # If line looks like an assignment but failed to match valid syntax
            if "=" in stripped and not stripped.startswith("/*"):
                syntax_errors.append((idx, stripped))

    return entries, duplicates, syntax_errors

def extract_format_specifiers(s: str) -> List[str]:
    # Matches %@, %d, %ld, %u, %f, %.2f, %s, etc.
    return re.findall(r'%[0-9\.]*[a-zA-Z@]', s)

def main():
    root_dir = Path(__file__).resolve().parent.parent
    loc_res_dir = root_dir / "Core" / "Localization" / "Resources"
    auto_sync = "--sync" in sys.argv or "-s" in sys.argv

    print(f"\n{BOLD}{CYAN}======================================================={RESET}")
    print(f"{BOLD}{CYAN}🌐 MyTuistProject Localization Consistency Validator{RESET}")
    print(f"{BOLD}{CYAN}======================================================={RESET}\n")

    en_file = loc_res_dir / "en.lproj" / "Localizable.strings"
    id_file = loc_res_dir / "id.lproj" / "Localizable.strings"

    if not en_file.exists():
        print(f"{RED}❌ File en.lproj/Localizable.strings tidak ditemukan di {en_file}{RESET}")
        sys.exit(1)
    if not id_file.exists():
        print(f"{RED}❌ File id.lproj/Localizable.strings tidak ditemukan di {id_file}{RESET}")
        sys.exit(1)

    en_entries, en_dups, en_errors = parse_strings_file(en_file)
    id_entries, id_dups, id_errors = parse_strings_file(id_file)

    has_issue = False

    # 1. Check syntax errors
    if en_errors:
        has_issue = True
        print(f"{RED}❌ Syntax error di en.lproj/Localizable.strings:{RESET}")
        for line_no, content in en_errors:
            print(f"   Baris {line_no}: {content}")
        print()

    if id_errors:
        has_issue = True
        print(f"{RED}❌ Syntax error di id.lproj/Localizable.strings:{RESET}")
        for line_no, content in id_errors:
            print(f"   Baris {line_no}: {content}")
        print()

    # 2. Check duplicates
    if en_dups:
        has_issue = True
        print(f"{YELLOW}⚠️  Duplicate key di en.lproj/Localizable.strings:{RESET}")
        for line_no, key in en_dups:
            print(f"   Baris {line_no}: {key}")
        print()

    if id_dups:
        has_issue = True
        print(f"{YELLOW}⚠️  Duplicate key di id.lproj/Localizable.strings:{RESET}")
        for line_no, key in id_dups:
            print(f"   Baris {line_no}: {key}")
        print()

    # 3. Check parity (en vs id)
    en_keys = set(en_entries.keys())
    id_keys = set(id_entries.keys())

    missing_in_id = en_keys - id_keys
    obsolete_in_id = id_keys - en_keys

    # 4. Check format specifiers mismatch
    common_keys = en_keys & id_keys
    specifier_mismatches = []
    for k in common_keys:
        en_specs = extract_format_specifiers(en_entries[k])
        id_specs = extract_format_specifiers(id_entries[k])
        if en_specs != id_specs:
            specifier_mismatches.append((k, en_specs, id_specs))

    if specifier_mismatches:
        has_issue = True
        print(f"{RED}❌ Format specifier mismatch (bisa menyebabkan runtime crash):{RESET}")
        for k, en_s, id_s in specifier_mismatches:
            print(f"   • {BOLD}{k}{RESET}")
            print(f"     EN: {en_entries[k]} {GRAY}(specs: {en_s}){RESET}")
            print(f"     ID: {id_entries[k]} {GRAY}(specs: {id_s}){RESET}")
        print()

    print(f"{BOLD}📊 Status Terjemahan:{RESET}")
    print(f"   • {BOLD}English (en.lproj){RESET}    : {GREEN}{len(en_keys)} keys{RESET}")
    print(f"   • {BOLD}Indonesian (id.lproj){RESET} : {GREEN}{len(id_keys)} keys{RESET}")

    if missing_in_id:
        has_issue = True
        print(f"\n{YELLOW}⚠️  {len(missing_in_id)} key ada di English tapi BELUM diterjemahkan ke Indonesian:{RESET}")
        for k in sorted(missing_in_id):
            print(f"   • {BOLD}{k}{RESET} = \"{en_entries[k]}\"")

        if auto_sync:
            print(f"\n{CYAN}🔄 Menambahkan key yang hilang ke id.lproj/Localizable.strings...{RESET}")
            sync_text = "\n\n/* MARK: - Auto-Synced Keys (Needs Translation) */\n"
            for k in sorted(missing_in_id):
                sync_text += f'"{k}" = "[TODO] {en_entries[k]}";\n'

            with open(id_file, "a", encoding="utf-8") as f:
                f.write(sync_text)
            print(f"{GREEN}✅ Berhasil menambahkan {len(missing_in_id)} key dengan tag '[TODO]'.{RESET}")
            has_issue = False
        else:
            print(f"\n💡 Jalankan 'make sync-localization' untuk otomatis menyinkronkan key dengan tag '[TODO]'.")

    if obsolete_in_id:
        print(f"\n{GRAY}ℹ️  {len(obsolete_in_id)} key ada di Indonesian tapi tidak ada di English (mungkin sudah deprecated):{RESET}")
        for k in sorted(obsolete_in_id):
            print(f"   • {k}")

    print()
    if not has_issue:
        print(f"{BOLD}{GREEN}🎉 SEMPURNA: File Localizable.strings 100% sinkron dan bebas error syntax!{RESET}\n")
        sys.exit(0)
    else:
        print(f"{BOLD}{RED}❌ Ditemukan ketidakkonsistenan pada file lokalisasi. Silakan periksa rincian di atas.{RESET}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
