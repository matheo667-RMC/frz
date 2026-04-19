import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { ItemForm } from "@/components/ItemForm";

export const dynamic = "force-dynamic";

export default async function EditItemPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const user = await getCurrentUser();
  if (!user) redirect("/api/auth/discord");
  if (!user.isAdmin) redirect("/");
  const { id } = await params;
  const item = await prisma.item.findUnique({ where: { id } });
  if (!item) return notFound();

  return (
    <div className="mt-8">
      <nav className="text-sm text-white/50">
        <Link href="/admin" className="hover:text-white">
          ← Admin
        </Link>
      </nav>
      <h1 className="mt-4 text-3xl font-black tracking-tight">
        Editer : {item.name}
      </h1>
      <div className="mt-6">
        <ItemForm
          initial={{
            id: item.id,
            slug: item.slug,
            name: item.name,
            description: item.description,
            category: item.category,
            priceEur: (item.priceCents / 100).toFixed(2),
            imageUrl: item.imageUrl ?? "",
            active: item.active,
            featured: item.featured,
            payloadJson: JSON.stringify(JSON.parse(item.payload), null, 2),
          }}
        />
      </div>
    </div>
  );
}
