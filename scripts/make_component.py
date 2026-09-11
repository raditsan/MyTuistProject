#!/usr/bin/env python3
import os
import sys
import re
import subprocess
from pathlib import Path

# Add script directory to sys.path to import helpers
sys.path.append(str(Path(__file__).resolve().parent))
from make_feature import to_pascal_case, insert_targets_into_project

def parse_args():
    name = None
    for arg in sys.argv[1:]:
        if arg.startswith("name=") or arg.startswith("NAME="):
            name = arg.split("=", 1)[1]
        elif not arg.startswith("-") and name is None:
            name = arg

    if not name:
        try:
            name = input("Masukkan nama UI Component baru (misal: PrimaryButton, Badge, Card): ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nOperasi dibatalkan.")
            sys.exit(1)

    if not name:
        print("Error: Nama component tidak boleh kosong.")
        sys.exit(1)

    return name

def main():
    root_dir = Path(__file__).resolve().parent.parent
    raw_name = parse_args()
    component_name = to_pascal_case(raw_name)

    print(f"\n🎨 Membuat Design System Component: {component_name}...")

    components_dir = root_dir / "Core" / "DesignSystem" / "Sources" / "Components"
    tests_dir = root_dir / "Core" / "DesignSystem" / "Tests"
    components_dir.mkdir(parents=True, exist_ok=True)
    tests_dir.mkdir(parents=True, exist_ok=True)

    # 1. Component View
    component_path = components_dir / f"{component_name}.swift"
    if not component_path.exists():
        template_component = f"""import SwiftUI

public struct {component_name}: View {{
    public let title: String
    public let action: (() -> Void)?

    public init(
        title: String,
        action: (() -> Void)? = nil
    ) {{
        self.title = title
        self.action = action
    }}

    public var body: some View {{
        Button(action: {{
            action?()
        }}) {{
            Text(title)
                .font(.headline)
                .foregroundColor(DesignTokens.Colors.background)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.primary)
                .cornerRadius(DesignTokens.CornerRadius.md)
        }}
    }}
}}

#Preview {{
    VStack(spacing: DesignTokens.Spacing.md) {{
        {component_name}(title: "Sample {component_name}")
    }}
    .padding()
}}
"""
        component_path.write_text(template_component)
        print(f"  ✅ Created: {component_path.relative_to(root_dir)}")
    else:
        print(f"  ℹ️ Component sudah ada: {component_path.relative_to(root_dir)}")

    # 2. Component Unit Test
    test_path = tests_dir / f"{component_name}Tests.swift"
    if not test_path.exists():
        template_test = f"""import XCTest
import SwiftUI
@testable import CoreDesignSystem

final class {component_name}Tests: XCTestCase {{
    func test_{component_name}_initialization() {{
        var actionCalled = false
        let component = {component_name}(title: "Test Button") {{
            actionCalled = true
        }}
        XCTAssertEqual(component.title, "Test Button")
        component.action?()
        XCTAssertTrue(actionCalled)
    }}
}}
"""
        test_path.write_text(template_test)
        print(f"  ✅ Created: {test_path.relative_to(root_dir)}")
    else:
        print(f"  ℹ️ Test sudah ada: {test_path.relative_to(root_dir)}")

    # 3. Ensure CoreDesignSystemTests is registered in Project.swift
    proj_path = root_dir / "Project.swift"
    proj_content = proj_path.read_text()

    if 'name: "CoreDesignSystemTests",' not in proj_content:
        tests_target_code = """
        .target(
            name: "CoreDesignSystemTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CoreDesignSystemTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: [
                "Core/DesignSystem/Tests/**"
            ],
            dependencies: [
                .target(name: "CoreDesignSystem")
            ]
        ),
"""
        proj_content = insert_targets_into_project(proj_content, tests_target_code)
        proj_path.write_text(proj_content)
        print("  ✅ Registered CoreDesignSystemTests target in Project.swift")

    # 4. Run tuist generate
    from make_feature import run_tuist_generate
    if run_tuist_generate(root_dir):
        print(f"\n🎉 UI Component '{component_name}' berhasil dibuat dan diregistrasikan ke project!")
    else:
        print(f"\n💡 Jalankan 'tuist generate' secara manual untuk melihat detail masalah.")

if __name__ == "__main__":
    main()
