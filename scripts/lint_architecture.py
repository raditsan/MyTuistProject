#!/usr/bin/env python3
import sys
import re
from pathlib import Path
from dataclasses import dataclass
from typing import List, Tuple

# ANSI color codes
RESET = "\033[0m"
BOLD = "\033[1m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
GRAY = "\033[90m"

@dataclass
class LintRule:
    id: str
    target_glob: str
    forbidden_pattern: str
    name: str
    rationale: str

RULES: List[LintRule] = [
    # 1. Feature Layer
    LintRule(
        id="ARCH-FEAT-01",
        target_glob="Features/*/Sources/**/*.swift",
        forbidden_pattern=r"import\s+Data[A-Za-z0-9_]+",
        name="Feature UI layer must not import Data layer directly",
        rationale="Features should only depend on Domain use cases and entities, not concrete Data repositories or DTOs."
    ),
    LintRule(
        id="ARCH-FEAT-02",
        target_glob="Features/*/Sources/**/*.swift",
        forbidden_pattern=r"import\s+(Moya|CombineMoya)",
        name="Feature UI layer must not import Moya directly",
        rationale="Network communication details belong in CoreNetwork and Data layers."
    ),

    # 2. Domain Layer (Pure Business Logic)
    LintRule(
        id="ARCH-DOM-01",
        target_glob="Modules/Domain/*/Sources/**/*.swift",
        forbidden_pattern=r"import\s+Data[A-Za-z0-9_]+",
        name="Domain layer must not depend on Data layer",
        rationale="Domain contains pure business rules and repository interfaces. Inversion of Dependency requires Data to depend on Domain, never vice-versa."
    ),
    LintRule(
        id="ARCH-DOM-02",
        target_glob="Modules/Domain/*/Sources/**/*.swift",
        forbidden_pattern=r"import\s+(SwiftUI|UIKit)",
        name="Domain layer must be UI-framework agnostic (no SwiftUI/UIKit)",
        rationale="Domain should be pure Swift and reusable across any platform or UI framework."
    ),
    LintRule(
        id="ARCH-DOM-03",
        target_glob="Modules/Domain/*/Sources/**/*.swift",
        forbidden_pattern=r"import\s+(Moya|CombineMoya)",
        name="Domain layer must not import networking libraries (Moya)",
        rationale="Domain defines abstract repository protocols; network execution is an infrastructure detail in Data."
    ),
    LintRule(
        id="ARCH-DOM-04",
        target_glob="Modules/Domain/*/Sources/**/*.swift",
        forbidden_pattern=r"import\s+Core(DesignSystem|Navigation)",
        name="Domain layer must not depend on UI Design System or Navigation",
        rationale="Domain represents business logic and should have zero knowledge of view presentation or navigation."
    ),

    # 3. Data Layer
    LintRule(
        id="ARCH-DATA-01",
        target_glob="Modules/Data/*/Sources/**/*.swift",
        forbidden_pattern=r"import\s+(SwiftUI|UIKit)",
        name="Data layer must not import UI frameworks (SwiftUI/UIKit)",
        rationale="Data handles persistence, remote APIs, and mappings. It must have no presentation dependency."
    ),
    LintRule(
        id="ARCH-DATA-02",
        target_glob="Modules/Data/*/Sources/**/*.swift",
        forbidden_pattern=r"import\s+Feature[A-Za-z0-9_]+",
        name="Data layer must not depend on Feature modules",
        rationale="Feature modules are higher-level presentation consumers; Data must never depend on Features."
    ),

    # 4. Core Infrastructure Modules
    LintRule(
        id="ARCH-CORE-01",
        target_glob="Core/*/Sources/**/*.swift",
        forbidden_pattern=r"import\s+(Domain|Data|Feature)[A-Za-z0-9_]+",
        name="Core infrastructure modules must not import Feature, Domain, or Data modules",
        rationale="Core modules (Network, Navigation, DesignSystem, etc.) are reusable foundational building blocks."
    ),
    LintRule(
        id="ARCH-CORE-02",
        target_glob="Core/DesignSystem/Sources/**/*.swift",
        forbidden_pattern=r"import\s+CoreNetwork",
        name="CoreDesignSystem must not depend on CoreNetwork",
        rationale="UI Design System tokens and components must remain decoupled from networking."
    ),
    LintRule(
        id="ARCH-CORE-03",
        target_glob="Core/Navigation/Sources/**/*.swift",
        forbidden_pattern=r"import\s+CoreNetwork",
        name="CoreNavigation must not depend on CoreNetwork",
        rationale="Navigation route definitions and coordinator protocols must not depend on network communication."
    ),
]

@dataclass
class Violation:
    rule: LintRule
    file_path: Path
    line_number: int
    line_content: str

def lint_architecture(root_dir: Path) -> List[Violation]:
    violations: List[Violation] = []
    scanned_files = set()

    for rule in RULES:
        regex = re.compile(rule.forbidden_pattern)
        matched_files = list(root_dir.glob(rule.target_glob))
        for file in matched_files:
            scanned_files.add(file)
            try:
                content = file.read_text(encoding="utf-8")
            except Exception as e:
                print(f"{YELLOW}⚠️ Could not read {file.relative_to(root_dir)}: {e}{RESET}")
                continue

            for idx, line in enumerate(content.splitlines(), start=1):
                # Skip comments
                stripped = line.strip()
                if stripped.startswith("//") or stripped.startswith("/*") or stripped.startswith("*"):
                    continue

                if regex.search(line):
                    violations.append(Violation(
                        rule=rule,
                        file_path=file,
                        line_number=idx,
                        line_content=stripped
                    ))

    return violations, len(scanned_files)

def main():
    root_dir = Path(__file__).resolve().parent.parent
    print(f"\n{BOLD}{CYAN}======================================================={RESET}")
    print(f"{BOLD}{CYAN}📐 Clean Architecture Rule Validator{RESET}")
    print(f"{BOLD}{CYAN}======================================================={RESET}\n")

    violations, total_files = lint_architecture(root_dir)

    if not violations:
        print(f"{GREEN}✅ Clean Architecture Validation PASSED!{RESET}")
        print(f"{GRAY}   Scanned {total_files} Swift source files across all layers.{RESET}")
        print(f"{GRAY}   Verified {len(RULES)} architecture boundary rules.{RESET}\n")
        sys.exit(0)
    else:
        print(f"{RED}❌ Found {len(violations)} Clean Architecture Violation(s):{RESET}\n")
        for v in violations:
            rel_path = v.file_path.relative_to(root_dir)
            print(f"  {RED}● [{v.rule.id}] {v.rule.name}{RESET}")
            print(f"    {BOLD}File:{RESET} {rel_path}:{v.line_number}")
            print(f"    {BOLD}Line:{RESET} {GRAY}{v.line_content}{RESET}")
            print(f"    {YELLOW}💡 Rationale:{RESET} {v.rule.rationale}\n")

        print(f"{RED}Architecture lint failed with {len(violations)} violation(s).{RESET}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
