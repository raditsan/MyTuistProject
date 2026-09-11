#!/usr/bin/env python3
import os
import sys
import re
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ANSI color codes
RESET = "\033[0m"
BOLD = "\033[1m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
GRAY = "\033[90m"
MAGENTA = "\033[35m"

def run_cmd(cmd: List[str]) -> Tuple[int, str]:
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return res.returncode, res.stdout.strip() or res.stderr.strip()
    except Exception as e:
        return -1, str(e)

def get_tooling_info() -> Dict[str, str]:
    info = {}

    # macOS
    _, os_ver = run_cmd(["sw_vers", "-productVersion"])
    _, os_build = run_cmd(["sw_vers", "-buildVersion"])
    info["macOS"] = f"{os_ver} (Build {os_build})" if os_ver else "Unknown"

    # Xcode
    _, xcode_out = run_cmd(["xcodebuild", "-version"])
    xcode_match = re.search(r"Xcode\s+([0-9\.]+)", xcode_out)
    build_match = re.search(r"Build version\s+([0-9A-Za-z]+)", xcode_out)
    if xcode_match:
        info["Xcode"] = f"{xcode_match.group(1)} ({build_match.group(1) if build_match else ''})"
    else:
        info["Xcode"] = "Not detected"

    # Swift
    _, swift_out = run_cmd(["swift", "--version"])
    swift_match = re.search(r"Apple Swift version\s+([0-9\.]+)", swift_out)
    if swift_match:
        info["Swift"] = swift_match.group(1)
    else:
        info["Swift"] = "Not detected"

    # Tuist
    _, tuist_out = run_cmd(["tuist", "version"])
    if tuist_out and "\n" not in tuist_out:
        info["Tuist"] = tuist_out.strip()
    else:
        first_line = tuist_out.splitlines()[0] if tuist_out else "Not detected"
        info["Tuist"] = first_line

    return info

class FeatureHealth:
    def __init__(self, name: str):
        self.name = name
        # Feature layer
        self.feat_views = False
        self.feat_viewmodels = False
        self.feat_tests = False
        # Domain layer
        self.domain_entity = False
        self.domain_repo_proto = False
        self.domain_usecase = False
        self.domain_di = False
        self.domain_tests = False
        # Data layer
        self.data_dto = False
        self.data_datasource = False
        self.data_endpoint = False
        self.data_repo = False
        self.data_di = False
        self.data_tests = False
        # Navigation
        self.nav_route = False
        self.nav_dest = False
        self.nav_param = False
        # Registrations
        self.reg_proj_targets = False
        self.reg_proj_deps = False
        self.reg_app_di = False
        self.reg_app_route = False
        self.reg_deeplink = False

    @property
    def feature_ok(self) -> bool:
        return self.feat_views and self.feat_viewmodels

    @property
    def domain_ok(self) -> bool:
        return self.domain_entity and self.domain_repo_proto and self.domain_usecase and self.domain_di

    @property
    def data_ok(self) -> bool:
        return self.data_dto and self.data_datasource and self.data_repo and self.data_di

    @property
    def nav_ok(self) -> bool:
        return self.nav_route and self.nav_dest

    @property
    def tests_ok(self) -> bool:
        return self.feat_tests and self.domain_tests and self.data_tests

    @property
    def reg_ok(self) -> bool:
        return (self.reg_proj_targets and self.reg_proj_deps and 
                self.reg_app_di and self.reg_app_route and self.reg_deeplink)

    @property
    def is_healthy(self) -> bool:
        return (self.feature_ok and self.domain_ok and self.data_ok and 
                self.nav_ok and self.tests_ok and self.reg_ok)

def to_camel_case(s: str) -> str:
    if not s:
        return ""
    return s[0].lower() + s[1:]

def inspect_feature(root_dir: Path, name: str, proj_content: str, di_content: str, app_route_content: str, deeplink_content: str) -> Tuple[FeatureHealth, str]:
    fh = FeatureHealth(name)
    case_name = to_camel_case(name)

    feat_dir = root_dir / "Features" / name
    domain_dir = root_dir / "Modules" / "Domain" / name
    data_dir = root_dir / "Modules" / "Data" / name

    feat_swift_files = list(feat_dir.glob("**/*.swift")) if feat_dir.exists() else []
    domain_swift_files = list(domain_dir.glob("**/*.swift")) if domain_dir.exists() else []
    data_swift_files = list(data_dir.glob("**/*.swift")) if data_dir.exists() else []

    # Detect category
    if not feat_swift_files and not domain_swift_files and not data_swift_files:
        category = "EMPTY"
    elif domain_swift_files or data_swift_files or f'name: "Domain{name}",' in proj_content:
        category = "CLEAN_ARCH"
    else:
        category = "UI_ONLY"

    # 1. Feature Layer
    fh.feat_views = any((feat_dir / "Sources").glob("**/Views/*.swift")) or any((feat_dir / "Sources").glob("**/*View.swift"))
    fh.feat_viewmodels = any((feat_dir / "Sources").glob("**/ViewModels/*.swift")) or any((feat_dir / "Sources").glob("**/*ViewModel.swift"))
    fh.feat_tests = any((feat_dir / "Tests").glob("**/*.swift"))

    # 2. Domain Layer
    if category == "CLEAN_ARCH":
        fh.domain_entity = any((domain_dir / "Sources").glob("**/Entities/*.swift")) or any((domain_dir / "Sources").glob(f"**/{name}.swift"))
        fh.domain_repo_proto = any((domain_dir / "Sources").glob("**/Repositories/*Protocol.swift")) or any((domain_dir / "Sources").glob(f"**/{name}RepositoryProtocol.swift"))
        fh.domain_usecase = any((domain_dir / "Sources").glob("**/UseCases/*.swift")) or any((domain_dir / "Sources").glob("**/*UseCase*.swift"))
        fh.domain_di = any((domain_dir / "Sources").glob("**/Container+*.swift")) or any((domain_dir / "Sources").glob("**/DI/*.swift"))
        fh.domain_tests = any((domain_dir / "Tests").glob("**/*.swift"))
    else:
        fh.domain_entity = True
        fh.domain_repo_proto = True
        fh.domain_usecase = True
        fh.domain_di = True
        fh.domain_tests = True

    # 3. Data Layer
    if category == "CLEAN_ARCH":
        fh.data_dto = any((data_dir / "Sources").glob("**/DTOs/*.swift")) or any((data_dir / "Sources").glob("**/*DTO*.swift"))
        fh.data_datasource = any((data_dir / "Sources").glob("**/DataSources/*.swift")) or any((data_dir / "Sources").glob("**/*DataSource*.swift"))
        # Endpoint can be in Endpoints/ or defined inside DataSource or client
        has_endpoint_dir = any((data_dir / "Sources").glob("**/Endpoints/*.swift"))
        has_target_type = False
        for sf in data_swift_files:
            try:
                if "TargetType" in sf.read_text():
                    has_target_type = True
                    break
            except Exception:
                pass
        fh.data_endpoint = has_endpoint_dir or has_target_type
        fh.data_repo = any((data_dir / "Sources").glob("**/Repositories/*.swift")) or any((data_dir / "Sources").glob(f"**/{name}Repository.swift"))
        fh.data_di = any((data_dir / "Sources").glob("**/Container+*.swift")) or any((data_dir / "Sources").glob("**/DI/*.swift"))
        fh.data_tests = any((data_dir / "Tests").glob("**/*.swift"))
    else:
        fh.data_dto = True
        fh.data_datasource = True
        fh.data_endpoint = True
        fh.data_repo = True
        fh.data_di = True
        fh.data_tests = True

    # 4. Navigation
    nav_dir = root_dir / "Core" / "Navigation" / "Sources"
    routes_dir = nav_dir / "Routes"
    route_handlers_dir = root_dir / "MyTuistProject" / "Sources" / "CompositionRoot" / "Routes"

    has_own_nav = (routes_dir / f"{name}Route.swift").exists() and (nav_dir / "Destinations" / f"{name}Destination.swift").exists()
    has_app_route = re.search(r"case\s+" + re.escape(case_name) + r"(\(|\b)", app_route_content, re.IGNORECASE) is not None
    
    # Check if mentioned in any Route file or RouteHandler
    has_parent_route = False
    if routes_dir.exists():
        for rf in routes_dir.glob("*.swift"):
            try:
                if name.lower() in rf.read_text().lower():
                    has_parent_route = True
                    break
            except Exception:
                pass

    has_route_handler = False
    if route_handlers_dir.exists():
        for rhf in route_handlers_dir.glob("*.swift"):
            try:
                if f"Feature{name}" in rhf.read_text() or f"{name}View" in rhf.read_text():
                    has_route_handler = True
                    break
            except Exception:
                pass

    fh.nav_route = has_own_nav or has_app_route or has_parent_route or has_route_handler
    fh.nav_dest = has_own_nav or has_app_route or has_parent_route or has_route_handler
    fh.nav_param = True # Param is optional depending on route requirements

    # 5. Registrations
    feat_targets = [f'name: "Feature{name}",', f'name: "Feature{name}Tests",']
    if category == "CLEAN_ARCH":
        feat_targets += [
            f'name: "Domain{name}",',
            f'name: "Domain{name}Tests",',
            f'name: "Data{name}",',
            f'name: "Data{name}Tests",'
        ]
    fh.reg_proj_targets = all(t in proj_content for t in feat_targets)

    feat_deps = [f'.target(name: "Feature{name}")']
    if category == "CLEAN_ARCH":
        feat_deps += [
            f'.target(name: "Domain{name}")',
            f'.target(name: "Data{name}")'
        ]
    fh.reg_proj_deps = all(d in proj_content for d in feat_deps)

    if category == "CLEAN_ARCH":
        fh.reg_app_di = (
            f'import Data{name}' in di_content and
            f'register{name}DataDependencies()' in di_content and
            (f'{name}RouteHandler' in di_content or has_route_handler)
        )
    else:
        # For UI only features, check if route handler or view is linked in CompositionRoot
        fh.reg_app_di = (f'{name}RouteHandler' in di_content or f'{name}View' in di_content or has_route_handler or not fh.nav_route)

    fh.reg_app_route = fh.nav_route
    fh.reg_deeplink = True # Optional per feature

    return fh, category

class CoreHealth:
    def __init__(self, name: str, sources_ok: bool, tests_ok: bool, target_ok: bool, dep_ok: bool):
        self.name = name
        self.sources_ok = sources_ok
        self.tests_ok = tests_ok
        self.target_ok = target_ok
        self.dep_ok = dep_ok

    @property
    def is_healthy(self) -> bool:
        return self.sources_ok and self.tests_ok and self.target_ok and self.dep_ok

def print_doctor_report(root_dir: Path):
    print(f"\n{BOLD}{CYAN}======================================================={RESET}")
    print(f"{BOLD}{CYAN}🩺 MyTuistProject System Doctor{RESET}")
    print(f"{BOLD}{CYAN}======================================================={RESET}\n")

    # 1. Environment Info
    print(f"{BOLD}🛠  Environment & Tooling:{RESET}")
    tools = get_tooling_info()
    for tool, val in tools.items():
        color = GREEN if "Not" not in val else RED
        print(f"   • {tool:<10}: {color}{val}{RESET}")
    print()

    # Read project reference files
    proj_file = root_dir / "Project.swift"
    proj_content = proj_file.read_text() if proj_file.exists() else ""

    app_di_file = root_dir / "MyTuistProject" / "Sources" / "CompositionRoot" / "AppDIContainer.swift"
    app_di_content = app_di_file.read_text() if app_di_file.exists() else ""

    app_route_file = root_dir / "Core" / "Navigation" / "Sources" / "Routes" / "AppRoute.swift"
    app_route_content = app_route_file.read_text() if app_route_file.exists() else ""

    deeplink_file = root_dir / "Core" / "Navigation" / "Sources" / "DeepLinkHandler.swift"
    deeplink_content = deeplink_file.read_text() if deeplink_file.exists() else ""

    # 2. Features Check
    features_dir = root_dir / "Features"
    feature_names = sorted([d.name for d in features_dir.iterdir() if d.is_dir() and not d.name.startswith(".")]) if features_dir.exists() else []

    print(f"{BOLD}📦 Features Health ({len(feature_names)} features found):{RESET}")
    all_features_healthy = True
    for fn in feature_names:
        fh, category = inspect_feature(root_dir, fn, proj_content, app_di_content, app_route_content, deeplink_content)
        if category == "EMPTY":
            print(f"   [{YELLOW}EMPTY{RESET}] {BOLD}{fn}{RESET} (Empty directory - no Swift files found)")
            print()
            continue

        status_badge = f"{GREEN}PASS{RESET}" if fh.is_healthy else f"{RED}FAIL{RESET}"
        if not fh.is_healthy:
            all_features_healthy = False

        type_label = "Full Clean Architecture" if category == "CLEAN_ARCH" else "Presentation Only (UI)"
        print(f"   [{status_badge}] {BOLD}{fn}{RESET} {GRAY}({type_label}){RESET}")
        print(f"       • Feature Layer : {'✅' if fh.feature_ok else '❌ Views/VM incomplete'} (Views: {'✓' if fh.feat_views else '✗'}, VMs: {'✓' if fh.feat_viewmodels else '✗'})")
        if category == "CLEAN_ARCH":
            print(f"       • Domain Layer  : {'✅' if fh.domain_ok else '❌ Incomplete'} (Entity: {'✓' if fh.domain_entity else '✗'}, RepoProto: {'✓' if fh.domain_repo_proto else '✗'}, UseCase: {'✓' if fh.domain_usecase else '✗'}, DI: {'✓' if fh.domain_di else '✗'})")
            print(f"       • Data Layer    : {'✅' if fh.data_ok else '❌ Incomplete'} (DTO: {'✓' if fh.data_dto else '✗'}, DS: {'✓' if fh.data_datasource else '✗'}, Endpt: {'✓' if fh.data_endpoint else '✗'}, Repo: {'✓' if fh.data_repo else '✗'}, DI: {'✓' if fh.data_di else '✗'})")
        else:
            print(f"       • Domain / Data : {GRAY}N/A (UI-Only Feature){RESET}")
        print(f"       • Navigation    : {'✅' if fh.nav_ok else '❌ Incomplete'} (Route: {'✓' if fh.nav_route else '✗'}, Destination: {'✓' if fh.nav_dest else '✗'})")
        print(f"       • Unit Tests    : {'✅' if fh.tests_ok else '⚠️ Incomplete'} (Feat: {'✓' if fh.feat_tests else '✗'}{', Domain: ' + ('✓' if fh.domain_tests else '✗') + ', Data: ' + ('✓' if fh.data_tests else '✗') if category == 'CLEAN_ARCH' else ''})")
        print(f"       • Registrations : {'✅' if fh.reg_ok else '❌ Incomplete'} (Targets: {'✓' if fh.reg_proj_targets else '✗'}, AppDeps: {'✓' if fh.reg_proj_deps else '✗'}, AppDI: {'✓' if fh.reg_app_di else '✗'})")
        print()

    # 3. Core Modules Check
    core_dir = root_dir / "Core"
    core_modules = sorted([d.name for d in core_dir.iterdir() if d.is_dir() and not d.name.startswith(".")]) if core_dir.exists() else []

    print(f"{BOLD}⚙️  Core Modules Health ({len(core_modules)} modules found):{RESET}")
    all_core_healthy = True
    for cn in core_modules:
        c_path = core_dir / cn
        sources_ok = (c_path / "Sources").exists() and any((c_path / "Sources").glob("**/*.swift"))
        tests_ok = (c_path / "Tests").exists() and any((c_path / "Tests").glob("**/*.swift"))
        target_name = f"Core{cn}" if not cn.startswith("Core") else cn
        target_ok = f'name: "{target_name}",' in proj_content
        dep_ok = f'.target(name: "{target_name}")' in proj_content

        ch = CoreHealth(cn, sources_ok, tests_ok, target_ok, dep_ok)
        if not ch.is_healthy:
            all_core_healthy = False
        badge = f"{GREEN}PASS{RESET}" if ch.is_healthy else f"{YELLOW}WARN{RESET}"
        print(f"   [{badge}] {BOLD}{target_name}{RESET}: Sources: {'✅' if sources_ok else '❌'}, Tests: {'✅' if tests_ok else '⚠️'}, Project.swift: {'✅' if (target_ok and dep_ok) else '❌'}")
    print()

    # 4. Orphan & Integrity Check
    print(f"{BOLD}🔍 Integrity & Orphan Detection:{RESET}")
    orphans = []

    # Empty feature directories
    for fn in feature_names:
        feat_dir = root_dir / "Features" / fn
        if not any(feat_dir.glob("**/*.swift")):
            orphans.append(f"Empty feature directory with no Swift files: 'Features/{fn}' (can be deleted or scaffolded)")

    # Domain without Feature
    domain_dir = root_dir / "Modules" / "Domain"
    if domain_dir.exists():
        for d in domain_dir.iterdir():
            if d.is_dir() and not d.name.startswith("."):
                if not any(d.glob("**/*.swift")):
                    orphans.append(f"Empty domain directory: 'Modules/Domain/{d.name}'")
                elif d.name not in feature_names:
                    orphans.append(f"Domain module 'Domain{d.name}' exists without matching 'Features/{d.name}'")

    # Data without Domain
    data_dir = root_dir / "Modules" / "Data"
    if data_dir.exists():
        for d in data_dir.iterdir():
            if d.is_dir() and not d.name.startswith("."):
                if not any(d.glob("**/*.swift")):
                    orphans.append(f"Empty data directory: 'Modules/Data/{d.name}'")
                elif not (domain_dir / d.name).exists():
                    orphans.append(f"Data module 'Data{d.name}' exists without matching 'Domain{d.name}'")

    if not orphans:
        print(f"   {GREEN}✅ No orphaned layers or mismatched modules detected.{RESET}")
    else:
        for o in orphans:
            print(f"   {YELLOW}⚠️  {o}{RESET}")
    print()

    # Overall Summary
    print(f"{BOLD}======================================================={RESET}")
    if all_features_healthy and all_core_healthy:
        print(f"{BOLD}{GREEN}🎉 PROJECT HEALTH: EXCELLENT (All active modules healthy & complete){RESET}")
    else:
        print(f"{BOLD}{YELLOW}⚠️ PROJECT HEALTH: ISSUES DETECTED - Review above checklist{RESET}")
    print(f"{BOLD}======================================================={RESET}\n")

def print_feature_list(root_dir: Path):
    print(f"\n{BOLD}{CYAN}========================================================================================{RESET}")
    print(f"{BOLD}{CYAN}📋 MyTuistProject Modules & Features Inventory{RESET}")
    print(f"{BOLD}{CYAN}========================================================================================{RESET}\n")

    proj_file = root_dir / "Project.swift"
    proj_content = proj_file.read_text() if proj_file.exists() else ""
    app_di_file = root_dir / "MyTuistProject" / "Sources" / "CompositionRoot" / "AppDIContainer.swift"
    app_di_content = app_di_file.read_text() if app_di_file.exists() else ""
    app_route_file = root_dir / "Core" / "Navigation" / "Sources" / "Routes" / "AppRoute.swift"
    app_route_content = app_route_file.read_text() if app_route_file.exists() else ""
    deeplink_file = root_dir / "Core" / "Navigation" / "Sources" / "DeepLinkHandler.swift"
    deeplink_content = deeplink_file.read_text() if deeplink_file.exists() else ""

    features_dir = root_dir / "Features"
    feature_names = sorted([d.name for d in features_dir.iterdir() if d.is_dir() and not d.name.startswith(".")]) if features_dir.exists() else []

    header = f"{'Feature':<16} | {'Type':<12} | {'Views':<8} | {'Domain':<8} | {'Data':<10} | {'Nav':<6} | {'Tests':<6} | {'Status'}"
    divider = "-" * 94
    print(f"{BOLD}{header}{RESET}")
    print(divider)

    for fn in feature_names:
        fh, category = inspect_feature(root_dir, fn, proj_content, app_di_content, app_route_content, deeplink_content)
        if category == "EMPTY":
            print(f"{GRAY}{fn:<16} | {'Empty':<12} | {'-':<8} | {'-':<8} | {'-':<8} | {'-':<6} | {'-':<6} | EMPTY{RESET}")
            continue

        type_str = "Clean Arch" if category == "CLEAN_ARCH" else "UI Only"
        f_feat = f"{GREEN}✓ Views{RESET}" if fh.feature_ok else f"{RED}✗ Incomp{RESET}"
        f_dom = (f"{GREEN}✓ Pure{RESET}" if fh.domain_ok else f"{RED}✗ Incomp{RESET}") if category == "CLEAN_ARCH" else f"{GRAY}N/A{RESET}"
        f_dat = (f"{GREEN}✓ Complete{RESET}" if fh.data_ok else f"{RED}✗ Incomp{RESET}") if category == "CLEAN_ARCH" else f"{GRAY}N/A{RESET}"
        f_nav = f"{GREEN}✓{RESET}" if fh.nav_ok else f"{RED}✗{RESET}"
        f_tst = f"{GREEN}✓{RESET}" if fh.tests_ok else f"{YELLOW}partial{RESET}"
        status = f"{GREEN}{BOLD}READY{RESET}" if fh.is_healthy else f"{YELLOW}{BOLD}ATTN{RESET}"

        print(f"{BOLD}{fn:<16}{RESET} | {type_str:<12} | {f_feat:<17} | {f_dom:<17} | {f_dat:<19} | {f_nav:<15} | {f_tst:<15} | {status}")

    print(divider)

    # Core Modules Summary
    core_dir = root_dir / "Core"
    core_modules = sorted([d.name for d in core_dir.iterdir() if d.is_dir() and not d.name.startswith(".")]) if core_dir.exists() else []
    print(f"\n{BOLD}⚙️  Infrastructure & Core Modules:{RESET}")
    for cn in core_modules:
        target_name = f"Core{cn}" if not cn.startswith("Core") else cn
        c_path = core_dir / cn
        tests_ok = (c_path / "Tests").exists() and any((c_path / "Tests").glob("**/*.swift"))
        t_badge = f"{GREEN}✓ Tests{RESET}" if tests_ok else f"{YELLOW}- No tests{RESET}"
        print(f"   • {BOLD}{target_name:<20}{RESET} [{t_badge}]")

    print()

def main():
    root_dir = Path(__file__).resolve().parent.parent
    is_list_mode = any(arg in sys.argv[1:] for arg in ["--list", "-l", "list"])

    if is_list_mode:
        print_feature_list(root_dir)
    else:
        print_doctor_report(root_dir)

if __name__ == "__main__":
    main()
