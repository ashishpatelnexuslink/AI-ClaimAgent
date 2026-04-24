# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaimAI is an AI-powered Claim Management System with three components:
- **Backend/** — ASP.NET Core 10.0 Web API (C#), PostgreSQL
- **MobileApp/** — Flutter (Dart) claimant-facing app
- **AdminPanel/** — React 19 + Vite + TypeScript admin web UI

## Build & Run Commands

### Backend (.NET)

```bash
# Restore / build / run
dotnet restore Backend/ClaimAI.Backend.slnx
dotnet build Backend/ClaimAI.Backend.slnx
dotnet run --project Backend/src/ClaimAI.API

# Tests (tests/ directory exists but is currently empty)
dotnet test Backend/ClaimAI.Backend.slnx

# EF Core migrations (CLI)
dotnet ef migrations add <Name> --project Backend/src/ClaimAI.Infrastructure --startup-project Backend/src/ClaimAI.API
dotnet ef database update       --project Backend/src/ClaimAI.Infrastructure --startup-project Backend/src/ClaimAI.API
```

In Visual Studio's **Package Manager Console** (set Default project = `ClaimAI.Infrastructure`):

```powershell
Add-Migration <Name> -Project ClaimAI.Infrastructure -StartupProject ClaimAI.API
Update-Database         -Project ClaimAI.Infrastructure -StartupProject ClaimAI.API
Remove-Migration        -Project ClaimAI.Infrastructure -StartupProject ClaimAI.API
Script-Migration -Idempotent -Project ClaimAI.Infrastructure -StartupProject ClaimAI.API
```

**Gotcha:** if `ClaimAI.API` is running (VS debugger / `dotnet run`), builds fail with `MSB3021 / MSB3027` because the DLLs are locked. Stop the API first, then build or migrate.

### MobileApp (Flutter)

```bash
cd MobileApp
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # json_serializable / hive
flutter run
flutter analyze
flutter test
flutter test test/path_to_test.dart          # single test file
```

### AdminPanel (React/Vite)

```bash
cd AdminPanel
npm install
npm run dev        # vite dev server with HMR
npm run build      # tsc -b && vite build
npm run lint       # eslint .
npm run preview    # preview the production build
```

## Architecture

### Backend — Clean Architecture (4 projects)

Dependency flow: **API → Application → Domain ← Infrastructure**

| Project | Responsibility |
|---------|---------------|
| `ClaimAI.Domain` | Entities inheriting `BaseEntity` (Id, CreatedAt/By, UpdatedAt/By, IsDeleted); enums; repo interfaces; `Result<T>` / `Result` wrapper in `Domain.Common` |
| `ClaimAI.Application` | Service interfaces, DTOs, FluentValidation validators, AutoMapper profiles |
| `ClaimAI.Infrastructure` | `ApplicationDbContext` (Npgsql), EF entity configurations, `GenericRepository<T>`, JWT/Identity, services that need DbContext directly |
| `ClaimAI.API` | Controllers under `Areas/Mobile/` and `Areas/Web/`, middleware (`ExceptionHandling`, `RequestLogging`), `ValidationFilter`, OpenAPI/Scalar UI |

**Controller areas:**
- `Areas/Mobile/Controllers/` → `/api/mobile/...` — Flutter endpoints, `[Authorize]` (JWT)
- `Areas/Web/Controllers/`    → `/api/web/...`    — AdminPanel endpoints, `[Authorize(Roles="Admin")]` where write access matters

**Service layer convention (important):**
- Services return `Result<T>` / `Result` (from `Domain.Common`).
- Controllers translate to HTTP: `Result.Succeeded ? Ok(ApiResponse<T>.SuccessResponse(...)) : BadRequest(ApiResponse<object>.FailResponse(result.Errors))`.
- `ApiResponse<T>` (in `Application.DTOs.Common`) wraps every response with `Success / Data / Errors / StatusCode`.

**Where services live:**
- `ClaimAI.Application/Services/` — services that use only Identity + repositories (e.g., `AuthService`).
- `ClaimAI.Infrastructure/Services/` — services that need `ApplicationDbContext` directly for `Include`, transactions, raw queries (e.g., `ChatService`).

**Cross-cutting patterns:**
- **Soft delete:** `BaseEntity.IsDeleted` with a global query filter applied to every `BaseEntity`-derived type in `ApplicationDbContext.OnModelCreating`.
- **Auditing:** `AuditableEntityInterceptor` (registered in `Infrastructure.DependencyInjection`) stamps `CreatedBy/UpdatedBy/CreatedAt/UpdatedAt` on SaveChanges.
- **Validation:** FluentValidation validators are registered via `AddValidatorsFromAssembly`, and `ValidationFilter` (wired in `Program.cs`) runs them for every action parameter automatically — do not call `Validate` manually in controllers.
- **Enums in DB:** stored as strings via `.HasConversion<string>()` in the entity configuration (see `ConversationMessageConfiguration`). New enum columns should follow this convention.
- **Seed data:** `HasData(...)` inside `IEntityTypeConfiguration<T>`. Requires fixed `Guid` literals and a fixed `DateTime` (not `Guid.NewGuid()` / `DateTime.UtcNow`).
- **Filtered unique indexes:** Postgres syntax `builder.HasIndex(...).IsUnique().HasFilter("\"IsDeleted\" = false")` — used for "unique among live rows" and "at most one active row".
- **JWT:** 30-min access + 7-day refresh; OTP flow for mobile.

Connection: PostgreSQL `ClaimAIDb` on `localhost:5432`, configured in `ClaimAI.API/appsettings.json`.

### MobileApp — Clean Architecture + BLoC/Cubit

Features under `lib/features/`: `auth/`, `claims/`, `chat/`, `assistant/`, `documents/`, `notifications/`.

Each feature follows:
```
feature/
├── data/
│   ├── datasources/    # Remote (Dio) + Local (Hive/SharedPrefs)
│   ├── models/         # fromJson/toJson models extending entities
│   └── repositories/   # Repository implementations
├── domain/
│   ├── entities/       # Equatable value types
│   ├── repositories/   # Abstract repository
│   └── usecases/       # Use cases returning Either<Failure, T>
└── presentation/
    ├── cubit/          # Cubit + States
    └── pages/          # Widgets
```

**`features/chat/` vs `features/assistant/`:**
- `features/chat/` — standard BLoC flow for request/response chat history (`/mobile/chat/send`, `/mobile/chat/{claimId}/history`).
- `features/assistant/presentation/pages/claim_chat_screen.dart` — the large SSE-streaming claim-submission chat (`/chat/stream`). Its message objects carry `triggers` (`GET_IMAGE`, `GET_DOCUMENT`, `GET_LOCATION`, `GET_DATE_TIME`, `SUBMIT_CLAIM`) that drive client-side UI, plus `claim_data` for the final submit. Most claim-flow wiring lives in this file, not in `features/chat/`.

**Cross-cutting patterns:**
- **DI:** GetIt service locator, everything registered in `lib/injection_container.dart` as `di.sl<T>()`.
- **Error handling:** `Either<Failure, T>` (dartz).
- **Networking:** Dio + `ApiInterceptor` for bearer-token injection and 401 → refresh retry.
- **Offline:** Hive + SharedPreferences; `NetworkInfo` for connectivity checks.
- **Environment:** `EnvConfig` picks dev/staging/prod from `lib/config/env_config.dart`; URLs live in `lib/core/constants/api_constants.dart`.
- **Model serialization:** the chat feature uses manual `fromJson`/`toJson` (see `chat_message_model.dart`). `json_serializable` is a dev dep but is not used for chat models — follow the manual pattern when adding new chat-side models to avoid a build_runner step.

### AdminPanel — React 19 + Vite + TanStack Query

```
src/
├── hooks/           # AuthContext, ToastContext (React Context providers)
├── components/
│   ├── ui/          # Badge, Button, Modal, Table, StatCard, Spinner, Avatar
│   └── layout/      # Sidebar, Header, Layout (shell for authenticated pages)
├── pages/           # auth/, dashboard/, claims/, users/, conversations/, settings/
├── App.tsx          # BrowserRouter + PrivateRoute gate + route table
└── main.tsx
```

Stack:
- **Routing:** React Router 7 (`BrowserRouter`). `PrivateRoute` in `App.tsx` redirects unauthenticated users to `/login`; authenticated routes nest under `<Layout />`.
- **Server state:** TanStack Query v5 with `staleTime: 5min, retry: 1` (configured in `App.tsx`). Use queries/mutations — don't fetch in `useEffect` manually.
- **Auth:** `AuthContext` provides `isAuthenticated`; token is read/written by it.
- **Styling:** TailwindCSS v4 via `@tailwindcss/vite`.
- **Forms:** `react-hook-form`.
- **HTTP:** `axios`.
- **Icons:** `lucide-react`; **Charts:** `recharts`.

Admin API base should target the backend `Areas/Web/` controllers (`/api/web/...`).

## Naming Conventions

### Backend (C#)
- Interfaces prefix `I`; DTO classes end in `Dto`; validators end in `Validator`; async methods end in `Async`.
- DTOs organized by area: `DTOs/Mobile/<Feature>/`, `DTOs/Auth/`, `DTOs/Common/`, `DTOs/<Feature>/` for shared read-model DTOs used by both Mobile and Web controllers.

### MobileApp (Dart)
- snake_case files; `Cubit` / `UseCase` / `DataSource` / `Entity` / `Model` suffixes.
- Imports via `package:claim_ai/...`.

### AdminPanel (TypeScript/React)
- PascalCase file + component (`ClaimsListPage.tsx`); camelCase hooks (`useAuthContext`).
- Pages under `src/pages/<area>/`, reusable primitives under `src/components/ui/`, layout shells under `src/components/layout/`.
