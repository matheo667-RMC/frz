import { NextResponse } from "next/server";
import { randomBytes } from "crypto";
import { getSession } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

// Genere (ou regenere) un code de liaison FiveM pour l'utilisateur courant.
// Le joueur utilise ensuite `/linkshop <code>` dans le serveur FiveM pour
// associer son personnage QBCore a son compte du shop.
//
// Si le compte est deja lie, on retourne juste l'etat actuel sans rien
// regenerer : pas besoin d'un nouveau code une fois le lien etabli.
export async function POST() {
  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const existing = await prisma.fivemLink.findUnique({
    where: { userId: session.userId },
  });
  if (existing?.linkedAt) {
    return NextResponse.json(toPayload(existing));
  }

  const code = generateCode();
  const link = await prisma.fivemLink.upsert({
    where: { userId: session.userId },
    update: { code },
    create: { userId: session.userId, code },
  });
  return NextResponse.json(toPayload(link));
}

function toPayload(link: {
  code: string;
  linkedAt: Date | null;
  license: string | null;
  citizenid: string | null;
}) {
  return {
    code: link.code,
    linked: Boolean(link.linkedAt),
    linkedAt: link.linkedAt?.toISOString() ?? null,
    license: link.license,
    citizenid: link.citizenid,
  };
}

// Code humain-friendly : 6 caracteres alphanumeriques sans ambiguite.
// ~32^6 = 1 milliard de combinaisons. On utilise un PRNG cryptographique car
// ces codes permettent de revendiquer un compte payant (attach license + citizenid)
// — un attaquant capable de predire des codes pourrait hijacker le lien d'un
// autre utilisateur et detourner ses achats.
function generateCode() {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // sans I, O, 0, 1
  const bytes = randomBytes(6);
  let out = "";
  for (let i = 0; i < 6; i++) {
    out += alphabet[bytes[i] % alphabet.length];
  }
  return out;
}
