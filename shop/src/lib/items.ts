// Types et validation du payload "livraison en jeu" QBCore.
import { z } from "zod";

export const payloadSchema = z.discriminatedUnion("type", [
  z.object({
    type: z.literal("weapon"),
    name: z.string().min(1), // ex: "weapon_pistol"
    amount: z.number().int().positive().default(1),
    ammo: z.number().int().nonnegative().default(0),
  }),
  z.object({
    type: z.literal("vehicle"),
    model: z.string().min(1), // ex: "adder"
    plate: z.string().max(8).optional(),
  }),
  z.object({
    type: z.literal("item"),
    name: z.string().min(1), // ex: "vip_pack"
    amount: z.number().int().positive().default(1),
  }),
  z.object({
    type: z.literal("money"),
    account: z.enum(["cash", "bank", "crypto"]).default("bank"),
    amount: z.number().int().positive(),
  }),
  z.object({
    type: z.literal("vip"),
    tier: z.string().min(1), // ex: "gold", "platinum"
    days: z.number().int().positive().default(30),
  }),
]);

export type ItemPayload = z.infer<typeof payloadSchema>;

export function parsePayload(raw: string): ItemPayload | null {
  try {
    const json = JSON.parse(raw);
    const parsed = payloadSchema.safeParse(json);
    return parsed.success ? parsed.data : null;
  } catch {
    return null;
  }
}

export function describePayload(p: ItemPayload): string {
  switch (p.type) {
    case "weapon":
      return `Arme ${p.name} x${p.amount}${p.ammo ? ` (${p.ammo} munitions)` : ""}`;
    case "vehicle":
      return `Vehicule ${p.model}${p.plate ? ` - plaque ${p.plate}` : ""}`;
    case "item":
      return `Item ${p.name} x${p.amount}`;
    case "money":
      return `${p.amount.toLocaleString("fr-FR")} $ sur ${p.account}`;
    case "vip":
      return `VIP ${p.tier} (${p.days} jours)`;
  }
}

export const CATEGORIES = [
  { value: "weapon", label: "Armes" },
  { value: "vehicle", label: "Vehicules" },
  { value: "item", label: "Items" },
  { value: "vip", label: "VIP" },
  { value: "money", label: "Argent" },
] as const;
