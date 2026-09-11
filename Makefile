.PHONY: help feature screen delete-feature test core component generate clean doctor list lint graph run build lint-strings sync-localization format format-check

help:
	@echo "======================================================="
	@echo "🛠  MyTuistProject Development Tools"
	@echo "======================================================="
	@echo "  make feature [name=FeatureName]"
	@echo "      Membuat modul Feature baru (Clean Architecture) lengkap dengan:"
	@echo "      - Feature Module (View, ViewModel, Unit Tests)"
	@echo "      - Domain Module (Entity, RepositoryProtocol, UseCase, DI Container, Tests)"
	@echo "      - Data Module (DTO, DataSource, Repository, DI Container, Tests)"
	@echo "      - Destinations, Routes, Navigation Param"
	@echo "      - Registrasi AppRoute, AppDIContainer, Project.swift"
	@echo "      - Otomatis menjalankan 'tuist generate'"
	@echo ""
	@echo "  make screen [feature=FeatureName] [name=ScreenName]"
	@echo "      Menambahkan Screen baru ke existing Feature:"
	@echo "      - Feature View, ViewModel, ViewModelTests"
	@echo "      - Domain Screen UseCase, Protocol, Container, Tests"
	@echo "      - Data Screen Endpoint, DataSource, Repository"
	@echo "      - Navigation Param di Core/Navigation/Sources/Param/"
	@echo "      - Update Destination, Route, dan RouteHandler"
	@echo "      - Otomatis menjalankan 'tuist generate'"
	@echo ""
	@echo "  make delete-feature [name=FeatureName]"
	@echo "      Menghapus Feature modul beserta Domain, Data, Navigasi, dan"
	@echo "      mencabut seluruh registrasi di Project.swift & AppDIContainer"
	@echo ""
	@echo "  make test [ModuleName | all]"
	@echo "      Menjalankan unit test secara otomatis via terminal:"
	@echo "      - make test CoreNetwork      : Menguji modul CoreNetwork"
	@echo "      - make test CoreDesignSystem : Menguji modul CoreDesignSystem"
	@echo "      - make test Product          : Menguji Feature + Domain + Data Product"
	@echo "      - make test                  : Menguji SEMUA modul (Core, Domain, Data, Feature, App)"
	@echo ""
	@echo "  make run [env=Dev|UAT|Prod] [device=iPhone 17]"
	@echo "      Membangun aplikasi dan langsung menjalankannya di iOS Simulator"
	@echo ""
	@echo "  make build [env=Dev|UAT|Prod]"
	@echo "      Hanya mengompilasi scheme aplikasi ke paket .app (tanpa launch)"
	@echo ""
	@echo "  make graph [target=TargetName] [mermaid=true]"
	@echo "      Menampilkan visualisasi pohon relasi dependensi arsitektur antar modul"
	@echo ""
	@echo "  make lint"
	@echo "      Validasi kepatuhan arsitektur Clean Architecture antar layer"
	@echo "      (Domain purity, isolasi Data layer, decoupling Core modules)"
	@echo ""
	@echo "  make lint-strings"
	@echo "      Memeriksa konsistensi Localizable.strings (en vs id), duplikasi, dan specifier"
	@echo ""
	@echo "  make sync-localization"
	@echo "      Menyinkronkan key bahasa Inggris yang belum ada di id.lproj dengan tag [TODO]"
	@echo ""
	@echo "  make format [path=Path]"
	@echo "      Merapikan style dan indentasi file Swift secara otomatis (in-place)"
	@echo ""
	@echo "  make format-check"
	@echo "      Memeriksa kesesuaian format kode Swift tanpa memodifikasi file"
	@echo ""
	@echo "  make doctor"
	@echo "      Memeriksa kesehatan proyek, environment Xcode/Swift/Tuist,"
	@echo "      kelengkapan layer tiap modul, registrasi, dan deteksi orphan"
	@echo ""
	@echo "  make list"
	@echo "      Menampilkan tabel inventaris seluruh Feature & Core Modules"
	@echo ""
	@echo "  make clean"
	@echo "      Deep clean cache Tuist, DerivedData, file proyek lokal,"
	@echo "      dan regenerasi bersih workspace"
	@echo ""
	@echo "  make core [name=CoreModuleName]"
	@echo "      Membuat infrastructure/core module baru di Core/<Name>"
	@echo "      lengkap dengan Service protocol, Factory Container, dan Tests"
	@echo ""
	@echo "  make component [name=ComponentName]"
	@echo "      Membuat UI Component Design System di Core/DesignSystem"
	@echo "      lengkap dengan DesignTokens, Preview, dan Unit Test"
	@echo ""
	@echo "  make generate"
	@echo "      Menjalankan 'tuist generate --no-open'"
	@echo "======================================================="

feature:
	@python3 scripts/make_feature.py name=$(name)$(NAME)

screen:
	@python3 scripts/make_screen.py feature=$(feature)$(FEATURE) name=$(name)$(NAME)

delete-feature:
	@python3 scripts/delete_feature.py name=$(name)$(NAME)

# Support positional argument: make test CoreNetwork
ifeq (test,$(firstword $(MAKECMDGOALS)))
  TEST_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(TEST_ARGS):;@:)
endif

test:
	@python3 scripts/run_tests.py $(TEST_ARGS) $(target)$(TARGET)$(feature)$(FEATURE)$(name)$(NAME)$(module)$(MODULE)

run:
	@python3 scripts/run_app.py env=$(env)$(ENV) device=$(device)$(DEVICE)

build:
	@python3 scripts/run_app.py env=$(env)$(ENV) device=$(device)$(DEVICE) --build-only

graph:
	@python3 scripts/graph_dependencies.py target=$(target)$(TARGET)$(name)$(NAME) $(if $(filter true 1,$(mermaid)$(MERMAID)),--mermaid,)

lint:
	@python3 scripts/lint_architecture.py

lint-strings:
	@python3 scripts/sync_localization.py

sync-localization:
	@python3 scripts/sync_localization.py --sync

format:
	@python3 scripts/format_code.py path=$(path)$(target)$(TARGET)$(file)$(FILE)

format-check:
	@python3 scripts/format_code.py path=$(path)$(target)$(TARGET)$(file)$(FILE) --check

doctor:
	@python3 scripts/project_doctor.py

list:
	@python3 scripts/project_doctor.py --list

clean:
	@python3 scripts/clean_project.py

core:
	@python3 scripts/make_core.py name=$(name)$(NAME)

component:
	@python3 scripts/make_component.py name=$(name)$(NAME)

generate:
	@tuist generate --no-open
