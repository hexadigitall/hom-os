# Contributing to HOM

Thanks for your interest. HOM is proprietary software owned by Hexadigitall,
so external code contributions are **not** currently accepted.

## How you can still help

- **Report bugs** — open an issue describing the bug, the platform (Android,
  Windows, Linux, web…), and steps to reproduce.
- **Report security issues** — do **not** open a public issue. Follow
  [SECURITY.md](SECURITY.md) and email <hello@hexadigitall.com>.
- **Suggest features** — open a feature-request issue and explain the
  workflow you're trying to fix for your hotel.

## Bug report checklist

- [ ] App version (shown in the app's settings/about screen) and platform
- [ ] Steps to reproduce
- [ ] Expected behaviour vs. what actually happened
- [ ] Screenshots or screen recordings, if helpful

## Feature request checklist

- [ ] The operational problem it solves (diesel, bookings, payroll, compliance…)
- [ ] Which department(s) would use it
- [ ] Rough priority for your hotel

## Code changes

Hexadigitall maintains the codebase internally. If you're part of the team,
follow the ecosystem-wide convention in the [README](README.md): changes apply
to every platform (Flutter app + Next.js web app + brand), and the shared RBAC
model must stay in sync between `mobile/` and `web/`.
