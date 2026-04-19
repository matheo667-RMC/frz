import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { env } from "@/lib/env";

// GET /api/fivem/pending?discordId=XXXX
// Retourne les livraisons en attente pour le joueur (Discord ID).
// Auth: Authorization: Bearer <FIVEM_API_TOKEN>
export async function GET(req: Request) {
  const auth = req.headers.get("authorization") ?? "";
  const token = auth.replace(/^Bearer\s+/i, "");
  if (!token || token !== env.fivem.apiToken()) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const url = new URL(req.url);
  const discordId = url.searchParams.get("discordId");
  if (!discordId) {
    return NextResponse.json(
      { error: "discordId requis" },
      { status: 400 },
    );
  }
  const user = await prisma.user.findUnique({ where: { discordId } });
  if (!user) {
    return NextResponse.json({ deliveries: [] });
  }
  const deliveries = await prisma.delivery.findMany({
    where: { userId: user.id, status: "PENDING" },
    orderBy: { createdAt: "asc" },
    include: { item: true },
  });

  return NextResponse.json({
    deliveries: deliveries.map((d) => ({
      id: d.id,
      itemId: d.itemId,
      itemName: d.item.name,
      payload: JSON.parse(d.payload),
      createdAt: d.createdAt.toISOString(),
    })),
  });
}
