import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { env } from "@/lib/env";

// GET /api/fivem/pending?discordId=XXXX | ?license=XXXX | ?citizenid=XXXX
// Retourne les livraisons en attente pour le joueur. On accepte plusieurs
// identifiants : Discord ID (legacy), ou license/citizenid si le joueur a lie
// son compte via `/linkshop` — ca garantit la livraison sur le bon personnage
// QBCore meme si Discord n'est pas ouvert.
// Auth: Authorization: Bearer <FIVEM_API_TOKEN>
export async function GET(req: Request) {
  const auth = req.headers.get("authorization") ?? "";
  const token = auth.replace(/^Bearer\s+/i, "");
  if (!token || token !== env.fivem.apiToken()) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const url = new URL(req.url);
  const discordId = url.searchParams.get("discordId");
  const license = url.searchParams.get("license");
  const citizenid = url.searchParams.get("citizenid");
  if (!discordId && !license && !citizenid) {
    return NextResponse.json(
      { error: "identifiant requis (discordId, license ou citizenid)" },
      { status: 400 },
    );
  }

  // Resolution de l'utilisateur : prio au lien FiveM (plus fort), fallback Discord.
  let userId: string | null = null;
  if (license || citizenid) {
    const link = await prisma.fivemLink.findFirst({
      where: {
        OR: [
          license ? { license } : {},
          citizenid ? { citizenid } : {},
        ].filter((o) => Object.keys(o).length > 0),
      },
    });
    if (link) userId = link.userId;
  }
  if (!userId && discordId) {
    const user = await prisma.user.findUnique({ where: { discordId } });
    if (user) userId = user.id;
  }
  if (!userId) {
    return NextResponse.json({ deliveries: [] });
  }

  const deliveries = await prisma.delivery.findMany({
    where: { userId, status: "PENDING" },
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
