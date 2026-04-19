import Link from "next/link";
import type { SessionPayload } from "@/lib/auth";

type Props = { session: SessionPayload | null };

export function Header({ session }: Props) {
  return (
    <header className="sticky top-0 z-30 border-b border-white/5 bg-[rgba(5,6,10,0.75)] backdrop-blur">
      <div className="mx-auto flex w-full max-w-6xl items-center justify-between px-4 py-3">
        <Link href="/" className="group flex items-center gap-2">
          <span
            aria-hidden
            className="grid h-8 w-8 place-items-center rounded-md bg-yellow-400 font-black text-black shadow"
          >
            F
          </span>
          <span className="text-lg font-extrabold tracking-wide">
            FRZ <span className="text-yellow-400">RP</span>
          </span>
          <span className="ml-2 hidden text-xs text-white/50 sm:inline">
            Boutique officielle
          </span>
        </Link>
        <nav className="flex items-center gap-2 text-sm">
          <Link
            href="/shop"
            className="rounded px-3 py-1.5 text-white/80 hover:bg-white/5"
          >
            Boutique
          </Link>
          {session ? (
            <>
              <Link
                href="/account"
                className="rounded px-3 py-1.5 text-white/80 hover:bg-white/5"
              >
                Mon compte
              </Link>
              {session.isAdmin ? (
                <Link
                  href="/admin"
                  className="rounded px-3 py-1.5 text-yellow-300 hover:bg-yellow-400/10"
                >
                  Admin
                </Link>
              ) : null}
              <span className="hidden items-center gap-2 rounded-md border border-white/10 bg-white/5 px-2.5 py-1 text-xs text-white/80 sm:inline-flex">
                <span className="inline-block h-1.5 w-1.5 rounded-full bg-green-400" />
                {session.username}
              </span>
              <form action="/api/auth/logout" method="post">
                <button className="btn btn-ghost">Deconnexion</button>
              </form>
            </>
          ) : (
            <a href="/api/auth/discord" className="btn btn-primary">
              Connexion Discord
            </a>
          )}
        </nav>
      </div>
    </header>
  );
}
