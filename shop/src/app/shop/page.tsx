import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { ItemCard } from "@/components/ItemCard";
import { CATEGORIES } from "@/lib/items";

export const revalidate = 30;

type SearchParams = {
  cat?: string;
};

export default async function ShopPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const { cat } = await searchParams;
  const where = cat
    ? { active: true, category: cat }
    : { active: true };
  const items = await prisma.item.findMany({
    where,
    orderBy: [{ featured: "desc" }, { createdAt: "desc" }],
  });

  return (
    <div className="mt-8">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-3xl font-black tracking-tight">Boutique FRZ RP</h1>
        <div className="flex flex-wrap gap-2">
          <CategoryChip href="/shop" label="Tout" active={!cat} />
          {CATEGORIES.map((c) => (
            <CategoryChip
              key={c.value}
              href={`/shop?cat=${c.value}`}
              label={c.label}
              active={cat === c.value}
            />
          ))}
        </div>
      </div>

      {items.length === 0 ? (
        <div className="mt-8 card p-10 text-center text-white/60">
          Aucun item dans cette categorie.
        </div>
      ) : (
        <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {items.map((it) => (
            <ItemCard key={it.id} item={it} />
          ))}
        </div>
      )}
    </div>
  );
}

function CategoryChip({
  href,
  label,
  active,
}: {
  href: string;
  label: string;
  active: boolean;
}) {
  return (
    <Link
      href={href}
      className={
        "rounded-full border px-3 py-1 text-sm transition " +
        (active
          ? "border-yellow-400/60 bg-yellow-400/10 text-yellow-300"
          : "border-white/10 bg-white/5 text-white/70 hover:bg-white/10")
      }
    >
      {label}
    </Link>
  );
}
