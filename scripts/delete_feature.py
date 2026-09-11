#!/usr/bin/env python3
import os
import sys
import re
import shutil
import subprocess
from pathlib import Path

# Add script directory to sys.path to import helpers
sys.path.append(str(Path(__file__).resolve().parent))
from make_feature import to_pascal_case, to_camel_case

def parse_args():
    name = None
    force = False
    for arg in sys.argv[1:]:
        if arg in ("-y", "--yes", "--force", "-f"):
            force = True
        elif arg.startswith("name=") or arg.startswith("NAME="):
            name = arg.split("=", 1)[1]
        elif not arg.startswith("-") and name is None:
            name = arg
    return name, force

def get_existing_features(root_dir: Path):
    features_dir = root_dir / "Features"
    if not features_dir.exists():
        return []
    return sorted([
        d.name for d in features_dir.iterdir()
        if d.is_dir() and (d / "Sources").exists() and not d.name.startswith(".")
    ])

def remove_target_from_project(proj_content: str, target_name: str) -> str:
    while True:
        pattern = rf'([ \t]*(?://[^\n]*\n)*[ \t]*\.target\(\s*name:\s*"{re.escape(target_name)}",\s*(?:destinations|product))'
        match = re.search(pattern, proj_content)
        if not match:
            break

        start_pos = match.start()
        # Find start of .target(
        target_start = proj_content.find(".target(", start_pos)
        open_paren_idx = proj_content.find("(", target_start)
        if open_paren_idx == -1:
            break

        # Find matching ')'
        depth = 0
        in_string = False
        escape = False
        end_pos = -1

        for i in range(open_paren_idx, len(proj_content)):
            char = proj_content[i]
            if escape:
                escape = False
                continue
            if char == '\\':
                escape = True
                continue
            if char == '"':
                in_string = not in_string
                continue
            if not in_string:
                if char == '(':
                    depth += 1
                elif char == ')':
                    depth -= 1
                    if depth == 0:
                        end_pos = i + 1
                        break

        if end_pos == -1:
            break

        # Consume optional trailing comma and spaces/newline
        while end_pos < len(proj_content) and proj_content[end_pos] in (',', ' ', '\t'):
            end_pos += 1
        if end_pos < len(proj_content) and proj_content[end_pos] == '\n':
            end_pos += 1

        proj_content = proj_content[:start_pos] + proj_content[end_pos:]

    return proj_content

def main():
    root_dir = Path(__file__).resolve().parent.parent
    raw_name, force = parse_args()

    existing_features = get_existing_features(root_dir)

    if not raw_name:
        print("\nExisting Features:")
        for idx, f in enumerate(existing_features, 1):
            print(f"  [{idx}] {f}")

        try:
            choice = input("\nPilih Feature yang ingin DIHAPUS (nomor atau nama): ").strip()
            if choice.isdigit() and 1 <= int(choice) <= len(existing_features):
                raw_name = existing_features[int(choice) - 1]
            else:
                raw_name = choice
        except (EOFError, KeyboardInterrupt):
            print("\nOperasi dibatalkan.")
            sys.exit(1)

    if not raw_name:
        print("Error: Nama feature tidak boleh kosong.")
        sys.exit(1)

    feature_name = to_pascal_case(raw_name)
    case_name = to_camel_case(feature_name)
    module_name = f"Feature{feature_name}"
    domain_name = f"Domain{feature_name}"
    data_name = f"Data{feature_name}"

    # Verify feature existence
    feature_dir = root_dir / "Features" / feature_name
    domain_dir = root_dir / "Modules" / "Domain" / feature_name
    data_dir = root_dir / "Modules" / "Data" / feature_name

    proj_path = root_dir / "Project.swift"
    in_project = False
    if proj_path.exists():
        in_project = f'"{module_name}"' in proj_path.read_text()

    found = feature_dir.exists() or domain_dir.exists() or data_dir.exists() or in_project
    if not found:
        print(f"⚠️ Feature '{feature_name}' tidak ditemukan di Features/, Modules/, atau Project.swift.")
        sys.exit(1)

    # Confirmation
    if not force:
        try:
            confirm = input(f"⚠️ PERINGATAN: Apakah Anda yakin ingin MENGHAPUS Feature '{feature_name}' beserta modul Domain, Data, Navigasi, dan DI-nya? (y/N): ").strip()
            if confirm.lower() not in ("y", "yes"):
                print("Operasi dibatalkan.")
                sys.exit(0)
        except (EOFError, KeyboardInterrupt):
            print("\nOperasi dibatalkan.")
            sys.exit(1)

    print(f"\n🗑️  Menghapus Feature: {feature_name}...")

    # 1. Delete Directories
    for d in [feature_dir, domain_dir, data_dir]:
        if d.exists():
            shutil.rmtree(d)
            print(f"  ✅ Removed directory: {d.relative_to(root_dir)}")

    # 2. Delete Navigation & CompositionRoot Files
    files_to_delete = [
        root_dir / "Core" / "Navigation" / "Sources" / "Destinations" / f"{feature_name}Destination.swift",
        root_dir / "Core" / "Navigation" / "Sources" / "Routes" / f"{feature_name}Route.swift",
        root_dir / "MyTuistProject" / "Sources" / "CompositionRoot" / "Routes" / f"{feature_name}RouteHandler.swift",
    ]

    param_dir = root_dir / "Core" / "Navigation" / "Sources" / "Param"
    if param_dir.exists():
        for p in param_dir.glob(f"{feature_name}*ScreenParam.swift"):
            files_to_delete.append(p)

    for f in files_to_delete:
        if f.exists():
            f.unlink()
            print(f"  ✅ Removed file: {f.relative_to(root_dir)}")

    # 3. Unregister from AppRouteDestination.swift
    app_dest_path = root_dir / "Core" / "Navigation" / "Sources" / "AppRouteDestination.swift"
    if app_dest_path.exists():
        content = app_dest_path.read_text()
        pattern = r'\s*case\s+' + re.escape(case_name) + r'\(' + re.escape(feature_name) + r'Destination\)\n?'
        content = re.sub(pattern, '\n', content)
        app_dest_path.write_text(content)
        print(f"  ✅ Unregistered from AppRouteDestination.swift")

    # 4. Unregister from AppRoute.swift
    app_route_path = root_dir / "Core" / "Navigation" / "Sources" / "Routes" / "AppRoute.swift"
    if app_route_path.exists():
        content = app_route_path.read_text()
        # Remove enum case
        pattern_case = r'\s*case\s+' + re.escape(case_name) + r'\(' + re.escape(feature_name) + r'Route\)\n?'
        content = re.sub(pattern_case, '\n', content)
        # Remove destination switch branch
        pattern_dest = r'\s*case\s+\.' + re.escape(case_name) + r'\(let\s+route\):\s*\n\s*return\s+route\.destination\n?'
        content = re.sub(pattern_dest, '\n', content)
        app_route_path.write_text(content)
        print(f"  ✅ Unregistered from AppRoute.swift")

    # 5. Unregister from DeepLinkHandler.swift
    handler_path = root_dir / "Core" / "Navigation" / "Sources" / "DeepLinkHandler.swift"
    if handler_path.exists():
        content = handler_path.read_text()
        pattern_link = r'\s*' + re.escape(feature_name) + r'Route\.self,?\n?'
        content = re.sub(pattern_link, '\n', content)
        handler_path.write_text(content)
        print(f"  ✅ Unregistered from DeepLinkHandler.swift")

    # 6. Unregister from AppDIContainer.swift
    app_di_path = root_dir / "MyTuistProject" / "Sources" / "CompositionRoot" / "AppDIContainer.swift"
    if app_di_path.exists():
        content = app_di_path.read_text()
        # Remove import
        content = re.sub(r'import\s+Data' + re.escape(feature_name) + r'\n?', '', content)
        # Remove data dependencies registration
        pattern_reg = r'\s*Container\.shared\.register' + re.escape(feature_name) + r'DataDependencies\(\)\n?'
        content = re.sub(pattern_reg, '\n', content)
        # Remove navigation switch branch
        pattern_nav = r'\s*case\s+\.' + re.escape(case_name) + r'\(let\s+' + re.escape(case_name) + r'Route\):\s*\n\s*return\s+' + re.escape(feature_name) + r'RouteHandler\.buildView\(for:\s+' + re.escape(case_name) + r'Route\)\n?'
        content = re.sub(pattern_nav, '\n', content)
        app_di_path.write_text(content)
        print(f"  ✅ Unregistered from AppDIContainer.swift")

    # 7. Unregister from Project.swift
    proj_path = root_dir / "Project.swift"
    if proj_path.exists():
        proj_content = proj_path.read_text()

        # 1. Remove target declarations first
        for t in [
            f"{module_name}Tests",
            module_name,
            f"{domain_name}Tests",
            domain_name,
            f"{data_name}Tests",
            data_name,
        ]:
            proj_content = remove_target_from_project(proj_content, t)

        # 2. Remove app target dependencies
        for dep in [module_name, domain_name, data_name]:
            pattern_dep = r'^[ \t]*\.target\(name:\s*"' + re.escape(dep) + r'"\),?[ \t]*\n?'
            proj_content = re.sub(pattern_dep, '', proj_content, flags=re.MULTILINE)

        proj_path.write_text(proj_content)
        print(f"  ✅ Removed targets and dependencies from Project.swift")

    # 8. Run tuist generate
    from make_feature import run_tuist_generate
    if run_tuist_generate(root_dir):
        print(f"\n🎉 Feature '{feature_name}' berhasil dihapus dan project telah diperbarui!")
    else:
        print(f"\n💡 Jalankan 'tuist generate' secara manual untuk melihat detail masalah.")

if __name__ == "__main__":
    main()
