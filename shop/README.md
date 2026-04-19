# FRZ RP — Boutique officielle (site web)

Site Next.js 14 ou les joueurs du serveur GTA RP **FRZ RP** achetent des items
(armes, vehicules, packs VIP, argent…) en vraie monnaie via **PayPal**. Les
items sont ensuite livres automatiquement en jeu par la ressource FiveM
[`fivem-shop`](../fivem-shop).

## Stack

- Next.js 14 (App Router) + TypeScript + Tailwind CSS
- Prisma ORM + SQLite (dev) / Postgres (prod)
- Authentification par Discord OAuth (cookie JWT via `jose`)
- Paiements PayPal Checkout (Orders v2)
- API interne `/api/fivem/*` protegee par token Bearer, consommee par la
  ressource QBCore pour livrer en jeu

## Pages principales

- `/` : vitrine avec items en vedette et nouveautes
- `/shop` : catalogue filtrable par categorie
- `/shop/[slug]` : fiche item avec bouton "Acheter avec PayPal"
- `/checkout/success` : page de retour PayPal (capture du paiement)
- `/account` : commandes et historique des livraisons du joueur
- `/admin` : dashboard admin (catalogue, commandes, stats)
- `/admin/items/new` et `/admin/items/[id]/edit` : CRUD des items

## Demarrage (developpement)

```bash
cd shop
cp .env.example .env          # puis editer les valeurs
npm install
npx prisma migrate dev --name init
npm run db:seed               # seed 8 items de demo
npm run dev                   # http://localhost:3000
```

### Variables d'environnement

Voir [`.env.example`](./.env.example). Minimum requis :

- `NEXT_PUBLIC_APP_URL` : URL publique du site
- `DATABASE_URL` : connexion SQLite/Postgres
- `SESSION_SECRET` : `openssl rand -base64 32`
- `DISCORD_CLIENT_ID` / `DISCORD_CLIENT_SECRET` : via
  [Discord Developer Portal](https://discord.com/developers/applications).
  Redirect URI a ajouter :
  `<NEXT_PUBLIC_APP_URL>/api/auth/discord/callback`
- `PAYPAL_MODE` (`sandbox` / `live`), `PAYPAL_CLIENT_ID`,
  `PAYPAL_CLIENT_SECRET` : via
  [PayPal Developer](https://developer.paypal.com/dashboard/applications/sandbox)
- `FIVEM_API_TOKEN` : `openssl rand -hex 32`, a copier aussi dans
  `fivem-shop/config.lua` cote serveur FiveM
- `ADMIN_DISCORD_ID` (optionnel) : Discord ID du proprio a promouvoir admin
  automatiquement a sa premiere connexion

## Promotion d'un admin

Deux options :

1. Definir `ADMIN_DISCORD_ID` dans le `.env` avant la premiere connexion du
   proprietaire — il sera promu admin automatiquement.
2. Directement en base : `UPDATE User SET isAdmin = 1 WHERE discordId = '...'`.

## Schema de la base

- `User` : identifie par `discordId` (snowflake Discord).
- `Item` : catalogue boutique. Chaque item a un `payload` JSON qui decrit ce
  qui est livre en jeu (voir [`src/lib/items.ts`](./src/lib/items.ts) pour le
  schema des payloads supportes par QBCore).
- `Order` : commande PayPal (PENDING / PAID / FAILED / REFUNDED).
- `Delivery` : livraison en jeu (PENDING tant que FiveM ne l'a pas livree).
- `WebhookLog` : audit des webhooks pour debug.

## API FiveM

Protegee par `Authorization: Bearer <FIVEM_API_TOKEN>`.

### `GET /api/fivem/pending?discordId=<snowflake>`

Retourne les livraisons `PENDING` du joueur.
```json
{
  "deliveries": [
    {
      "id": "cl...",
      "itemId": "cl...",
      "itemName": "Combat Pistol",
      "payload": { "type": "weapon", "name": "weapon_combatpistol", "amount": 1, "ammo": 150 },
      "createdAt": "2026-04-19T16:44:00.000Z"
    }
  ]
}
```

### `POST /api/fivem/deliver`

Body : `{ "deliveryId": "cl...", "status": "DELIVERED" | "FAILED", "note"?: "..." }`.
Marque la livraison comme traitee.

## Production

- Basculer `PAYPAL_MODE="live"` + identifiants PayPal de prod.
- Utiliser Postgres en base de donnees ; changer le provider dans
  `prisma/schema.prisma` et lancer `prisma migrate deploy`.
- Deployer derriere HTTPS (Vercel, Fly.io, Railway, etc.). Configurer
  l'URL publique dans le Discord Developer Portal (redirect OAuth) et dans
  `NEXT_PUBLIC_APP_URL`.
- Restreindre l'acces a `/api/fivem/*` au serveur FiveM via un WAF si
  possible (en complement du token).

## Scripts

| Script | Description |
| --- | --- |
| `npm run dev` | Dev server Next.js |
| `npm run build` | Build de prod |
| `npm run start` | Demarre le build de prod |
| `npm run lint` | ESLint |
| `npm run typecheck` | `tsc --noEmit` |
| `npm run db:migrate` | `prisma migrate dev` |
| `npm run db:seed` | Seed des 8 items de demo |
| `npm run db:push` | Synchronise la DB au schema sans creer de migration |
