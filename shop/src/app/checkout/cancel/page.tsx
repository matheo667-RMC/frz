import Link from "next/link";

export default function CancelPage() {
  return (
    <div className="mx-auto mt-16 max-w-xl card p-8 text-center">
      <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-white/10 text-white/70">
        ×
      </div>
      <h1 className="mt-4 text-2xl font-bold">Paiement annule</h1>
      <p className="mt-2 text-white/60">
        Tu peux reessayer a tout moment, aucun montant n&apos;a ete debite.
      </p>
      <div className="mt-6 flex justify-center gap-3">
        <Link href="/shop" className="btn btn-primary">
          Retour a la boutique
        </Link>
      </div>
    </div>
  );
}
