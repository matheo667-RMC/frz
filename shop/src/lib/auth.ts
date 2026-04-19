import { SignJWT, jwtVerify } from "jose";
import { cookies } from "next/headers";
import { env } from "./env";
import { prisma } from "./prisma";

const COOKIE_NAME = "frzrp_session";
const COOKIE_MAX_AGE = 60 * 60 * 24 * 30; // 30 jours

export type SessionPayload = {
  userId: string;
  discordId: string;
  username: string;
  isAdmin: boolean;
};

function secretKey(): Uint8Array {
  return new TextEncoder().encode(env.sessionSecret());
}

export async function createSession(payload: SessionPayload): Promise<void> {
  const token = await new SignJWT({ ...payload })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime(`${COOKIE_MAX_AGE}s`)
    .sign(secretKey());

  (await cookies()).set(COOKIE_NAME, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: COOKIE_MAX_AGE,
  });
}

export async function destroySession(): Promise<void> {
  (await cookies()).delete(COOKIE_NAME);
}

export async function getSession(): Promise<SessionPayload | null> {
  const token = (await cookies()).get(COOKIE_NAME)?.value;
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, secretKey());
    return {
      userId: String(payload.userId),
      discordId: String(payload.discordId),
      username: String(payload.username),
      isAdmin: Boolean(payload.isAdmin),
    };
  } catch {
    return null;
  }
}

/** Recharge l'utilisateur depuis la DB (utile pour verifier isAdmin). */
export async function getCurrentUser() {
  const session = await getSession();
  if (!session) return null;
  return prisma.user.findUnique({ where: { id: session.userId } });
}

// ---- Discord OAuth helpers --------------------------------------------------

export const DISCORD_AUTHORIZE_URL = "https://discord.com/oauth2/authorize";
export const DISCORD_TOKEN_URL = "https://discord.com/api/oauth2/token";
export const DISCORD_ME_URL = "https://discord.com/api/users/@me";

export function discordRedirectUri(): string {
  return `${env.appUrl}/api/auth/discord/callback`;
}

export function buildDiscordAuthorizeUrl(state: string): string {
  const params = new URLSearchParams({
    client_id: env.discord.clientId(),
    response_type: "code",
    scope: "identify email",
    redirect_uri: discordRedirectUri(),
    state,
    prompt: "none",
  });
  return `${DISCORD_AUTHORIZE_URL}?${params.toString()}`;
}

export type DiscordTokenResponse = {
  access_token: string;
  token_type: string;
  expires_in: number;
  refresh_token: string;
  scope: string;
};

export type DiscordMe = {
  id: string;
  username: string;
  global_name?: string | null;
  avatar: string | null;
  email?: string | null;
};

export async function exchangeDiscordCode(
  code: string,
): Promise<DiscordTokenResponse> {
  const body = new URLSearchParams({
    client_id: env.discord.clientId(),
    client_secret: env.discord.clientSecret(),
    grant_type: "authorization_code",
    code,
    redirect_uri: discordRedirectUri(),
  });
  const res = await fetch(DISCORD_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });
  if (!res.ok) {
    throw new Error(`Discord token exchange failed: ${res.status}`);
  }
  return (await res.json()) as DiscordTokenResponse;
}

export async function fetchDiscordMe(accessToken: string): Promise<DiscordMe> {
  const res = await fetch(DISCORD_ME_URL, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    throw new Error(`Discord me failed: ${res.status}`);
  }
  return (await res.json()) as DiscordMe;
}
