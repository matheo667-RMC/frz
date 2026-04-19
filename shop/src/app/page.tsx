import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { ItemCard } from "@/components/ItemCard";

export const revalidate = 30;

export default async function HomePage() {
  const featured = await prisma.item.findMany({
    where: { active: true, featured: true },
    orderBy: { updatedAt: "desc" },
    take: 6,
  });
  const latest = await prisma.item.findMany({
    where: { active: true },
    orderBy: { createdAt: "desc" },
    take: 8,
  });

  return (
    <div>
      {/* Hero */}
      <section className="relative mt-6 overflow-hidden rounded-2xl border border-white/10 p-8 md:p-14">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 opacity-30"
          style={{
            background:
              "radial-gradient(600px 250px at 20% 20%, rgba(255,217,61,0.35), transparent 60%), radial-gradient(500px 250px at 90% 80%, rgba(34,211,238,0.3), transparent 60%)",
          }}
        />
        <div className="relative max-w-3xl">
          <span className="chip border-yellow-400/40 bg-yellow-400/10 text-yellow-300">
            GTA V • FiveM • QBCore
          </span>
          <h1 className="mt-4 text-4xl font-black leading-tight tracking-tight md:text-6xl">
            Equipe ton personnage{" "}
            <span className="text-yellow-400">FRZ RP</span> en 2 minutes.
          </h1>
          <p className="mt-4 max-w-2xl text-white/70">
            Achete des armes, vehicules, items rares et packs VIP. Livraison
            automatique en jeu des que ton paiement PayPal est confirme.
          </p>
          <div className="mt-6 flex flex-wrap gap-3">
            <Link href="/shop" className="btn btn-primary">
              Voir la boutique
            </Link>
            <Link href="/account" className="btn btn-ghost">
              Mes commandes
            </Link>
          </div>
          <ul className="mt-6 grid grid-cols-2 gap-2 text-xs text-white/60 sm:grid-cols-3">
            <li>✓ Paiement securise PayPal</li>
            <li>✓ Livraison auto en jeu</li>
            <li>✓ Connexion Discord</li>
            <li>✓ Utilisable via GTA (NUI)</li>
            <li>✓ Utilisable depuis Google</li>
            <li>✓ Compatible QBCore / QBox</li>
          </ul>
        </div>
      </section>

      {/* Featured */}
      {featured.length > 0 ? (
        <section className="mt-10">
          <div className="mb-4 flex items-end justify-between">
            <h2 className="text-xl font-bold">En vedette</h2>
            <Link
              href="/shop"
              className="text-sm text-white/60 hover:text-white"
            >
              Tout voir →
            </Link>
          </div>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {featured.map((item) => (
              <ItemCard key={item.id} item={item} />
            ))}
          </div>
        </section>
      ) : null}

      {/* Latest */}
      <section className="mt-10">
        <div className="mb-4 flex items-end justify-between">
          <h2 className="text-xl font-bold">Nouveautes</h2>
          <Link href="/shop" className="text-sm text-white/60 hover:text-white">
            Tout voir →
          </Link>
        </div>
        {latest.length === 0 ? (
          <div className="card p-8 text-center text-white/60">
            Aucun item pour le moment. Les admins peuvent en ajouter depuis{" "}
            <Link href="/admin" className="underline">
              /admin
            </Link>
            .
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {latest.map((item) => (
              <ItemCard key={item.id} item={item} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
