// Seed de demo pour la boutique FRZ RP.
// Usage: npx prisma db seed
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const items = [
  {
    slug: "pistol-starter",
    name: "Pistolet Starter",
    description:
      "Pistolet basique avec 100 munitions. Parfait pour demarrer ta vie de criminel sur FRZ RP.",
    category: "weapon",
    priceCents: 499,
    featured: false,
    imageUrl:
      "https://images.unsplash.com/photo-1605806616949-1e87b487fc2f?w=1200",
    payload: {
      type: "weapon",
      name: "weapon_pistol",
      amount: 1,
      ammo: 100,
    },
  },
  {
    slug: "combat-pistol",
    name: "Combat Pistol",
    description:
      "Pistolet de combat, 150 munitions. Precis, fiable, le favori des braqueurs.",
    category: "weapon",
    priceCents: 999,
    featured: true,
    imageUrl:
      "https://images.unsplash.com/photo-1595590424283-b8f17842773f?w=1200",
    payload: {
      type: "weapon",
      name: "weapon_combatpistol",
      amount: 1,
      ammo: 150,
    },
  },
  {
    slug: "ak-47",
    name: "AK-47 (Assault Rifle)",
    description:
      "L'iconique AK-47. 200 munitions incluses. Reserve aux pros. ",
    category: "weapon",
    priceCents: 2999,
    featured: true,
    imageUrl:
      "https://images.unsplash.com/photo-1584266337361-679ab67bbcc3?w=1200",
    payload: {
      type: "weapon",
      name: "weapon_assaultrifle",
      amount: 1,
      ammo: 200,
    },
  },
  {
    slug: "adder-hypercar",
    name: "Adder (Hypercar)",
    description:
      "Le vehicule hypercar Adder, livre directement dans ton garage. Vitesse de pointe : 375 km/h.",
    category: "vehicle",
    priceCents: 4999,
    featured: true,
    imageUrl:
      "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1200",
    payload: { type: "vehicle", model: "adder" },
  },
  {
    slug: "sultan-rs",
    name: "Sultan RS",
    description:
      "Sportive urbaine, ideale pour les courses de rue et les poursuites.",
    category: "vehicle",
    priceCents: 1999,
    featured: false,
    imageUrl:
      "https://images.unsplash.com/photo-1542362567-b07e54358753?w=1200",
    payload: { type: "vehicle", model: "sultanrs" },
  },
  {
    slug: "lockpick-pack",
    name: "Pack Lockpick x5",
    description: "5 lockpicks livres dans ton inventaire. Pour les cambrioleurs.",
    category: "item",
    priceCents: 299,
    featured: false,
    imageUrl: null,
    payload: { type: "item", name: "lockpick", amount: 5 },
  },
  {
    slug: "vip-gold-30d",
    name: "VIP Gold (30 jours)",
    description:
      "Statut VIP Gold pendant 30 jours : spawn prioritaire, slots reserves, couleur de chat, +10% salaire.",
    category: "vip",
    priceCents: 1499,
    featured: true,
    imageUrl:
      "https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=1200",
    payload: { type: "vip", tier: "gold", days: 30 },
  },
  {
    slug: "cash-50k",
    name: "50 000 $ en banque",
    description:
      "50 000 $ deposes directement sur ton compte bancaire en jeu. Pratique pour demarrer.",
    category: "money",
    priceCents: 999,
    featured: false,
    imageUrl:
      "https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=1200",
    payload: { type: "money", account: "bank", amount: 50000 },
  },
];

async function main() {
  for (const it of items) {
    await prisma.item.upsert({
      where: { slug: it.slug },
      update: {
        name: it.name,
        description: it.description,
        category: it.category,
        priceCents: it.priceCents,
        imageUrl: it.imageUrl ?? null,
        featured: it.featured,
        payload: JSON.stringify(it.payload),
      },
      create: {
        slug: it.slug,
        name: it.name,
        description: it.description,
        category: it.category,
        priceCents: it.priceCents,
        currency: "EUR",
        imageUrl: it.imageUrl ?? null,
        active: true,
        featured: it.featured,
        payload: JSON.stringify(it.payload),
      },
    });
  }
  console.log(`Seeded ${items.length} items.`);
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
