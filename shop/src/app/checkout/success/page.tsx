import Link from "next/link";
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { captureOrder } from "@/lib/paypal";

export const dynamic = "force-dynamic";

export default async function SuccessPage({
  searchParams,
}: {
  searchParams: Promise<{ order?: string; token?: string }>;
}) {
  const session = await getSession();
  if (!session) redirect("/api/auth/discord");

  const { order: orderId } = await searchParams;
  if (!orderId) {
    return (
      <div className="mt-16 card p-8 text-center">
        <h1 className="text-2xl font-bold">Commande introuvable</h1>
        <p className="mt-2 text-white/60">
          Aucun identifiant de commande fourni.
        </p>
      </div>
    );
  }

  const order = await prisma.order.findUnique({
    where: { id: orderId },
    include: { item: true },
  });
  if (!order || order.userId !== session.userId) {
    return (
      <div className="mt-16 card p-8 text-center">
        <h1 className="text-2xl font-bold">Commande introuvable</h1>
      </div>
    );
  }

  // Capture cote serveur au retour de PayPal.
  let status = order.status;
  if (status !== "PAID" && order.paypalOrderId) {
    try {
      const result = await captureOrder(order.paypalOrderId);
      const paid = result.status === "COMPLETED";
      const updated = await prisma.order.update({
        where: { id: order.id },
        data: {
          status: paid ? "PAID" : "FAILED",
          paidAt: paid ? new Date() : null,
          paypalCaptureId: result.captureId,
        },
      });
      status = updated.status;
      if (paid) {
        // Upsert atomique : Delivery.orderId est @unique, donc meme si
        // l'utilisateur rafraichit la page ou que /api/paypal/capture est
        // appele en parallele, on n'aura qu'une seule livraison.
        await prisma.delivery.upsert({
          where: { orderId: order.id },
          update: {},
          create: {
            orderId: order.id,
            userId: order.userId,
            itemId: order.itemId,
            payload: order.item.payload,
            status: "PENDING",
          },
        });
      }
    } catch (err) {
      console.error("Capture error on success page", err);
    }
  }

  const paid = status === "PAID";

  return (
    <div className="mx-auto mt-16 max-w-xl card p-8 text-center">
      <div
        className={`mx-auto grid h-14 w-14 place-items-center rounded-full ${
          paid ? "bg-green-500/20 text-green-400" : "bg-yellow-500/20 text-yellow-300"
        }`}
      >
        {paid ? "✓" : "…"}
      </div>
      <h1 className="mt-4 text-2xl font-bold">
        {paid ? "Paiement confirme" : "Paiement en cours"}
      </h1>
      <p className="mt-2 text-white/70">
        {paid
          ? `Merci ! Ton item "${order.item.name}" sera livre dans les 30 prochaines secondes quand tu es connecte sur FRZ RP.`
          : "Ton paiement n'a pas encore ete confirme par PayPal. Reessaie dans quelques secondes."}
      </p>
      <div className="mt-6 flex justify-center gap-3">
        <Link href="/account" className="btn btn-primary">
          Voir mes commandes
        </Link>
        <Link href="/shop" className="btn btn-ghost">
          Continuer les achats
        </Link>
      </div>
    </div>
  );
}
