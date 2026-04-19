import { notFound } from "next/navigation";
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { getSession } from "@/lib/auth";
import { formatPrice, categoryLabel } from "@/lib/format";
import { parsePayload, describePayload } from "@/lib/items";
import { BuyButton } from "@/components/BuyButton";

export const dynamic = "force-dynamic";

export default async function ItemPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const item = await prisma.item.findUnique({ where: { slug } });
  if (!item || !item.active) return notFound();
  const session = await getSession();
  const payload = parsePayload(item.payload);

  return (
    <div className="mt-8 grid grid-cols-1 gap-8 lg:grid-cols-[1.4fr_1fr]">
      <div>
        <nav className="text-sm text-white/50">
          <Link href="/shop" className="hover:text-white">
            ← Boutique
          </Link>
        </nav>
        <div className="mt-4 overflow-hidden rounded-2xl border border-white/10 bg-black/40">
          <div className="relative aspect-[16/9] w-full">
            {item.imageUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={item.imageUrl}
                alt={item.name}
                className="h-full w-full object-cover"
              />
            ) : (
              <div className="flex h-full w-full items-center justify-center">
                <span className="text-6xl font-black text-white/10">FRZ</span>
              </div>
            )}
          </div>
        </div>
        <h1 className="mt-6 text-3xl font-black tracking-tight">{item.name}</h1>
        <div className="mt-2 flex flex-wrap gap-2">
          <span className="chip">{categoryLabel(item.category)}</span>
          {item.featured ? (
            <span className="chip border-yellow-400/40 bg-yellow-400/10 text-yellow-300">
              ★ En vedette
            </span>
          ) : null}
        </div>
        <p className="mt-4 whitespace-pre-wrap text-white/80">
          {item.description}
        </p>
        {payload ? (
          <div className="mt-6 card p-4">
            <div className="label">Ce que vous recevez en jeu</div>
            <div className="mt-1 text-sm text-white/80">
              {describePayload(payload)}
            </div>
          </div>
        ) : null}
      </div>

      <aside className="card h-fit p-6">
        <div className="label">Prix</div>
        <div className="mt-1 text-3xl font-black text-yellow-300">
          {formatPrice(item.priceCents, item.currency)}
        </div>
        <div className="mt-6">
          <BuyButton itemId={item.id} isLoggedIn={Boolean(session)} />
        </div>
        <ul className="mt-6 space-y-2 text-sm text-white/60">
          <li>• Livraison automatique en jeu</li>
          <li>• Requis : etre connecte sur FRZ RP au moins une fois</li>
          <li>• Paiement securise PayPal</li>
        </ul>
      </aside>
    </div>
  );
}
