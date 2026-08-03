# HOM — Hospitality Operations Manager

The hotel operating system powering Nigeria. One offline-first OS for the whole property — bookings, diesel tracking (5 fuel types), expenditure control, compliance automation, staff payroll, vendors, WhatsApp integration and bank reconciliation.

- **Product site:** https://hom.com.ng
- **Web app:** https://app.hom.com.ng
- **Built by:** [Hexadigitall](https://hexadigitall.com)
- **License:** Proprietary — all rights reserved. See [LICENSE](LICENSE).

## Why HOM

Nigerian hotels run on paper log books, generator diesel that disappears, and accountants chasing bank statements. HOM replaces all of it with a single offline-first app that runs on Android, Windows, Linux, macOS and the web — works without internet, in a language staff already use.

## Repo layout

```
hom-os/
├── web/     -> Next.js 14 marketing site + web app (Vercel: hom.com.ng / app.hom.com.ng)
├── mobile/  -> Flutter app (Android AAB/APK, Windows MSIX, Linux DEB, macOS, web)
├── brand/   -> Logo pack & brand assets
├── vercel.json
└── .github/workflows/build-hom.yml -> CI/CD: signed builds + release assets + checksums
```

## Ecosystem-wide convention

> All updates and changes apply to **every** part of the HOM ecosystem: the
> Next.js web app (`web/`), the Flutter app (`mobile/`), and the brand
> assets (`brand/`). Do not ship a feature to one platform only.

### Role-based access (RBAC)

HOM uses a shared **additive, zero-trust RBAC model**:

- Cold start: no default admin. First boot = owner registration, then invite codes.
- Access = union of assigned roles + custom grants, only while `status == active`.
- Departments scope what a user can see/do; heads of departments can head more
  than one department. Suspension revokes access immediately.

The model is implemented in lockstep in two places — **keep them in sync**:
- `mobile/lib/models/role.dart` + `mobile/lib/data/role_store.dart` (Flutter)
- `web/lib/rbac.ts` + `web/lib/auth.tsx` (Next.js)

## Quick start

### Web

```bash
cd web
npm install
NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY=pk_test_754731e7a9876ece4826c96a4f7734c189e7f7c6 npm run dev
```

The `NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY` above is a public **test** key; replace with your own in production.

### Mobile

```bash
cd mobile
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

Platform-specific builds (Windows MSIX, Linux DEB, macOS, web) are documented in the Flutter app's build configuration.

## Releases

Every push to `main` triggers [CI](.github/workflows/build-hom.yml) which produces:

- Signed Android **APK**, **AAB** and split APKs
- Signed Windows **MSIX** + certificate
- Linux **DEB**, macOS and web builds
- A GitHub **release** with a `SHA256SUMS.txt` for every artifact

Versions follow `2.<build_number>.0` and always bump — so new releases install
**in place** over the previous one without uninstalling. The app checks for
updates on launch and prompts the user.

## Security

Found a vulnerability or a leaked credential? Do **not** open a public issue.
See [SECURITY.md](SECURITY.md) for how to report it privately.

## License

Proprietary. All rights reserved. You may not copy, modify, redistribute or
sub-license this code without prior written permission from Hexadigitall.
See [LICENSE](LICENSE).
