import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { env } from "@/lib/env";

const bodySchema = z.object({
  deliveryId: z.string().min(1),
  status: z.enum(["DELIVERED", "FAILED"]).default("DELIVERED"),
  note: z.string().max(500).optional(),
});

// POST /api/fivem/deliver
// Body: { deliveryId, status?, note? }
// Auth: Authorization: Bearer <FIVEM_API_TOKEN>
export async function POST(req: Request) {
  const auth = req.headers.get("authorization") ?? "";
  const token = auth.replace(/^Bearer\s+/i, "");
  if (!token || token !== env.fivem.apiToken()) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const json = await req.json().catch(() => null);
  const parsed = bodySchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json({ error: "Requete invalide" }, { status: 400 });
  }

  const delivery = await prisma.delivery.findUnique({
    where: { id: parsed.data.deliveryId },
  });
  if (!delivery) {
    return NextResponse.json({ error: "Livraison introuvable" }, { status: 404 });
  }
  if (delivery.status !== "PENDING") {
    return NextResponse.json({ ok: true, alreadyProcessed: true });
  }

  await prisma.delivery.update({
    where: { id: delivery.id },
    data: {
      status: parsed.data.status,
      note: parsed.data.note,
      deliveredAt:
        parsed.data.status === "DELIVERED" ? new Date() : null,
    },
  });
  return NextResponse.json({ ok: true });
}
