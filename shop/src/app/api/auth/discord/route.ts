import { NextResponse } from "next/server";
import { buildDiscordAuthorizeUrl } from "@/lib/auth";
import { randomBytes } from "crypto";
import { cookies } from "next/headers";

export async function GET() {
  const state = randomBytes(16).toString("hex");
  const jar = await cookies();
  jar.set("discord_oauth_state", state, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 10,
  });
  return NextResponse.redirect(buildDiscordAuthorizeUrl(state));
}
