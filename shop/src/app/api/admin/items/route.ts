import { NextResponse } from "next/server";
import { z } from "zod";
import { getCurrentUser } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { payloadSchema } from "@/lib/items";

const createSchema = z.object({
  slug: z
    .string()
    .min(2)
    .max(80)
    .regex(/^[a-z0-9-]+$/, "slug alphanumerique en minuscules, tirets autorises"),
  name: z.string().min(1).max(120),
  description: z.string().min(1).max(2000),
  category: z.enum(["weapon", "vehicle", "item", "vip", "money"]),
  priceCents: z.number().int().positive(),
  currency: z.string().length(3).default("EUR"),
  imageUrl: z.string().url().optional().nullable(),
  payload: payloadSchema,
  active: z.boolean().default(true),
  featured: z.boolean().default(false),
});

async function requireAdmin() {
  const user = await getCurrentUser();
  if (!user || !user.isAdmin) return null;
  return user;
}

export async function POST(req: Request) {
  const admin = await requireAdmin();
  if (!admin) {
    return NextResponse.json({ error: "forbidden" }, { status: 403 });
  }
  const json = await req.json().catch(() => null);
  const parsed = createSchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "invalid", issues: parsed.error.issues },
      { status: 400 },
    );
  }
  const data = parsed.data;
  try {
    const item = await prisma.item.create({
      data: {
        slug: data.slug,
        name: data.name,
        description: data.description,
        category: data.category,
        priceCents: data.priceCents,
        currency: data.currency,
        imageUrl: data.imageUrl ?? null,
        payload: JSON.stringify(data.payload),
        active: data.active,
        featured: data.featured,
      },
    });
    return NextResponse.json({ item });
  } catch (err: unknown) {
    const msg =
      err instanceof Error && err.message.includes("Unique")
        ? "slug_already_exists"
        : "db_error";
    return NextResponse.json({ error: msg }, { status: 400 });
  }
}
