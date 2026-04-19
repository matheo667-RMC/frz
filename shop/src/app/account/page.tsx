import Link from "next/link";
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { formatPrice, formatDate } from "@/lib/format";

export const dynamic = "force-dynamic";

export default async function AccountPage() {
  const session = await getSession();
  if (!session) redirect("/api/auth/discord");

  const [orders, deliveries] = await Promise.all([
    prisma.order.findMany({
      where: { userId: session.userId },
      orderBy: { createdAt: "desc" },
      include: { item: true },
      take: 50,
    }),
    prisma.delivery.findMany({
      where: { userId: session.userId },
      orderBy: { createdAt: "desc" },
      include: { item: true },
      take: 50,
    }),
  ]);

  return (
    <div className="mt-8 space-y-10">
      <section>
        <h1 className="text-3xl font-black tracking-tight">Mon compte</h1>
        <p className="mt-1 text-white/60">
          Connecte en tant que <strong>{session.username}</strong> (Discord ID:{" "}
          <code className="text-white/80">{session.discordId}</code>)
        </p>
      </section>

      <section>
        <h2 className="mb-3 text-xl font-bold">Mes commandes</h2>
        {orders.length === 0 ? (
          <div className="card p-8 text-center text-white/60">
            Tu n&apos;as pas encore de commande.{" "}
            <Link href="/shop" className="underline">
              Voir la boutique
            </Link>
            .
          </div>
        ) : (
          <div className="overflow-hidden rounded-xl border border-white/10">
            <table className="w-full text-sm">
              <thead className="bg-white/5 text-left text-white/60">
                <tr>
                  <th className="px-4 py-2">Date</th>
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
                      <Link
                        href={`/shop/${o.item.slug}`}
                        className="hover:underline"
                      >
                        {o.item.name}
                      </Link>
                    </td>
                    <td className="px-4 py-2">
                      {formatPrice(o.amountCents, o.currency)}
                    </td>
                    <td className="px-4 py-2">
                      <OrderBadge status={o.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <section>
        <h2 className="mb-3 text-xl font-bold">Livraisons en jeu</h2>
        {deliveries.length === 0 ? (
          <div className="card p-8 text-center text-white/60">
            Aucune livraison pour le moment.
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
            {deliveries.map((d) => (
              <div key={d.id} className="card p-4">
                <div className="flex items-center justify-between">
                  <div className="font-semibold">{d.item.name}</div>
                  <DeliveryBadge status={d.status} />
                </div>
                <div className="mt-1 text-xs text-white/50">
                  Cree {formatDate(d.createdAt)}
                  {d.deliveredAt
                    ? ` • Livre ${formatDate(d.deliveredAt)}`
                    : ""}
                </div>
                {d.note ? (
                  <div className="mt-2 text-xs text-white/60">
                    Note: {d.note}
                  </div>
                ) : null}
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function OrderBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    PAID: "bg-green-500/15 text-green-400 border-green-500/30",
    PENDING: "bg-yellow-500/15 text-yellow-300 border-yellow-500/30",
    FAILED: "bg-red-500/15 text-red-400 border-red-500/30",
    REFUNDED: "bg-white/10 text-white/70 border-white/10",
  };
  return (
    <span
      className={`inline-flex rounded-full border px-2 py-0.5 text-xs ${
        map[status] ?? "border-white/10 bg-white/5 text-white/70"
      }`}
    >
      {status}
    </span>
  );
}

function DeliveryBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    DELIVERED: "bg-green-500/15 text-green-400 border-green-500/30",
    PENDING: "bg-yellow-500/15 text-yellow-300 border-yellow-500/30",
    FAILED: "bg-red-500/15 text-red-400 border-red-500/30",
  };
  return (
    <span
      className={`inline-flex rounded-full border px-2 py-0.5 text-xs ${
        map[status] ?? "border-white/10 bg-white/5 text-white/70"
      }`}
    >
      {status}
    </span>
  );
}
