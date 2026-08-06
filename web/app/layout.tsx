import "./globals.css";
import SwRegister from "./sw-register";
export const metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "https://hom.com.ng"),
  title: "HOM — The Hotel Operating System for Nigerian Hotels | Hexadigitall",
  description: "HOM - The Hotel OS Powering Nigeria: Bookings, Diesel theft detection, Inventory, HR/Payroll PAYE 7% Pension 8%, Paystack, WhatsApp Cloud, Booking.com sync. Offline-first. Built by Hexadigitall.",
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
    title: "HOM — The Hotel Operating System Powering Nigeria",
    description: "One app for bookings, diesel tracking (5 fuel types), expenditure, compliance, payroll, WhatsApp and bank reconciliation. Offline-first for Nigerian hotels.",
    images: ["/brand/logo-emerald-bg.png"],
    url: "https://hom.com.ng",
    siteName: "HOM Hospitality",
    type: "website",
  },
};
export default function RootLayout({children}: {children: React.ReactNode}) {
  return <html lang="en"><head><link rel="icon" href="/favicon.ico" /><link rel="apple-touch-icon" href="/apple-touch-icon.png" /></head><body className="bg-hom-background text-hom-ink">{children}<SwRegister /></body></html>
}
