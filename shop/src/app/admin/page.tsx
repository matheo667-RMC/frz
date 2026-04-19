import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { formatPrice, formatDate, categoryLabel } from "@/lib/format";

export const dynamic = "force-dynamic";

export default async function AdminPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/api/auth/discord");
  if (!user.isAdmin) {
    return (
      <div className="mt-16 card p-8 text-center">
        <h1 className="text-2xl font-bold">Acces refuse</h1>
        <p className="mt-2 text-white/60">
          Ton compte n&apos;est pas administrateur. Demande au proprietaire du
          serveur FRZ RP de te promouvoir (ou configure{" "}
          <code>ADMIN_DISCORD_ID</code> dans <code>.env</code>).
        </p>
      </div>
    );
  }

  const [items, orders, pendingDeliveries] = await Promise.all([
    prisma.item.findMany({ orderBy: { createdAt: "desc" } }),
    prisma.order.findMany({
      orderBy: { createdAt: "desc" },
      include: { item: true, user: true },
      take: 25,
    }),
    prisma.delivery.count({ where: { status: "PENDING" } }),
  ]);

  const paidCount = orders.filter((o) => o.status === "PAID").length;
  const revenueCents = orders
    .filter((o) => o.status === "PAID")
    .reduce((sum, o) => sum + o.amountCents, 0);

  return (
    <div className="mt-8 space-y-10">
      <section className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-3xl font-black tracking-tight">
            Dashboard admin
          </h1>
          <p className="mt-1 text-white/60">
            Gere le catalogue, vois les commandes et suis les livraisons.
          </p>
        </div>
        <Link href="/admin/items/new" className="btn btn-primary">
          + Ajouter un item
        </Link>
      </section>

      <section className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <Stat label="Items actifs" value={items.filter((i) => i.active).length} />
        <Stat label="Commandes payees" value={paidCount} />
        <Stat
          label="Revenu total"
          value={formatPrice(revenueCents, "EUR")}
        />
        <Stat label="Livraisons en attente" value={pendingDeliveries} />
      </section>

      <section>
        <h2 className="mb-3 text-xl font-bold">Catalogue ({items.length})</h2>
        <div className="overflow-hidden rounded-xl border border-white/10">
          <table className="w-full text-sm">
            <thead className="bg-white/5 text-left text-white/60">
              <tr>
                <th className="px-4 py-2">Nom</th>
                <th className="px-4 py-2">Categorie</th>
                <th className="px-4 py-2">Prix</th>
                <th className="px-4 py-2">Actif</th>
                <th className="px-4 py-2">Vedette</th>
                <th className="px-4 py-2"></th>
              </tr>
            </thead>
            <tbody>
              {items.map((it) => (
                <tr key={it.id} className="border-t border-white/5">
                  <td className="px-4 py-2">
                    <div className="font-semibold">{it.name}</div>
                    <div className="text-xs text-white/50">/{it.slug}</div>
                  </td>
                  <td className="px-4 py-2 text-white/70">
                    {categoryLabel(it.category)}
                  </td>
                  <td className="px-4 py-2">
                    {formatPrice(it.priceCents, it.currency)}
                  </td>
                  <td className="px-4 py-2">{it.active ? "oui" : "non"}</td>
                  <td className="px-4 py-2">{it.featured ? "★" : "—"}</td>
                  <td className="px-4 py-2 text-right">
                    <Link
                      href={`/admin/items/${it.id}/edit`}
                      className="text-yellow-300 hover:underline"
                    >
                      Editer
                    </Link>
                  </td>
                </tr>
              ))}
              {items.length === 0 ? (
                <tr>
                  <td
                    colSpan={6}
                    className="px-4 py-10 text-center text-white/50"
                  >
                    Aucun item. Ajoute le premier pour commencer.
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      </section>

      <section>
        <h2 className="mb-3 text-xl font-bold">
          Dernieres commandes ({orders.length})
        </h2>
        <div className="overflow-hidden rounded-xl border border-white/10">
          <table className="w-full text-sm">
            <thead className="bg-white/5 text-left text-white/60">
              <tr>
                <th className="px-4 py-2">Date</th>
                <th className="px-4 py-2">Joueur</th>
                <th className="px-4 py-2">Item</th>
                <th className="px-4 py-2">Montant</th>
                <th className="px-4 py-2">Statut</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((o) => (
                <tr key={o.id} className="border-t border-white/5">
                  <td className="px-4 py-2 text-white/60">
                    {formatDate(o.createdAt)}
                  </td>
                  <td className="px-4 py-2">
                    <div>{o.user.username}</div>
                    <div className="text-xs text-white/50">
                      {o.user.discordId}
                    </div>
                  </td>
                  <td className="px-4 py-2">{o.item.name}</td>
                  <td className="px-4 py-2">
                    {formatPrice(o.amountCents, o.currency)}
                  </td>
                  <td className="px-4 py-2">{o.status}</td>
                </tr>
              ))}
              {orders.length === 0 ? (
                <tr>
                  <td
                    colSpan={5}
                    className="px-4 py-10 text-center text-white/50"
                  >
                    Aucune commande pour le moment.
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="card p-4">
      <div className="label">{label}</div>
      <div className="mt-1 text-2xl font-black">{value}</div>
    </div>
  );
}
