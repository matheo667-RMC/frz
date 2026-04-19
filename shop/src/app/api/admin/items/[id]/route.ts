import { NextResponse } from "next/server";
import { z } from "zod";
import { getCurrentUser } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { payloadSchema } from "@/lib/items";

const updateSchema = z.object({
  name: z.string().min(1).max(120).optional(),
  description: z.string().min(1).max(2000).optional(),
  category: z.enum(["weapon", "vehicle", "item", "vip", "money"]).optional(),
  priceCents: z.number().int().positive().optional(),
  currency: z.string().length(3).optional(),
  imageUrl: z.string().url().optional().nullable(),
  payload: payloadSchema.optional(),
  active: z.boolean().optional(),
  featured: z.boolean().optional(),
});

async function requireAdmin() {
  const user = await getCurrentUser();
  if (!user || !user.isAdmin) return null;
  return user;
}

export async function PUT(
  req: Request,
  context: { params: Promise<{ id: string }> },
) {
  const admin = await requireAdmin();
  if (!admin) return NextResponse.json({ error: "forbidden" }, { status: 403 });
  const { id } = await context.params;

  const json = await req.json().catch(() => null);
  const parsed = updateSchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "invalid", issues: parsed.error.issues },
      { status: 400 },
    );
  }
  const d = parsed.data;
  const item = await prisma.item.update({
    where: { id },
    data: {
      ...(d.name !== undefined ? { name: d.name } : {}),
      ...(d.description !== undefined ? { description: d.description } : {}),
      ...(d.category !== undefined ? { category: d.category } : {}),
      ...(d.priceCents !== undefined ? { priceCents: d.priceCents } : {}),
      ...(d.currency !== undefined ? { currency: d.currency } : {}),
      ...(d.imageUrl !== undefined ? { imageUrl: d.imageUrl } : {}),
      ...(d.payload !== undefined
        ? { payload: JSON.stringify(d.payload) }
        : {}),
      ...(d.active !== undefined ? { active: d.active } : {}),
      ...(d.featured !== undefined ? { featured: d.featured } : {}),
    },
  });
  return NextResponse.json({ item });
}

export async function DELETE(
  _req: Request,
  context: { params: Promise<{ id: string }> },
) {
  const admin = await requireAdmin();
  if (!admin) return NextResponse.json({ error: "forbidden" }, { status: 403 });
  const { id } = await context.params;
  // On desactive plutot que de supprimer, pour preserver les commandes historiques.
  await prisma.item.update({
    where: { id },
    data: { active: false },
  });
  return NextResponse.json({ ok: true });
}
