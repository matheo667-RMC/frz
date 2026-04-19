import { NextResponse } from "next/server";
import { z } from "zod";
import { getSession } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { createOrder } from "@/lib/paypal";
import { env } from "@/lib/env";

const bodySchema = z.object({
  itemId: z.string().min(1),
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
  const item = await prisma.item.findUnique({
    where: { id: parsed.data.itemId },
  });
  if (!item || !item.active) {
    return NextResponse.json({ error: "Item introuvable" }, { status: 404 });
  }

  const order = await prisma.order.create({
    data: {
      userId: session.userId,
      itemId: item.id,
      amountCents: item.priceCents,
      currency: item.currency,
      status: "PENDING",
    },
  });

  const returnUrl = `${env.appUrl}/checkout/success?order=${order.id}`;
  const cancelUrl = `${env.appUrl}/checkout/cancel?order=${order.id}`;

  try {
    const paypal = await createOrder({
      itemId: item.id,
      itemName: item.name,
      amountCents: item.priceCents,
      currency: item.currency,
      returnUrl,
      cancelUrl,
    });
    await prisma.order.update({
      where: { id: order.id },
      data: { paypalOrderId: paypal.id },
    });
    return NextResponse.json({
      orderId: order.id,
      paypalOrderId: paypal.id,
      approveUrl: paypal.approveUrl,
    });
  } catch (err) {
    console.error("PayPal create-order failed", err);
    await prisma.order.update({
      where: { id: order.id },
      data: { status: "FAILED" },
    });
    return NextResponse.json(
      { error: "PayPal indisponible" },
      { status: 502 },
    );
  }
}
