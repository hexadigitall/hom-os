# Security Policy

## Reporting a vulnerability

Please do **not** open a public GitHub issue for security problems. Report
them privately to <hello@hexadigitall.com>.

Include in your report:

- The affected component (mobile app, web app, website, CI/release pipeline)
- App/platform version
- Steps to reproduce
- Impact of the vulnerability (what an attacker could do)

You should receive an acknowledgement within 5 business days, and we will
keep you updated as the issue is triaged and fixed.

## Leaked credentials

This repository deals with signing keys for the Android, Windows MSIX and
release pipeline. If you find a secret, keystore, certificate password or API
key committed in the repository, treat it as compromised and report it
immediately using the address above. Do not share or reuse it.

## Scope

- `web/` — Next.js marketing site and web app
- `mobile/` — Flutter app and its signing configuration
- `.github/workflows/` — CI/CD and release artifacts
- `brand/` — brand assets

## Supported versions

Only the latest release is supported. New versions are released continuously
with automatic in-place updates.
