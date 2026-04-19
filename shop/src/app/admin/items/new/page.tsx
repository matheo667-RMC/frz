import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { ItemForm } from "@/components/ItemForm";

export const dynamic = "force-dynamic";

export default async function NewItemPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/api/auth/discord");
  if (!user.isAdmin) redirect("/");

  return (
    <div className="mt-8">
      <nav className="text-sm text-white/50">
        <Link href="/admin" className="hover:text-white">
          ← Admin
        </Link>
      </nav>
      <h1 className="mt-4 text-3xl font-black tracking-tight">
        Nouvel item
      </h1>
      <div className="mt-6">
        <ItemForm />
      </div>
    </div>
  );
}
