// Validation et typage des variables d'environnement.
// Le but est d'obtenir des erreurs claires au runtime si une variable manque,
// plutot que des "undefined" silencieux un peu partout dans le code.

function required(name: string): string {
  const value = process.env[name];
  if (!value || value.length === 0) {
    throw new Error(
      `Variable d'environnement manquante: ${name}. Voir shop/.env.example`,
    );
  }
  return value;
}

function optional(name: string): string | undefined {
  const value = process.env[name];
  return value && value.length > 0 ? value : undefined;
}

export const env = {
  appUrl: process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000",
  sessionSecret: () => required("SESSION_SECRET"),
  discord: {
    clientId: () => required("DISCORD_CLIENT_ID"),
    clientSecret: () => required("DISCORD_CLIENT_SECRET"),
  },
  paypal: {
    mode: (process.env.PAYPAL_MODE ?? "sandbox") as "sandbox" | "live",
    clientId: () => required("PAYPAL_CLIENT_ID"),
    clientSecret: () => required("PAYPAL_CLIENT_SECRET"),
    webhookId: () => optional("PAYPAL_WEBHOOK_ID"),
  },
  fivem: {
    apiToken: () => required("FIVEM_API_TOKEN"),
  },
  adminDiscordId: optional("ADMIN_DISCORD_ID"),
};

export function paypalApiBase(): string {
  return env.paypal.mode === "live"
    ? "https://api-m.paypal.com"
    : "https://api-m.sandbox.paypal.com";
}
