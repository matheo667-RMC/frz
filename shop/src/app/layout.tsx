import type { Metadata } from "next";
import "./globals.css";
import { Header } from "@/components/Header";
import { getSession } from "@/lib/auth";

export const metadata: Metadata = {
  title: "FRZ RP — Boutique officielle",
  description:
    "La boutique officielle du serveur FRZ RP : achete des armes, vehicules, items et packs VIP pour ton personnage.",
};

export default async function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const session = await getSession();
  return (
    <html lang="fr">
      <body className="antialiased">
        <Header session={session} />
        <main className="mx-auto w-full max-w-6xl px-4 pb-20">{children}</main>
        <footer className="mx-auto w-full max-w-6xl px-4 py-10 text-xs text-white/40">
          © FRZ RP — Tous droits reserves. Ces items sont utilisables uniquement
          sur le serveur GTA V FiveM FRZ RP.
        </footer>
      </body>
    </html>
  );
}
