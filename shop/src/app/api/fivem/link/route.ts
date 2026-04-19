import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { env } from "@/lib/env";

const bodySchema = z.object({
  code: z.string().min(4).max(16),
  license: z.string().min(4).max(128),
  citizenid: z.string().min(1).max(64),
});

// Revendique un code de liaison cote FiveM : attache license + citizenid
// au compte shop qui a genere le code. Appele par la resource Lua suite a
// la commande `/linkshop <code>`.
//
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
    return NextResponse.json(
      { error: "invalid", issues: parsed.error.issues },
      { status: 400 },
    );
  }
  const { code, license, citizenid } = parsed.data;

  const link = await prisma.fivemLink.findUnique({
    where: { code },
    include: { user: true },
  });
  if (!link) {
    return NextResponse.json(
      { error: "code_invalide", message: "Code inconnu ou deja utilise" },
      { status: 404 },
    );
  }
  if (link.linkedAt) {
    return NextResponse.json(
      {
        error: "deja_lie",
        message: `Ce compte est deja lie a ${link.user.username}`,
      },
      { status: 409 },
    );
  }

  // Verifie que license/citizenid ne sont pas deja pris par un autre compte.
  const existing = await prisma.fivemLink.findFirst({
    where: {
      OR: [{ license }, { citizenid }],
      NOT: { userId: link.userId },
    },
  });
  if (existing) {
    return NextResponse.json(
      {
        error: "identifiants_deja_lies",
        message:
          "Ce personnage FiveM est deja lie a un autre compte du shop.",
      },
      { status: 409 },
    );
  }

  const updated = await prisma.fivemLink.update({
    where: { id: link.id },
    data: {
      license,
      citizenid,
      linkedAt: new Date(),
    },
    include: { user: true },
  });

  return NextResponse.json({
    success: true,
    username: updated.user.username,
    discordId: updated.user.discordId,
    linkedAt: updated.linkedAt?.toISOString(),
  });
}
