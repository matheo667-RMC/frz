"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { CATEGORIES } from "@/lib/items";

type ItemFormValues = {
  id?: string;
  slug: string;
  name: string;
  description: string;
  category: string;
  priceEur: string; // saisie en euros, converti en cents
  imageUrl: string;
  active: boolean;
  featured: boolean;
  payloadJson: string;
};

export function defaultPayloadForCategory(cat: string): string {
  switch (cat) {
    case "weapon":
      return JSON.stringify(
        { type: "weapon", name: "weapon_pistol", amount: 1, ammo: 100 },
        null,
        2,
      );
    case "vehicle":
      return JSON.stringify(
        { type: "vehicle", model: "adder" },
        null,
        2,
      );
    case "item":
      return JSON.stringify(
        { type: "item", name: "lockpick", amount: 1 },
        null,
        2,
      );
    case "vip":
      return JSON.stringify(
        { type: "vip", tier: "gold", days: 30 },
        null,
        2,
      );
    case "money":
      return JSON.stringify(
        { type: "money", account: "bank", amount: 50000 },
        null,
        2,
      );
    default:
      return "{}";
  }
}

export function ItemForm({ initial }: { initial?: ItemFormValues }) {
  const router = useRouter();
  const [values, setValues] = useState<ItemFormValues>(
    initial ?? {
      slug: "",
      name: "",
      description: "",
      category: "weapon",
      priceEur: "9.99",
      imageUrl: "",
      active: true,
      featured: false,
      payloadJson: defaultPayloadForCategory("weapon"),
    },
  );
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  function setField<K extends keyof ItemFormValues>(
    key: K,
    value: ItemFormValues[K],
  ) {
    setValues((v) => ({ ...v, [key]: value }));
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSaving(true);
    try {
      let payload: unknown;
      try {
        payload = JSON.parse(values.payloadJson);
      } catch {
        throw new Error("Payload JSON invalide");
      }
      const priceCents = Math.round(
        parseFloat(values.priceEur.replace(",", ".")) * 100,
      );
      if (!Number.isFinite(priceCents) || priceCents <= 0) {
        throw new Error("Prix invalide");
      }
      const body = {
        slug: values.slug,
        name: values.name,
        description: values.description,
        category: values.category,
        priceCents,
        currency: "EUR",
        imageUrl: values.imageUrl || null,
        payload,
        active: values.active,
        featured: values.featured,
      };
      const url = initial?.id
        ? `/api/admin/items/${initial.id}`
        : "/api/admin/items";
      const method = initial?.id ? "PUT" : "POST";
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data?.error ?? `Erreur ${res.status}`);
      }
      router.push("/admin");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erreur inconnue");
    } finally {
      setSaving(false);
    }
  }

  async function onDelete() {
    if (!initial?.id) return;
    if (!confirm("Desactiver cet item ?")) return;
    setSaving(true);
    try {
      const res = await fetch(`/api/admin/items/${initial.id}`, {
        method: "DELETE",
      });
      if (!res.ok) throw new Error(`Erreur ${res.status}`);
      router.push("/admin");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erreur");
      setSaving(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="grid grid-cols-1 gap-6 lg:grid-cols-2">
      <div className="space-y-4">
        <div>
          <label className="label">Slug (URL)</label>
          <input
            className="input mt-1"
            value={values.slug}
            onChange={(e) => setField("slug", e.target.value)}
            placeholder="pistolet-legendaire"
            pattern="[a-z0-9-]+"
            required
            disabled={Boolean(initial?.id)}
          />
        </div>
        <div>
          <label className="label">Nom</label>
          <input
            className="input mt-1"
            value={values.name}
            onChange={(e) => setField("name", e.target.value)}
            placeholder="Pistolet legendaire"
            required
          />
        </div>
        <div>
          <label className="label">Description</label>
          <textarea
            className="input mt-1 h-28"
            value={values.description}
            onChange={(e) => setField("description", e.target.value)}
            placeholder="Decris l'item, les effets en jeu, les restrictions…"
            required
          />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="label">Categorie</label>
            <select
              className="input mt-1"
              value={values.category}
              onChange={(e) => {
                const cat = e.target.value;
                setValues((v) => ({
                  ...v,
                  category: cat,
                  payloadJson: initial
                    ? v.payloadJson
                    : defaultPayloadForCategory(cat),
                }));
              }}
            >
              {CATEGORIES.map((c) => (
                <option key={c.value} value={c.value}>
                  {c.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">Prix (EUR)</label>
            <input
              className="input mt-1"
              type="text"
              inputMode="decimal"
              value={values.priceEur}
              onChange={(e) => setField("priceEur", e.target.value)}
              placeholder="9.99"
              required
            />
          </div>
        </div>
        <div>
          <label className="label">URL image (optionnel)</label>
          <input
            className="input mt-1"
            type="url"
            value={values.imageUrl}
            onChange={(e) => setField("imageUrl", e.target.value)}
            placeholder="https://…"
          />
        </div>
        <div className="flex flex-wrap gap-6">
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={values.active}
              onChange={(e) => setField("active", e.target.checked)}
            />
            Actif (visible en boutique)
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={values.featured}
              onChange={(e) => setField("featured", e.target.checked)}
            />
            Mettre en vedette
          </label>
        </div>
      </div>

      <div className="space-y-4">
        <div>
          <label className="label">Payload livre en jeu (QBCore)</label>
          <textarea
            className="input mt-1 h-72 font-mono text-xs"
            value={values.payloadJson}
            onChange={(e) => setField("payloadJson", e.target.value)}
            required
          />
          <p className="mt-1 text-xs text-white/50">
            JSON. Types supportes: <code>weapon</code>, <code>vehicle</code>,{" "}
            <code>item</code>, <code>money</code>, <code>vip</code>. Voir{" "}
            <code>src/lib/items.ts</code> pour le schema.
          </p>
        </div>

        {error ? (
          <div className="rounded border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-300">
            {error}
          </div>
        ) : null}

        <div className="flex justify-between gap-3">
          <button
            type="submit"
            disabled={saving}
            className="btn btn-primary disabled:opacity-50"
          >
            {saving
              ? "Enregistrement…"
              : initial?.id
              ? "Enregistrer"
              : "Creer l'item"}
          </button>
          {initial?.id ? (
            <button
              type="button"
              onClick={onDelete}
              className="btn btn-danger"
              disabled={saving}
            >
              Desactiver
            </button>
          ) : null}
        </div>
      </div>
    </form>
  );
}
