"use client";

import { useState } from "react";

type LinkState = {
  code: string;
  linked: boolean;
  linkedAt: string | null;
  license: string | null;
  citizenid: string | null;
};

export function FivemLinkCard({ initial }: { initial: LinkState | null }) {
  const [link, setLink] = useState<LinkState | null>(initial);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function generate() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/account/fivem-link", { method: "POST" });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = (await res.json()) as LinkState;
      setLink(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : "erreur");
    } finally {
      setLoading(false);
    }
  }

  if (link?.linked) {
    return (
      <div className="card p-6">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-sm uppercase tracking-wider text-white/50">
              Compte FiveM lie
            </div>
            <div className="mt-1 text-lg font-semibold text-green-400">
              Personnage QBCore lie ✓
            </div>
            <div className="mt-1 text-xs text-white/50">
              citizenid <code className="text-white/80">{link.citizenid}</code>
            </div>
          </div>
          <div className="text-right text-xs text-white/50">
            lie le {new Date(link.linkedAt ?? "").toLocaleDateString("fr-FR")}
          </div>
        </div>
        <p className="mt-4 text-sm text-white/60">
          Tes prochains achats seront livres directement sur ce personnage (meme
          si Discord n&apos;est pas ouvert pendant que tu joues).
        </p>
      </div>
    );
  }

  return (
    <div className="card p-6">
      <div className="text-sm uppercase tracking-wider text-white/50">
        Lier mon compte FiveM
      </div>
      <p className="mt-2 text-sm text-white/70">
        Genere un code et tape <code className="text-yellow-400">/linkshop CODE</code>{" "}
        dans le tchat du serveur FRZ RP pour que tes achats soient livres
        directement sur ton personnage QBCore.
      </p>

      {link?.code ? (
        <div className="mt-4 flex items-center gap-4">
          <div className="rounded-lg border border-yellow-400/40 bg-yellow-400/10 px-6 py-4 font-mono text-3xl font-black tracking-[0.3em] text-yellow-400">
            {link.code}
          </div>
          <div className="text-sm text-white/60">
            Dans le serveur FiveM, tape :
            <div className="mt-1 font-mono text-white">
              /linkshop {link.code}
            </div>
          </div>
        </div>
      ) : null}

      <div className="mt-4 flex items-center gap-3">
        <button
          onClick={generate}
          disabled={loading}
          className="btn btn-ghost disabled:opacity-50"
        >
          {loading
            ? "…"
            : link?.code
              ? "Regenerer un nouveau code"
              : "Generer mon code de liaison"}
        </button>
        {error ? (
          <span className="text-sm text-red-400">Erreur : {error}</span>
        ) : null}
      </div>
    </div>
  );
}
