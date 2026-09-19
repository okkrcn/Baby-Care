/**
 * Baby Care — OpenRouter vekili (Cloudflare Worker, ücretsiz plan yeterli)
 *
 * Neden vekil: iOS paketine konan anahtar cihazdan çıkarılabilir. Vekil
 * anahtarı kendinde tutar, uygulama yalnız vekil adresini bilir. Uygulama
 * tarafında AISecrets.plist → OPENROUTER_BASE_URL = https://<worker>.workers.dev/api/v1
 *
 * Kurulum:
 *   npm i -g wrangler && wrangler login
 *   wrangler secret put OPENROUTER_API_KEY
 *   wrangler deploy proxy/openrouter-worker.js --name baby-care-ai
 *
 * Yalnız iki uç noktaya izin verir, yalnız ücretsiz modelleri geçirir ve
 * basit bir IP başına dakika kotası uygular (KV gerektirmez; tek izole
 * örnekte yaklaşık sınırlama sağlar — kesin kota için Durable Object/KV kullanın).
 */

const ALLOWED_PATHS = new Set(["/api/v1/chat/completions", "/api/v1/models"]);
const UPSTREAM = "https://openrouter.ai";
const MAX_BODY_BYTES = 64 * 1024;
const RATE_LIMIT_PER_MINUTE = 20;

const buckets = new Map();

function rateLimited(ip) {
  const now = Date.now();
  const window = Math.floor(now / 60_000);
  const key = `${ip}:${window}`;
  const count = (buckets.get(key) ?? 0) + 1;
  buckets.set(key, count);
  if (buckets.size > 5000) buckets.clear();
  return count > RATE_LIMIT_PER_MINUTE;
}

function onlyFreeModels(body) {
  const isFree = (id) => typeof id === "string" && id.endsWith(":free");
  if (body.model && !isFree(body.model)) return false;
  if (Array.isArray(body.models) && !body.models.every(isFree)) return false;
  return true;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (!ALLOWED_PATHS.has(url.pathname)) {
      return new Response("Not found", { status: 404 });
    }
    if (!env.OPENROUTER_API_KEY) {
      return new Response("Proxy misconfigured", { status: 500 });
    }

    const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
    if (rateLimited(ip)) {
      return Response.json(
        { error: { code: 429, message: "Çok fazla istek; bir dakika sonra tekrar deneyin." } },
        { status: 429 }
      );
    }

    let body = null;
    if (request.method === "POST") {
      const raw = await request.text();
      if (raw.length > MAX_BODY_BYTES) {
        return new Response("Payload too large", { status: 413 });
      }
      try {
        body = JSON.parse(raw);
      } catch {
        return new Response("Bad JSON", { status: 400 });
      }
      if (!onlyFreeModels(body)) {
        return Response.json(
          { error: { code: 403, message: "Yalnız ücretsiz modeller kullanılabilir." } },
          { status: 403 }
        );
      }
      body.max_tokens = Math.min(Number(body.max_tokens ?? 700), 1024);
    }

    const upstream = await fetch(UPSTREAM + url.pathname, {
      method: request.method,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${env.OPENROUTER_API_KEY}`,
        "HTTP-Referer": request.headers.get("HTTP-Referer") ?? "https://okkrcn.github.io/Baby-Care/",
        "X-Title": request.headers.get("X-Title") ?? "Baby Care",
      },
      body: body ? JSON.stringify(body) : undefined,
    });

    return new Response(upstream.body, {
      status: upstream.status,
      headers: { "Content-Type": "application/json" },
    });
  },
};
