# hom.com.ng — HOM Monorepo

Built by Hexadigitall — https://hexadigitall.com / https://github.com/hexadigitall

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
