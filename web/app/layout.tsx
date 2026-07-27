import "./globals.css";
export const metadata = {
  title: "hom.com.ng — The Hotel OS Powering Nigeria",
  description: "Bookings, Diesel tracking, Vendors, Payroll, Paystack & WhatsApp automation for PH/Lagos hotels. Built by Hexadigitall.",
  icons: { icon: "/favicon.ico" },
  manifest: "/site.webmanifest",
  openGraph: { title: "hom.com.ng", images: ["/logo.png"] }
};
export default function RootLayout({children}: {children: React.ReactNode}) {
  return <html lang="en"><body className="bg-white text-zinc-900">{children}</body></html>
}
