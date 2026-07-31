# HOM - Hospitality Operations Manager 

Built by Hexadigitall — https://hexadigitall.com / https://github.com/hexadigitall

## Ecosystem-wide convention

> All updates and changes apply to **every** part of the HOM ecosystem: the
> Next.js web app (`web/`), the Flutter mobile app (`mobile/`), and the brand
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

## Structure
```
/hom.com.ng/
├── web/     -> Vercel Next.js 14 (hom.com.ng)
├── mobile/  -> Flutter Android (AAB + APK)
├── brand/   -> Logo pack & brand assets
├── vercel.json
```

## Quick Start
### Web
cd web
npm install
NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY=pk_test_754731e7a9876ece4826c96a4f7734c189e7f7c6 npm run dev

### Deploy to Vercel
1. Push to github.com/hexadigitall/hom-os
2. Vercel -> New Project -> Import
3. Root Directory = `web`
4. Env: NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY=pk_test_754731e7a9876ece4826c96a4f7734c189e7f7c6
5. Domains: hom.com.ng, www.hom.com.ng, app.hom.com.ng
   DNS: A @ 76.76.21.21, CNAME www cname.vercel-dns.com

### Mobile
cd mobile
flutter pub get
flutter build apk --release
flutter build appbundle --release

GitHub Actions auto-builds signed AAB/APK on push to main.
