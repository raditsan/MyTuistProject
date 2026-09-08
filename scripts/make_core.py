#!/usr/bin/env python3
import os
import sys
import re
import subprocess
from pathlib import Path

# Add script directory to sys.path to import helpers
sys.path.append(str(Path(__file__).resolve().parent))
from make_feature import to_pascal_case, to_camel_case

def parse_args():
    name = None
    for arg in sys.argv[1:]:
        if arg.startswith("name=") or arg.startswith("NAME="):
            name = arg.split("=", 1)[1]
        elif not arg.startswith("-") and name is None:
            name = arg

    if not name:
        try:
            name = input("Masukkan nama Core module baru (misal: Analytics, Storage, Security): ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nOperasi dibatalkan.")
            sys.exit(1)

    if not name:
        print("Error: Nama Core module tidak boleh kosong.")
        sys.exit(1)

    return name

def main():
    root_dir = Path(__file__).resolve().parent.parent
    raw_name = parse_args()

    # Clean prefix 'core' if user passed 'CoreAnalytics' or 'core-analytics'
    raw_name = re.sub(r'^(core|Core)[_\-\s]*', '', raw_name)
    core_name = to_pascal_case(raw_name)
    case_name = to_camel_case(core_name)
    module_name = f"Core{core_name}"

    print(f"\n🚀 Membuat Core Foundation Module: {module_name} (Core/{core_name})...")

    core_dir = root_dir / "Core" / core_name
    (core_dir / "Sources").mkdir(parents=True, exist_ok=True)
    (core_dir / "Tests").mkdir(parents=True, exist_ok=True)

    # 1. Service/Client Protocol & Implementation
    service_path = core_dir / "Sources" / f"{core_name}Service.swift"
    if not service_path.exists():
        template_service = f"""import Foundation

public protocol {core_name}ServiceProtocol: Sendable {{
    func performAction() async throws
}}

public final class {core_name}Service: {core_name}ServiceProtocol, @unchecked Sendable {{
    public init() {{}}

    public func performAction() async throws {{
        // Implementation for {core_name}Service
    }}
}}
"""
        service_path.write_text(template_service)
        print(f"  ✅ Created: {service_path.relative_to(root_dir)}")

    # 2. Container+Core<Name>.swift
    container_path = core_dir / "Sources" / f"Container+Core{core_name}.swift"
    if not container_path.exists():
        template_container = f"""import Foundation
import FactoryKit

extension Container {{
    public var {case_name}Service: Factory<{core_name}ServiceProtocol> {{
        self {{ {core_name}Service() }}.singleton
    }}
}}
"""
        container_path.write_text(template_container)
        print(f"  ✅ Created: {container_path.relative_to(root_dir)}")

    # 3. Unit Tests
    test_path = core_dir / "Tests" / f"{core_name}ServiceTests.swift"
    if not test_path.exists():
        template_test = f"""import XCTest
import FactoryKit
@testable import {module_name}

final class {core_name}ServiceTests: XCTestCase {{
    private var sut: {core_name}Service!

    override func setUp() {{
        super.setUp()
        sut = {core_name}Service()
    }}

    override func tearDown() {{
        sut = nil
        super.tearDown()
    }}

    func test_performAction_success() async throws {{
        try await sut.performAction()
        XCTAssertNotNil(sut)
    }}

    func test_containerRegistration() {{
        let service = Container.shared.{case_name}Service()
        XCTAssertNotNil(service)
    }}
}}
"""
        test_path.write_text(template_test)
        print(f"  ✅ Created: {test_path.relative_to(root_dir)}")

    # 4. Update Project.swift
    proj_path = root_dir / "Project.swift"
    proj_content = proj_path.read_text()

    # 4a. Add dependency to MyTuistProject app target
    dep_str = f'.target(name: "{module_name}"),'
    pattern_app_dep = r'(name:\s*"MyTuistProject",[\s\S]*?dependencies:\s*\[)([\s\S]*?)(\n\s*\]\s*\n\s*\),)'
    m_app = re.search(pattern_app_dep, proj_content)
    if m_app and dep_str not in m_app.group(2):
        updated_deps = m_app.group(2).rstrip() + f'\n                {dep_str}'
        proj_content = proj_content[:m_app.start(2)] + updated_deps + proj_content[m_app.end(2):]
        print(f"  ✅ Added {dep_str} to MyTuistProject dependencies in Project.swift")

    # 4b. Add Core targets if not present
    if f'name: "{module_name}",' not in proj_content:
        core_targets_code = f"""
        // MARK: - Core {core_name}
        .target(
            name: "{module_name}",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.{module_name}",
            deploymentTargets: deploymentTargets,
            sources: [
                "Core/{core_name}/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit")
            ]
        ),
        .target(
            name: "{module_name}Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.{module_name}Tests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: [
                "Core/{core_name}/Tests/**"
            ],
            dependencies: [
                .target(name: "{module_name}"),
                .external(name: "FactoryKit")
            ]
        ),
"""
        pattern_targets_end = r'(\n\s*\]\s*\n\))'
        proj_content = re.sub(pattern_targets_end, rf'{core_targets_code}\1', proj_content)
        print(f"  ✅ Added {module_name} and {module_name}Tests targets in Project.swift")

    proj_path.write_text(proj_content)

    # 5. Run tuist generate
    print("\n📦 Menjalankan 'tuist generate --no-open'...")
    res = subprocess.run(["tuist", "generate", "--no-open"], cwd=root_dir)
    if res.returncode == 0:
        print(f"\n🎉 Core module '{module_name}' berhasil dibuat dan diregistrasikan ke project!")
    else:
        print(f"\n⚠️ 'tuist generate' selesai dengan kode {res.returncode}. Silakan periksa Project.swift.")

if __name__ == "__main__":
    main()
