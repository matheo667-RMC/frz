import Link from "next/link";
import { formatPrice, categoryLabel } from "@/lib/format";

type ItemCardProps = {
  item: {
    slug: string;
    name: string;
    description: string;
    category: string;
    priceCents: number;
    currency: string;
    imageUrl: string | null;
    featured?: boolean;
  };
};

export function ItemCard({ item }: ItemCardProps) {
  return (
    <Link
      href={`/shop/${item.slug}`}
      className="card group block overflow-hidden transition hover:-translate-y-0.5"
    >
      <div className="relative aspect-[16/10] w-full overflow-hidden bg-black/40">
        {item.imageUrl ? (
          // Pas d'optimisation Next/Image pour autoriser des hosts externes sans config.
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={item.imageUrl}
            alt={item.name}
            className="h-full w-full object-cover transition group-hover:scale-105"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center text-white/20">
            <span className="text-4xl font-black">FRZ</span>
          </div>
        )}
        <span className="absolute left-3 top-3 chip">
          {categoryLabel(item.category)}
        </span>
        {item.featured ? (
          <span className="absolute right-3 top-3 chip border-yellow-400/40 bg-yellow-400/10 text-yellow-300">
            ★ En vedette
          </span>
        ) : null}
      </div>
      <div className="flex items-start justify-between gap-4 p-4">
        <div className="min-w-0">
          <h3 className="truncate text-base font-semibold">{item.name}</h3>
          <p className="mt-1 line-clamp-2 text-sm text-white/60">
            {item.description}
          </p>
        </div>
        <div className="shrink-0 text-right">
          <div className="text-xs text-white/50">Prix</div>
          <div className="text-lg font-extrabold text-yellow-300">
            {formatPrice(item.priceCents, item.currency)}
          </div>
        </div>
      </div>
    </Link>
  );
}
