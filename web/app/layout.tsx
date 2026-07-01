import type { Metadata } from "next";
import { Lexend } from "next/font/google";
import "./globals.css";

const lexend = Lexend({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Stock'ESAT — Pilotage",
  description: "Tableau de bord de gestion de stock",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fr">
      <body
        className={`${lexend.className} bg-slate-50 text-slate-800 antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
