import "./globals.css";
export const metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "https://hom-os-web.vercel.app"),
  title: "HOM — Hospitality Operations Manager",
  description: "HOM - Hospitality Operations Manager: Bookings, Diesel theft, Inventory, HR/Payroll PAYE 7% Pension 8%, Paystack, WhatsApp Cloud, Booking.com sync. The Hotel OS Powering Nigeria. Built by Hexadigitall.",
  icons: {
    icon: [
      { url: "/favicon.ico" },
      { url: "/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [{ url: "/apple-touch-icon.png", sizes: "180x180" }],
  },
  manifest: "/site.webmanifest",
  openGraph: {
    title: "HOM — Hospitality Operations Manager",
    description: "The Hotel OS Powering Nigeria — Bookings, Diesel, Inventory, HR/Payroll, Paystack, WhatsApp, Booking.com",
    images: ["/playstore-icon-512.png"],
  },
};
export default function RootLayout({children}: {children: React.ReactNode}) {
  return <html lang="en"><head><link rel="icon" href="/favicon.ico" /><link rel="apple-touch-icon" href="/apple-touch-icon.png" /></head><body className="bg-white text-zinc-900">{children}</body></html>
}
