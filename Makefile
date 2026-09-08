.PHONY: help feature screen generate

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
	@echo "      - Domain Screen UseCase, Protocol, Container, Tests (membuat Domain jika belum ada)"
	@echo "      - Data Screen Endpoint, DataSource, Repository (membuat Data jika belum ada)"
	@echo "      - Navigation Param di Core/Navigation/Sources/Param/"
	@echo "      - Update Destination, Route, dan RouteHandler"
	@echo "      - Otomatis menjalankan 'tuist generate'"
	@echo ""
	@echo "  make generate"
	@echo "      Menjalankan 'tuist generate --no-open'"
	@echo "======================================================="

feature:
	@python3 scripts/make_feature.py name=$(name)$(NAME)

screen:
	@python3 scripts/make_screen.py feature=$(feature)$(FEATURE) name=$(name)$(NAME)

generate:
	@tuist generate --no-open
