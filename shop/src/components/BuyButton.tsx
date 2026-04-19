"use client";

import { useState } from "react";

type Props = {
  itemId: string;
  isLoggedIn: boolean;
};

export function BuyButton({ itemId, isLoggedIn }: Props) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onBuy() {
    setError(null);
    if (!isLoggedIn) {
      window.location.href = "/api/auth/discord";
      return;
    }
    setLoading(true);
    try {
      const res = await fetch("/api/paypal/create-order", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ itemId }),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data?.error ?? `Erreur ${res.status}`);
      }
      if (!data.approveUrl) throw new Error("Lien PayPal manquant");
      window.location.href = data.approveUrl;
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erreur");
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-col gap-2">
      <button
        onClick={onBuy}
        disabled={loading}
        className="btn btn-primary disabled:opacity-50"
      >
        {loading
          ? "Redirection vers PayPal…"
          : isLoggedIn
          ? "Acheter avec PayPal"
          : "Se connecter pour acheter"}
      </button>
      {error ? (
        <p className="text-xs text-red-400">{error}</p>
      ) : (
        <p className="text-xs text-white/40">
          Paiement securise par PayPal. Livraison auto en jeu (FiveM).
        </p>
      )}
    </div>
  );
}
