// Client leger pour l'API PayPal Orders v2.
// https://developer.paypal.com/docs/api/orders/v2/
import { env, paypalApiBase } from "./env";

type PayPalAccessToken = { access_token: string; expires_at: number };

let cachedToken: PayPalAccessToken | null = null;

async function getAccessToken(): Promise<string> {
  const now = Date.now();
  if (cachedToken && cachedToken.expires_at > now + 30_000) {
    return cachedToken.access_token;
  }
  const basic = Buffer.from(
    `${env.paypal.clientId()}:${env.paypal.clientSecret()}`,
  ).toString("base64");

  const res = await fetch(`${paypalApiBase()}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`PayPal token error ${res.status}: ${text}`);
  }
  const data = (await res.json()) as { access_token: string; expires_in: number };
  cachedToken = {
    access_token: data.access_token,
    expires_at: now + data.expires_in * 1000,
  };
  return data.access_token;
}

export type CreateOrderInput = {
  itemId: string;
  itemName: string;
  amountCents: number;
  currency: string;
  returnUrl: string;
  cancelUrl: string;
};

export type CreateOrderResult = {
  id: string;
  approveUrl: string;
};

export async function createOrder(
  input: CreateOrderInput,
): Promise<CreateOrderResult> {
  const token = await getAccessToken();
  const amount = (input.amountCents / 100).toFixed(2);
  const body = {
    intent: "CAPTURE",
    purchase_units: [
      {
        reference_id: input.itemId,
        description: input.itemName.slice(0, 127),
        amount: {
          currency_code: input.currency,
          value: amount,
        },
      },
    ],
    application_context: {
      brand_name: "FRZ RP",
      landing_page: "LOGIN",
      user_action: "PAY_NOW",
      return_url: input.returnUrl,
      cancel_url: input.cancelUrl,
    },
  };
  const res = await fetch(`${paypalApiBase()}/v2/checkout/orders`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`PayPal create order ${res.status}: ${text}`);
  }
  const data = (await res.json()) as {
    id: string;
    links: { rel: string; href: string }[];
  };
  const approve = data.links.find((l) => l.rel === "approve");
  if (!approve) throw new Error("PayPal order: no approve link");
  return { id: data.id, approveUrl: approve.href };
}

export type CaptureOrderResult = {
  orderId: string;
  captureId: string | null;
  status: string;
};

export async function captureOrder(
  orderId: string,
): Promise<CaptureOrderResult> {
  const token = await getAccessToken();
  const res = await fetch(
    `${paypalApiBase()}/v2/checkout/orders/${orderId}/capture`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      // PayPal accepte un body vide pour capture.
      body: "{}",
    },
  );
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`PayPal capture ${res.status}: ${text}`);
  }
  const data = (await res.json()) as {
    id: string;
    status: string;
    purchase_units?: {
      payments?: {
        captures?: { id: string; status: string }[];
      };
    }[];
  };
  const capture = data.purchase_units?.[0]?.payments?.captures?.[0];
  return {
    orderId: data.id,
    captureId: capture?.id ?? null,
    status: data.status,
  };
}
