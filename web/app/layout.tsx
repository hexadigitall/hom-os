import "./globals.css";
export const metadata = {
  title: "HOM — Hospitality Operations Manager",
  description: "HOM - Hospitality Operations Manager: Bookings, Diesel theft, Inventory, HR/Payroll, Paystack, WhatsApp Cloud, Booking.com sync. Built by Hexadigitall.",
  icons: { icon: "/logo.png" },
  manifest: "/site.webmanifest",
};
export default function RootLayout({children}: {children: React.ReactNode}) {
  return <html lang="en"><body className="bg-white text-zinc-900">{children}</body></html>
}
