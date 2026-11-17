#!/usr/bin/env node
// iPhone Duo mağaza ekran görüntüleri: dış ekran (1398x2034) ve iç ekran (2853x2007).
//
// Girdi: docs/screenshots/v1.7/duo/raw/ (iPhone Duo simülatörü, iOS 27.2, durum çubuğu 09:41)
//   dis-0X-*.png  kapalı poz, dış ekran 1398x2034
//   ic-0X-*.png   açık poz, iç ekran 2853x2007 (yatay)
// Çıktı: docs/screenshots/v1.7/duo/appstore/{dis,ic}-0X-*.png, alpha yok
//
// Görsel dil 1.7 setinden gelir: krem arka plan (v1.6/background-generated.png),
// koyu kahverengi serif başlık, ince koyu çerçeveli gerçek ekran görüntüsü.
// Uygulama pikselleri yeniden çizilmez; yalnız ölçeklenir.
//
// Kullanım: node scripts/build-appstore-duo.mjs

import { spawn, execSync } from "node:child_process";
import { readFileSync, writeFileSync, mkdtempSync, mkdirSync, existsSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DUO = join(ROOT, "docs", "screenshots", "v1.7", "duo");
const RAW = join(DUO, "raw");
const OUT = join(DUO, "appstore");
const BG = join(ROOT, "docs", "screenshots", "v1.6", "background-generated.png");
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const b64 = (p) => readFileSync(p).toString("base64");

const COLORS = { title: "#3B2417", frame: "#2A1F19" };
const SERIF = `"Georgia","Iowan Old Style","Times New Roman",serif`;

// Başlıklar mevcut mağaza setleriyle aynı dilde (1.6 iPhone/iPad, 1.7).
const SCREENS = [
  { key: "01-ana-sayfa",     title: ["Bebeğinin bakımı", "tek ekranda"] },
  { key: "02-dis-gelisimi",  title: ["Süt dişlerini", "tek tek işaretleyin"] },
  { key: "03-buyume",        title: ["Gelişimi DSÖ", "persentiliyle izle"] },
  { key: "04-ek-gida",       title: ["Ek gıdada", "ay ay rehber"] },
];

// Ekran boyutuna göre yerleşim. Dış ekran dikey: iki satır başlık, altta ekran.
// İç ekran yatay: tek satır başlık, altta geniş ekran.
const LAYOUTS = {
  dis: { w: 1398, h: 2034, titleTop: 92, fontSize: 84, lines: 2, frameW: 1000, bottom: 80, border: 12 },
  ic:  { w: 2853, h: 2007, titleTop: 96, fontSize: 104, lines: 1, frameW: 2200, bottom: 84, border: 14 },
};

function slide(L, title, rawB64, rawW, rawH) {
  const imgH = Math.round(L.frameW * rawH / rawW);
  const frameTop = L.h - L.bottom - imgH - 2 * L.border;
  const left = Math.round((L.w - L.frameW - 2 * L.border) / 2);
  const text = L.lines === 2 ? title.join("<br>") : title.join(" ");
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:${L.w}px;height:${L.h}px;overflow:hidden}
  .slide{position:relative;width:${L.w}px;height:${L.h}px}
  .bg{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
  .title{position:absolute;top:${L.titleTop}px;left:60px;right:60px;text-align:center;
    font-family:${SERIF};font-weight:700;font-size:${L.fontSize}px;line-height:1.08;color:${COLORS.title};letter-spacing:-.5px}
  .frame{position:absolute;left:${left}px;top:${frameTop}px;width:${L.frameW + 2 * L.border}px;
    border:${L.border}px solid ${COLORS.frame};background:#000;box-shadow:0 40px 90px rgba(59,36,23,.28)}
  .frame img{display:block;width:100%;height:auto}
  </style></head><body><div class="slide">
    <img class="bg" src="data:image/png;base64,${b64(BG)}">
    <div class="title">${text}</div>
    <div class="frame"><img src="data:image/png;base64,${rawB64}"></div>
  </div></body></html>`;
}

async function shoot(html, w, h, out, tmp, name) {
  const htmlPath = join(tmp, name + ".html");
  const rawPng = join(tmp, name + "-raw.png");
  writeFileSync(htmlPath, html);
  const child = spawn(CHROME, [
    "--headless", "--disable-gpu", "--no-sandbox", "--hide-scrollbars", "--no-first-run",
    "--no-default-browser-check", `--user-data-dir=${join(tmp, "profile-" + name)}`,
    "--force-device-scale-factor=1", `--window-size=${w},${h}`, `--screenshot=${rawPng}`, `file://${htmlPath}`,
  ], { stdio: "ignore" });
  const deadline = Date.now() + 90000;
  let ok = false;
  while (Date.now() < deadline) {
    await sleep(500);
    if (existsSync(rawPng)) {
      const a = statSync(rawPng).size;
      await sleep(700);
      if (statSync(rawPng).size === a && a > 1000) { ok = true; break; }
    }
  }
  try { child.kill("SIGKILL"); } catch {}
  if (!ok) throw new Error("Chrome görüntü üretemedi: " + name);
  // App Store alpha kanalı kabul etmez.
  execSync(`magick "${rawPng}" -background white -alpha remove -alpha off "${out}"`);
  const dims = execSync(`sips -g pixelWidth -g pixelHeight "${out}"`).toString().match(/\d+/g).slice(-2).join("x");
  console.log(`✓ ${out.replace(ROOT + "/", "")}  ${dims}`);
}

if (!existsSync(CHROME)) { console.error("Chrome bulunamadı"); process.exit(1); }
const tmp = mkdtempSync(join(tmpdir(), "bc-duo-"));
mkdirSync(OUT, { recursive: true });

for (const [prefix, L] of Object.entries(LAYOUTS)) {
  for (const s of SCREENS) {
    const src = join(RAW, `${prefix}-${s.key}.png`);
    const [rw, rh] = execSync(`sips -g pixelWidth -g pixelHeight "${src}"`).toString().match(/\d+/g).slice(-2).map(Number);
    await shoot(slide(L, s.title, b64(src), rw, rh), L.w, L.h, join(OUT, `${prefix}-${s.key}.png`), tmp, `${prefix}-${s.key}`);
  }
}
console.log("\nTamamlandı →", OUT.replace(ROOT + "/", ""));
