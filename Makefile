.PHONY: help feature screen delete-feature test core component generate

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
	@echo "  make test [feature=FeatureName]"
	@echo "      Menjalankan unit test secara otomatis via terminal."
	@echo "      Jika feature ditentukan, menguji Feature + Domain + Data terkait."
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

test:
	@python3 scripts/run_tests.py feature=$(feature)$(FEATURE)

core:
	@python3 scripts/make_core.py name=$(name)$(NAME)

component:
	@python3 scripts/make_component.py name=$(name)$(NAME)

generate:
	@tuist generate --no-open
