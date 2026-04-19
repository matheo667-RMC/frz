import { NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import {
  createSession,
  exchangeDiscordCode,
  fetchDiscordMe,
} from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { env } from "@/lib/env";

export async function GET(req: NextRequest) {
  const url = new URL(req.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const jar = await cookies();
  const expected = jar.get("discord_oauth_state")?.value;

  if (!code || !state || !expected || state !== expected) {
    return NextResponse.redirect(
      new URL("/?error=oauth_state", env.appUrl),
    );
  }
  jar.delete("discord_oauth_state");

  try {
    const tokens = await exchangeDiscordCode(code);
    const me = await fetchDiscordMe(tokens.access_token);

    const displayName = me.global_name || me.username;
    const isBootstrapAdmin =
      env.adminDiscordId !== undefined && env.adminDiscordId === me.id;

    const user = await prisma.user.upsert({
      where: { discordId: me.id },
      update: {
        username: displayName,
        avatar: me.avatar,
        email: me.email ?? undefined,
        ...(isBootstrapAdmin ? { isAdmin: true } : {}),
      },
      create: {
        discordId: me.id,
        username: displayName,
        avatar: me.avatar,
        email: me.email ?? undefined,
        isAdmin: isBootstrapAdmin,
      },
    });

    await createSession({
      userId: user.id,
      discordId: user.discordId,
      username: user.username,
      isAdmin: user.isAdmin,
    });

    return NextResponse.redirect(new URL("/account", env.appUrl));
  } catch (err) {
    console.error("Discord OAuth error", err);
    return NextResponse.redirect(new URL("/?error=oauth", env.appUrl));
  }
}
