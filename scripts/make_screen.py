#!/usr/bin/env python3
import os
import sys
import re
import subprocess
from pathlib import Path

# Add script directory to sys.path to import helpers from make_feature
sys.path.append(str(Path(__file__).resolve().parent))
from make_feature import (
    to_pascal_case,
    to_camel_case,
    create_domain_module,
    create_data_module,
    register_in_app_di_container,
    register_in_project_swift,
)

def get_existing_features(root_dir: Path):
    features_dir = root_dir / "Features"
    if not features_dir.exists():
        return []
    return sorted([
        d.name for d in features_dir.iterdir()
        if d.is_dir() and (d / "Sources").exists() and not d.name.startswith(".")
    ])

def parse_args(root_dir: Path):
    feature = None
    name = None

    for arg in sys.argv[1:]:
        if arg.startswith("feature=") or arg.startswith("FEATURE="):
            feature = arg.split("=", 1)[1]
        elif arg.startswith("name=") or arg.startswith("NAME="):
            name = arg.split("=", 1)[1]
        elif not arg.startswith("-"):
            if feature is None:
                feature = arg
            elif name is None:
                name = arg

    existing_features = get_existing_features(root_dir)

    if not feature:
        print("\nExisting Features:")
        for idx, f in enumerate(existing_features, 1):
            print(f"  [{idx}] {f}")

        try:
            choice = input("\nPilih Feature (nomor atau nama): ").strip()
            if choice.isdigit() and 1 <= int(choice) <= len(existing_features):
                feature = existing_features[int(choice) - 1]
            else:
                feature = choice
        except (EOFError, KeyboardInterrupt):
            print("\nOperasi dibatalkan.")
            sys.exit(1)

    if not feature:
        print("Error: Feature harus ditentukan.")
        sys.exit(1)

    # Normalize feature name
    normalized_feature = None
    for f in existing_features:
        if f.lower() == feature.lower() or f.lower() == f"feature{feature.lower()}":
            normalized_feature = f
            break
    if normalized_feature:
        feature = normalized_feature
    else:
        feature = to_pascal_case(feature)

    if not (root_dir / "Features" / feature).exists():
        print(f"⚠️ Peringatan: Direktori Features/{feature} belum ada.")

    if not name:
        try:
            name = input(f"Masukkan nama Screen baru untuk Feature '{feature}' (misal: Review, History, Detail): ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nOperasi dibatalkan.")
            sys.exit(1)

    if not name:
        print("Error: Nama screen tidak boleh kosong.")
        sys.exit(1)

    return feature, name

def ensure_domain_and_data_base(root_dir: Path, feature_name: str):
    domain_dir = root_dir / "Modules" / "Domain" / feature_name
    data_dir = root_dir / "Modules" / "Data" / feature_name

    needs_wiring = False
    if not domain_dir.exists():
        print(f"  ℹ️ Domain{feature_name} belum ada. Membuat base Domain module...")
        create_domain_module(root_dir, feature_name)
        needs_wiring = True

    if not data_dir.exists():
        print(f"  ℹ️ Data{feature_name} belum ada. Membuat base Data module...")
        create_data_module(root_dir, feature_name)
        needs_wiring = True

    if needs_wiring:
        register_in_app_di_container(root_dir, feature_name)
        register_in_project_swift(root_dir, feature_name)

def add_screen_to_domain(root_dir: Path, feature_name: str, screen_name: str):
    domain_dir = root_dir / "Modules" / "Domain" / feature_name
    case_name = to_camel_case(feature_name)

    # 1. Screen UseCase
    use_cases_dir = domain_dir / "Sources" / "UseCases"
    use_cases_dir.mkdir(parents=True, exist_ok=True)
    use_case_path = use_cases_dir / f"Get{screen_name}UseCase.swift"
    if not use_case_path.exists():
        template_use_case = f"""import Foundation
import FactoryKit

public protocol Get{screen_name}UseCaseProtocol: Sendable {{
    func execute() async throws -> {feature_name}
}}

public final class Get{screen_name}UseCase: Get{screen_name}UseCaseProtocol, @unchecked Sendable {{
    @Injected(\\.{case_name}Repository) private var repository: {feature_name}RepositoryProtocol

    public init() {{}}

    public init(repository: {feature_name}RepositoryProtocol) {{
        self.repository = repository
    }}

    public func execute() async throws -> {feature_name} {{
        try await repository.get{screen_name}()
    }}
}}
"""
        use_case_path.write_text(template_use_case)
        print(f"  ✅ Created Domain UseCase: {use_case_path.relative_to(root_dir)}")

    # 2. Add method in RepositoryProtocol
    repo_proto_path = domain_dir / "Sources" / "Repositories" / f"{feature_name}RepositoryProtocol.swift"
    if repo_proto_path.exists():
        content = repo_proto_path.read_text()
        method_sig = f"func get{screen_name}() async throws -> {feature_name}"
        if method_sig not in content:
            pattern = r"(public protocol " + re.escape(feature_name) + r"RepositoryProtocol:\s*Sendable\s*\{[\s\S]*?)(\n\})\s*$"
            def add_proto_method(m):
                body = m.group(1).rstrip()
                return f"{body}\n    {method_sig}\n}}"
            content = re.sub(pattern, add_proto_method, content)
            repo_proto_path.write_text(content)
            print(f"  ✅ Added '{method_sig}' to {repo_proto_path.name}")

    # 3. Register in Container+Domain<Feature>.swift
    container_path = domain_dir / "Sources" / f"Container+Domain{feature_name}.swift"
    if container_path.exists():
        content = container_path.read_text()
        factory_name = f"get{screen_name}UseCase"
        if factory_name not in content:
            pattern = r"(extension Container\s*\{[\s\S]*?)(\n\})\s*$"
            factory_code = f"""
    public var get{screen_name}UseCase: Factory<Get{screen_name}UseCaseProtocol> {{
        self {{ Get{screen_name}UseCase() }}
    }}"""
            def add_factory(m):
                body = m.group(1).rstrip()
                return f"{body}\n{factory_code}\n}}"
            content = re.sub(pattern, add_factory, content)
            container_path.write_text(content)
            print(f"  ✅ Registered '{factory_name}' in {container_path.name}")

    # 4. Update MockRepository in Tests/Mocks
    if feature_name == "Product":
        dummy_entity = 'Product(id: 2, title: "Test", price: 9.99, description: "Test", category: "Test", image: "", rating: ProductRating(rate: 5.0, count: 1))'
    else:
        dummy_entity = f'{feature_name}(id: "2", title: "Test {screen_name}")'

    mock_repo_path = domain_dir / "Tests" / "Mocks" / f"Mock{feature_name}Repository.swift"
    if mock_repo_path.exists():
        mock_content = mock_repo_path.read_text()
        if f"func get{screen_name}()" not in mock_content:
            pattern_mock = r'(public final class Mock' + re.escape(feature_name) + r'Repository:[\s\S]*?)(\n\})\s*$'
            def add_mock_method(m):
                body = m.group(1).rstrip()
                method_code = f"""
    public func get{screen_name}() async throws -> {feature_name} {{
        if let error = errorToThrow {{
            throw error
        }}
        return resultToReturn ?? {dummy_entity}
    }}"""
                return f"{body}\n{method_code}\n}}"
            mock_content = re.sub(pattern_mock, add_mock_method, mock_content)
            mock_repo_path.write_text(mock_content)
            print(f"  ✅ Updated Mock{feature_name}Repository with get{screen_name}()")

    # 5. Domain UseCase Unit Tests
    tests_dir = domain_dir / "Tests"
    tests_dir.mkdir(parents=True, exist_ok=True)
    test_path = tests_dir / f"Get{screen_name}UseCaseTests.swift"
    if not test_path.exists():
        template_test = f"""import XCTest
import FactoryKit
@testable import Domain{feature_name}

final class Get{screen_name}UseCaseTests: XCTestCase {{
    private var sut: Get{screen_name}UseCase!
    private var mockRepository: Mock{feature_name}Repository!

    override func setUp() {{
        super.setUp()
        Container.shared.reset()
        mockRepository = Mock{feature_name}Repository()
        let repo = mockRepository!
        Container.shared.{case_name}Repository.register {{ repo }}
        sut = Get{screen_name}UseCase(repository: repo)
    }}

    override func tearDown() {{
        Container.shared.reset()
        sut = nil
        mockRepository = nil
        super.tearDown()
    }}

    func test_execute_success() async throws {{
        let expected = {dummy_entity}
        mockRepository.resultToReturn = expected

        let result = try await sut.execute()
        XCTAssertEqual(result, expected)
    }}
}}
"""
        test_path.write_text(template_test)
        print(f"  ✅ Created Domain Test: {test_path.relative_to(root_dir)}")

def add_screen_to_data(root_dir: Path, feature_name: str, screen_name: str):
    data_dir = root_dir / "Modules" / "Data" / feature_name
    feature_lower = feature_name.lower()
    screen_lower = screen_name.lower()

    # 1. Update Endpoint
    endpoint_path = data_dir / "Sources" / "Endpoints" / f"{feature_name}Endpoint.swift"
    target_endpoint_file = endpoint_path if endpoint_path.exists() else (data_dir / "Sources" / "DataSources" / f"{feature_name}RemoteDataSource.swift")
    if target_endpoint_file.exists():
        ep_content = target_endpoint_file.read_text()

        # Add endpoint case to enum
        endpoint_case = f"case get{screen_name}"
        if endpoint_case not in ep_content:
            pattern_enum = r"(public enum " + re.escape(feature_name) + r"Endpoint:\s*(?:APIEndpoint|TargetType)\s*\{)([\s\S]*?)(\n\s*public var (?:baseURL|path):)"
            def add_ep_case(m):
                body = m.group(2).rstrip()
                return f"{m.group(1)}{body}\n    {endpoint_case}{m.group(3)}"
            ep_content = re.sub(pattern_enum, add_ep_case, ep_content)

        # Add path in switch self
        path_case_str = f"case .get{screen_name}:"
        if path_case_str not in ep_content:
            pattern_path = r"(public var path: String\s*\{[\s\S]*?switch self\s*\{)([\s\S]*?)(\n\s*\}\s*\n\s*\})"
            def add_path_case(m):
                body = m.group(2).rstrip()
                new_branch = f"\n        case .get{screen_name}:\n            return \"/{feature_lower}/{screen_lower}\""
                return f"{m.group(1)}{body}{new_branch}{m.group(3)}"
            ep_content = re.sub(pattern_path, add_path_case, ep_content)

        target_endpoint_file.write_text(ep_content)
        print(f"  ✅ Updated Endpoint in {target_endpoint_file.name}")

    # 2. Update RemoteDataSource
    rds_path = data_dir / "Sources" / "DataSources" / f"{feature_name}RemoteDataSource.swift"
    if rds_path.exists():
        rds_content = rds_path.read_text()

        # Add method to RemoteDataSourceProtocol
        proto_fetch = f"func fetch{screen_name}() async throws -> {feature_name}DTO"
        if proto_fetch not in rds_content:
            pattern_ds_proto = r"(public protocol " + re.escape(feature_name) + r"RemoteDataSourceProtocol:\s*Sendable\s*\{)([\s\S]*?)(\n\})"
            def add_ds_proto(m):
                body = m.group(2).rstrip()
                return f"{m.group(1)}{body}\n    {proto_fetch}\n}}"
            rds_content = re.sub(pattern_ds_proto, add_ds_proto, rds_content)

        # Add implementation to RemoteDataSource class
        class_fetch_str = f"public func fetch{screen_name}()"
        if class_fetch_str not in rds_content:
            pattern_ds_class = r'(public final class ' + re.escape(feature_name) + r'RemoteDataSource:[\s\S]*?)(\n\})\s*$'
            def add_ds_method(m):
                body = m.group(1).rstrip()
                method_code = f"""
    public func fetch{screen_name}() async throws -> {feature_name}DTO {{
        try await client.request(target: {feature_name}Endpoint.get{screen_name}, type: {feature_name}DTO.self)
    }}"""
                return f"{body}\n{method_code}\n}}"
            rds_content = re.sub(pattern_ds_class, add_ds_method, rds_content)

        rds_path.write_text(rds_content)
        print(f"  ✅ Updated RemoteDataSource in {rds_path.name}")

    # 3. Update Repository
    repo_path = data_dir / "Sources" / "Repositories" / f"{feature_name}Repository.swift"
    if repo_path.exists():
        repo_content = repo_path.read_text()
        repo_method_str = f"public func get{screen_name}()"
        if repo_method_str not in repo_content:
            pattern_repo = r'(public final class ' + re.escape(feature_name) + r'Repository:[\s\S]*?)(\n\})\s*$'
            def add_repo_method(m):
                body = m.group(1).rstrip()
                method_code = f"""
    public func get{screen_name}() async throws -> {feature_name} {{
        let dto = try await remoteDataSource.fetch{screen_name}()
        return dto.toDomain()
    }}"""
                return f"{body}\n{method_code}\n}}"
            repo_content = re.sub(pattern_repo, add_repo_method, repo_content)
            repo_path.write_text(repo_content)
            print(f"  ✅ Updated Data Repository in {repo_path.name}")

    # 3. Update MockRemoteDataSource in Tests/Mocks
    mock_rds_path = data_dir / "Tests" / "Mocks" / f"Mock{feature_name}RemoteDataSource.swift"
    if mock_rds_path.exists():
        mock_rds_content = mock_rds_path.read_text()
        if f"func fetch{screen_name}()" not in mock_rds_content:
            pattern_mock_rds = r'(public final class Mock' + re.escape(feature_name) + r'RemoteDataSource:[\s\S]*?)(\n\})\s*$'
            def add_mock_rds_method(m):
                body = m.group(1).rstrip()
                method_code = f"""
    public func fetch{screen_name}() async throws -> {feature_name}DTO {{
        if let error = errorToThrow {{
            throw error
        }}
        return dtoToReturn ?? {feature_name}DTO(id: "1", title: "Test")
    }}"""
                return f"{body}\n{method_code}\n}}"
            mock_rds_content = re.sub(pattern_mock_rds, add_mock_rds_method, mock_rds_content)
            mock_rds_path.write_text(mock_rds_content)
            print(f"  ✅ Updated Mock{feature_name}RemoteDataSource with fetch{screen_name}()")

def ensure_feature_target_dependencies(root_dir: Path, feature_name: str):
    proj_path = root_dir / "Project.swift"
    proj_content = proj_path.read_text()

    domain_target = f'.target(name: "Domain{feature_name}")'
    pattern_feat_dep = r'(name:\s*"Feature' + re.escape(feature_name) + r'",[\s\S]*?dependencies:\s*\[)([\s\S]*?)(\n\s*\])'
    m_feat = re.search(pattern_feat_dep, proj_content)
    if m_feat and domain_target not in m_feat.group(2):
        updated_deps = m_feat.group(2).rstrip() + f'\n                {domain_target},'
        proj_content = proj_content[:m_feat.start(2)] + updated_deps + proj_content[m_feat.end(2):]
        proj_path.write_text(proj_content)
        print(f"  ✅ Added {domain_target} to Feature{feature_name} dependencies in Project.swift")

def main():
    root_dir = Path(__file__).resolve().parent.parent
    feature_name, raw_screen_name = parse_args(root_dir)

    screen_name = to_pascal_case(raw_screen_name)
    screen_case = to_camel_case(screen_name)
    feature_case = to_camel_case(feature_name)
    module_name = f"Feature{feature_name}"

    view_name = f"{screen_name}View"
    view_model_name = f"{screen_name}ViewModel"
    test_name = f"{screen_name}ViewModelTests"
    param_name = f"{screen_name}ScreenParam"
    destination_name = f"{feature_name}Destination"
    route_name = f"{feature_name}Route"
    route_handler_name = f"{feature_name}RouteHandler"

    print(f"\n🚀 Membuat Screen '{view_name}' di Feature '{feature_name}' (lengkap dengan Domain & Data)...")

    # 1. Pastikan Base Domain & Data modules ada
    ensure_domain_and_data_base(root_dir, feature_name)

    # 2. Tambahkan UseCase ke Domain module
    print(f"\n📦 [1/4] Menambahkan UseCase ke Domain{feature_name}...")
    add_screen_to_domain(root_dir, feature_name, screen_name)

    # 3. Tambahkan Endpoint & Method ke Data module
    print(f"\n📦 [2/4] Menambahkan Endpoint & DataSource ke Data{feature_name}...")
    add_screen_to_data(root_dir, feature_name, screen_name)

    # 4. Buat Screen UI di Feature module
    print(f"\n📦 [3/4] Menyiapkan UI Screen di {module_name}...")
    feature_dir = root_dir / "Features" / feature_name
    (feature_dir / "Sources" / "Views").mkdir(parents=True, exist_ok=True)
    (feature_dir / "Sources" / "ViewModels").mkdir(parents=True, exist_ok=True)
    (feature_dir / "Tests").mkdir(parents=True, exist_ok=True)

    # View
    view_path = feature_dir / "Sources" / "Views" / f"{view_name}.swift"
    if not view_path.exists():
        template_view = f"""import SwiftUI
import CoreDesignSystem
import CoreNavigation
import CoreLocalization
import Domain{feature_name}
import FactoryKit

@MainActor
public struct {view_name}: View {{
    @Injected(\\.router) private var router
    @StateObject private var viewModel: {view_model_name}

    public init(param: {param_name}? = nil) {{
        _viewModel = StateObject(wrappedValue: {view_model_name}(param: param))
    }}

    public init(viewModel: {view_model_name}) {{
        _viewModel = StateObject(wrappedValue: viewModel)
    }}

    public var body: some View {{
        Group {{
            switch viewModel.state {{
            case .idle, .loading:
                LoadingView(message: "Loading {screen_name}...")
            case .empty:
                ErrorView(
                    title: "No Data",
                    message: "No {screen_name} data available.",
                    retryAction: {{
                        Task {{ await viewModel.loadData() }}
                    }}
                )
            case .failure(let errorMessage):
                ErrorView(
                    title: "Something went wrong",
                    message: errorMessage,
                    retryAction: {{
                        Task {{ await viewModel.loadData() }}
                    }}
                )
            case .success(let item):
                contentView(item: item)
            }}
        }}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("{screen_name}")
        .task {{
            await viewModel.loadData()
        }}
    }}

    @ViewBuilder
    private func contentView(item: {feature_name}) -> some View {{
        VStack(spacing: DesignTokens.Spacing.md) {{
            Text(item.title.isEmpty ? "{screen_name}" : item.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            Text("ID: \\(item.id)")
                .font(.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }}
        .padding(DesignTokens.Spacing.lg)
    }}
}}
"""
        view_path.write_text(template_view)
        print(f"  ✅ Created: {view_path.relative_to(root_dir)}")
    else:
        print(f"  ℹ️ View sudah ada: {view_path.relative_to(root_dir)}")

    # ViewModel
    vm_path = feature_dir / "Sources" / "ViewModels" / f"{view_model_name}.swift"
    if not vm_path.exists():
        template_vm = f"""import Foundation
import Combine
import CoreNavigation
import Domain{feature_name}
import FactoryKit

public enum {screen_name}ViewState: Equatable {{
    case idle
    case loading
    case success({feature_name})
    case empty
    case failure(String)
}}

@MainActor
public final class {view_model_name}: ObservableObject {{
    @Published public private(set) var state: {screen_name}ViewState = .idle
    @Injected(\\.router) private var router: AppRouter
    @Injected(\\.get{screen_name}UseCase) private var get{screen_name}UseCase: Get{screen_name}UseCaseProtocol
    public let param: {param_name}?

    public init(param: {param_name}? = nil) {{
        self.param = param
    }}

    public init(
        param: {param_name}? = nil,
        get{screen_name}UseCase: Get{screen_name}UseCaseProtocol,
        router: AppRouter? = nil
    ) {{
        self.param = param
        self.get{screen_name}UseCase = get{screen_name}UseCase
        if let router {{
            self.router = router
        }}
    }}

    public func loadData() async {{
        state = .loading
        do {{
            let data = try await get{screen_name}UseCase.execute()
            state = .success(data)
        }} catch {{
            state = .failure(error.localizedDescription)
        }}
    }}

    public func goBack() {{
        router.pop()
    }}
}}
"""
        vm_path.write_text(template_vm)
        print(f"  ✅ Created: {vm_path.relative_to(root_dir)}")
    else:
        print(f"  ℹ️ ViewModel sudah ada: {vm_path.relative_to(root_dir)}")

    # ViewModelTests
    test_path = feature_dir / "Tests" / f"{test_name}.swift"
    if not test_path.exists():
        template_test = f"""import XCTest
import SwiftUI
import CoreNavigation
import Domain{feature_name}
import FactoryKit
@testable import {module_name}

private final class MockGet{screen_name}UseCase: Get{screen_name}UseCaseProtocol, @unchecked Sendable {{
    var resultToReturn: {feature_name}?
    var errorToThrow: Error?

    func execute() async throws -> {feature_name} {{
        if let error = errorToThrow {{
            throw error
        }}
        return resultToReturn ?? {dummy_entity}
    }}
}}

@MainActor
final class {test_name}: XCTestCase {{
    private var sut: {view_model_name}!
    private var router: AppRouter!
    private var mockUseCase: MockGet{screen_name}UseCase!

    override func setUp() {{
        super.setUp()
        Container.shared.reset()
        let nav = UINavigationController()
        router = AppRouter(navigationController: nav)
        mockUseCase = MockGet{screen_name}UseCase()

        let r = router!
        Container.shared.router.register {{
            r
        }}
        let useCase = mockUseCase!
        Container.shared.get{screen_name}UseCase.register {{
            useCase
        }}
        sut = {view_model_name}()
    }}

    override func tearDown() {{
        Container.shared.reset()
        sut = nil
        router = nil
        mockUseCase = nil
        super.tearDown()
    }}

    func test_initialState() {{
        XCTAssertEqual(sut.state, .idle)
    }}

    func test_loadData_success() async {{
        let expected = {dummy_entity}
        mockUseCase.resultToReturn = expected

        await sut.loadData()

        XCTAssertEqual(sut.state, .success(expected))
    }}

    func test_loadData_failure() async {{
        let expectedError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network Failed"])
        mockUseCase.errorToThrow = expectedError

        await sut.loadData()

        if case .failure(let message) = sut.state {{
            XCTAssertTrue(message.contains("Network Failed") || !message.isEmpty)
        }} else {{
            XCTFail("Expected .failure state, got \\(sut.state)")
        }}
    }}

    func test_goBack_callsRouterPop() {{
        router.push(Text("Screen 1"), animated: false)
        router.push(Text("Screen 2"), animated: false)
        XCTAssertEqual(router.navigationController.viewControllers.count, 2)

        sut.goBack()
        XCTAssertEqual(router.navigationController.viewControllers.count, 1)
    }}
}}
"""
        test_path.write_text(template_test)
        print(f"  ✅ Created: {test_path.relative_to(root_dir)}")
    else:
        print(f"  ℹ️ Test sudah ada: {test_path.relative_to(root_dir)}")

    # 5. Param, Destination, Route, RouteHandler
    print(f"\n📦 [4/4] Menghubungkan Navigasi & Routing...")
    # Param
    param_path = root_dir / "Core" / "Navigation" / "Sources" / "Param" / f"{param_name}.swift"
    if not param_path.exists():
        param_path.parent.mkdir(parents=True, exist_ok=True)
        template_param = f"""import Foundation

/// Navigation parameter for {screen_name} screen.
/// Kept in CoreNavigation without any dependency to Domain entities.
public struct {param_name}: Identifiable, Hashable, Sendable {{
    public let id: String

    public init(id: String = UUID().uuidString) {{
        self.id = id
    }}
}}
"""
        param_path.write_text(template_param)
        print(f"  ✅ Created: {param_path.relative_to(root_dir)}")
    else:
        print(f"  ℹ️ Param sudah ada: {param_path.relative_to(root_dir)}")

    # Destination
    dest_path = root_dir / "Core" / "Navigation" / "Sources" / "Destinations" / f"{destination_name}.swift"
    if dest_path.exists():
        dest_content = dest_path.read_text()
        case_line = f"case {screen_case}"
        if case_line not in dest_content:
            pattern = r"(public enum " + re.escape(destination_name) + r": [^\{]+\{.*?)(\n\})"
            def add_dest_case(m):
                body = m.group(1).rstrip()
                return f"{body}\n    {case_line}\n}}"
            dest_content = re.sub(pattern, add_dest_case, dest_content, flags=re.DOTALL)
            dest_path.write_text(dest_content)
            print(f"  ✅ Added '{case_line}' to {destination_name}.swift")
    else:
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        template_dest = f"""import Foundation

public enum {destination_name}: FeatureDestination {{
    case list
    case {screen_case}
}}
"""
        dest_path.write_text(template_dest)
        print(f"  ✅ Created {destination_name}.swift with case {screen_case}")

    # Route
    route_path = root_dir / "Core" / "Navigation" / "Sources" / "Routes" / f"{route_name}.swift"
    if route_path.exists():
        route_content = route_path.read_text()
        route_case = f"case {screen_case}({param_name})"
        if f"case {screen_case}" not in route_content:
            pattern_enum = r"(public enum " + re.escape(route_name) + r": [^\{]+\{\n)(.*?)(\n\s*public var destination:)"
            def add_enum_case(m):
                body = m.group(2).rstrip()
                return f"{m.group(1)}{body}\n    {route_case}{m.group(3)}"
            route_content = re.sub(pattern_enum, add_enum_case, route_content, flags=re.DOTALL)

            pattern_switch = r"(public var destination: AppRouteDestination\s*\{[\s\S]*?switch self\s*\{)([\s\S]*?)(\n\s*\}\s*\n\s*\})"
            dest_case_str = f"case .{screen_case}"
            if dest_case_str not in route_content:
                def add_dest_case(m):
                    body = m.group(2).rstrip()
                    new_branch = f"\n        case .{screen_case}:\n            return .{feature_case}(.{screen_case})"
                    return f"{m.group(1)}{body}{new_branch}{m.group(3)}"
                route_content = re.sub(pattern_switch, add_dest_case, route_content, flags=re.DOTALL)

            route_path.write_text(route_content)
            print(f"  ✅ Added '{route_case}' to {route_name}.swift")
    else:
        print(f"  ℹ️ {route_name}.swift tidak ditemukan untuk diupdate otomatis.")

    # RouteHandler
    handler_path = root_dir / "MyTuistProject" / "Sources" / "CompositionRoot" / "Routes" / f"{route_handler_name}.swift"
    if handler_path.exists():
        handler_content = handler_path.read_text()
        handler_case = f"case .{screen_case}"
        if handler_case not in handler_content:
            pattern_switch = r"(switch route\s*\{)([\s\S]*?)(\n\s*\}\s*\n\s*\}\s*\n\s*return AnyView)"
            def add_handler_case(m):
                body = m.group(2).rstrip()
                new_branch = f"\n            case .{screen_case}(let param):\n                {view_name}(param: param)"
                return f"{m.group(1)}{body}{new_branch}{m.group(3)}"
            handler_content = re.sub(pattern_switch, add_handler_case, handler_content, flags=re.DOTALL)
            handler_path.write_text(handler_content)
            print(f"  ✅ Added '{screen_case}' to {route_handler_name}.swift")
    else:
        print(f"  ℹ️ {route_handler_name}.swift belum ada.")

    # Ensure Feature target in Project.swift depends on Domain<Feature>
    ensure_feature_target_dependencies(root_dir, feature_name)

    # Run tuist generate
    from make_feature import run_tuist_generate
    if run_tuist_generate(root_dir):
        print(f"\n🎉 Screen '{view_name}' berhasil ditambahkan ke Feature '{feature_name}'!")
    else:
        print(f"\n💡 Jalankan 'tuist generate' secara manual untuk melihat detail masalah.")

if __name__ == "__main__":
    main()
