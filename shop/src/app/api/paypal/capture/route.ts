import { NextResponse } from "next/server";
import { z } from "zod";
import { getSession } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { captureOrder } from "@/lib/paypal";

const bodySchema = z.object({
  orderId: z.string().min(1), // id interne de Order
});

export async function POST(req: Request) {
  const session = await getSession();
  if (!session) {
    return NextResponse.json(
      { error: "Connexion Discord requise" },
      { status: 401 },
    );
  }
  const json = await req.json().catch(() => null);
  const parsed = bodySchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json({ error: "Requete invalide" }, { status: 400 });
  }

  const order = await prisma.order.findUnique({
    where: { id: parsed.data.orderId },
    include: { item: true },
  });
  if (!order || order.userId !== session.userId) {
    return NextResponse.json({ error: "Commande introuvable" }, { status: 404 });
  }
  if (order.status === "PAID") {
    return NextResponse.json({ status: "PAID", alreadyCaptured: true });
  }
  if (!order.paypalOrderId) {
    return NextResponse.json(
      { error: "PayPal order id manquant" },
      { status: 400 },
    );
  }

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

    if (paid) {
      // Evite les doublons si la capture est appelee plusieurs fois (retries,
      // race entre /checkout/success et cette route, etc.).
      const existing = await prisma.delivery.findFirst({
        where: { orderId: order.id },
      });
      if (!existing) {
        await prisma.delivery.create({
          data: {
            orderId: order.id,
            userId: order.userId,
            itemId: order.itemId,
            payload: order.item.payload,
            status: "PENDING",
          },
        });
      }
    }

    return NextResponse.json({ status: updated.status });
  } catch (err) {
    console.error("PayPal capture failed", err);
    return NextResponse.json(
      { error: "Capture impossible" },
      { status: 502 },
    );
  }
}
