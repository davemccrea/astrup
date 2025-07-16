# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**IMPORTANT**: Always review [CONVENTIONS.md](./CONVENTIONS.md) for Elixir/Phoenix best practices and coding standards before making changes.

## Project Overview

HappiHub is an interactive learning platform for arterial blood gas (ABG) interpretation designed for healthcare professionals. The platform provides:

- **Learning modules** for ABG analysis fundamentals
- **Interactive quizzes** to test understanding
- **Guided interpretation tools** for real-world practice
- **ECG integration** for comprehensive patient assessment
- **Multi-language support** (English, Finnish, Swedish)

## Development Methodology

You should always being by checking reviewing CONVENTIONS.md and ROADMAP.md.

When given a problem first:

1. Write a failing test
2. Write code to make the test pass
3. If the test passes, commit the changes to git

Repeat this pattern until the problem is solved.

### Available MCPs for Development

**Tidewave MCP** (for Elixir/Phoenix development):

- Execute SQL queries against the database
- Run Elixir code in project context
- Introspect application logs and runtime
- Fetch documentation from Hex docs
- View all Ecto schemas
- Debug LiveView processes

**Context7 MCP** (for external documentation):

- Fetch up-to-date docs not available in Hex (Tailwind, Heroicons, DaisyUI, etc.)
- Get current API references for frontend libraries

## Architecture

### Tech Stack

- **Backend**: Elixir/Phoenix with LiveView
- **Database**: PostgreSQL
- **Frontend**: Phoenix LiveView + Tailwind CSS
- **Build**: esbuild for JavaScript bundling
- **HTTP Client**: Req for external API calls
- **Caching**: Cachex
- **i18n**: Gettext (English, Swedish and Finnish)

### Key Directories

- `lib/astrup/` - Business logic contexts
- `lib/astrup_web/` - Web layer (LiveViews, components, controllers)
- `assets/` - Frontend assets (CSS, JS, Tailwind config)

## Testing

### Backend Testing (Elixir/Phoenix)

- **Framework**: ExUnit (built into Elixir)
- **Run tests**: `mix test`
- **Test coverage**: Available via `mix test --cover`
- **Test database**: Separate test database configured in `config/test.exs`

Key test files:

- `test/astrup/` - Core business logic tests
- `test/astrup_web/` - Web layer tests
- `test/support/` - Test helpers and fixtures

### Frontend Testing (JavaScript)

- **Framework**: Vitest with jsdom environment
- **Run tests**: `cd assets && npm test`
- **Watch mode**: `npm run test:watch`
- **Coverage**: `npm run test:coverage`
- **UI**: `npm run test:ui`

## Development Commands

```bash
# Setup project
mix setup

# Run development server
mix phx.server

# Run all tests
mix test && cd assets && npm test
```

## Roadmap Management

**IMPORTANT**: Always check ROADMAP.md first

### Progress Tracking Protocol

1. **Todo**: `- [ ] **Task Name** - Description`
2. **In Progress**: `- [-] **Task Name** - Description 🏗️ YYYY/MM/DD`
3. **Completed**: `- [x] **Task Name** - Description ✅ YYYY/MM/DD`

- Use `date "+%Y/%m/%d"` to get current system date
- Update checkbox and timestamp when status changes
