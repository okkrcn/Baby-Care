#!/usr/bin/env node
// Ürün sayfası yerleşim görselleri: ayrı Header (21:9) ve Search Results (3:2).
// Universal (16:9) görsel iki yerleşimde de kırpıldığı için ana öğeler küçük kalıyordu;
// bu görseller her yerleşimin kendi güvenli alanına göre çizilir.
//
// Apple ölçüleri (Creative assets specifications, 2026-11):
//   Header          3840x1646, sanat güvenli alanı 1646x661 @ (1097,493)
//   Search Results  3840x2560, sanat güvenli alanı 2168x1030 @ (836,765)
// Alpha kanalı yok; metin yok (App Store ad ve ikonu kendisi gösterir).
//
// Girdi: docs/screenshots/v1.7/raw/ ve v1.6/raw/ (iPhone 17 Pro Max, 1320x2868)
// Çıktı: docs/screenshots/v1.7/creative/header-3840x1646.png
//        docs/screenshots/v1.7/creative/search-3840x2560.png
//
// Kullanım: node scripts/build-appstore-placements.mjs [--guides]
//   --guides  güvenli alanı kırmızı çerçeveyle çizer (yalnız kontrol için, yüklenmez)

import { spawn, execSync } from "node:child_process";
import { readFileSync, writeFileSync, mkdtempSync, mkdirSync, existsSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const SHOTS = join(ROOT, "docs", "screenshots");
const RAW17 = join(SHOTS, "v1.7", "raw");
const RAW16 = join(SHOTS, "v1.6", "raw");
const OUT = join(SHOTS, "v1.7", "creative");
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const GUIDES = process.argv.includes("--guides");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const b64 = (p) => readFileSync(p).toString("base64");
const CROP = JSON.parse(readFileSync(join(SHOTS, "v1.7", "crop.json"), "utf8"));
const FRAME = "#2A1F19";

function pageShell(w, h, body, css) {
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:${w}px;height:${h}px;overflow:hidden}
  .c{position:relative;width:${w}px;height:${h}px;overflow:hidden;
    background:radial-gradient(ellipse at 50% 42%,#FBF4EA 0%,#F3E6D4 55%,#E9D6BD 100%)}
  .blob{position:absolute;border-radius:50%;filter:blur(8px)}
  .dots{position:absolute;inset:0;background-image:radial-gradient(#C9AE8E 3px,transparent 3.5px);
    background-size:120px 120px;opacity:.16}
  .phone{position:absolute;border:solid ${FRAME};overflow:hidden;background:#000}
  .phone img{display:block;width:100%;height:auto}
  .soft{box-shadow:0 50px 110px rgba(59,36,23,.36)}
  .guide{position:absolute;border:6px dashed #E0115F;z-index:99}
  ${css}
  </style></head><body><div class="c">${body}</div></body></html>`;
}

// Telefon: ekran görüntüsü 1320x2868; çerçeve ve köşe genişliğe oranlı.
function phone(cls, src, w) {
  const border = Math.round(w * 0.021), radius = Math.round(w * 0.136);
  return `<div class="phone soft ${cls}" style="width:${w}px;border-width:${border}px;border-radius:${radius}px">
    <img src="data:image/png;base64,${src}"></div>`;
}

function guide(s) {
  return GUIDES ? `<div class="guide" style="left:${s.x}px;top:${s.y}px;width:${s.w}px;height:${s.h}px"></div>` : "";
}

// Header 21:9. Güvenli alan dar (661px yükseklik): Dynamic Island + widget ana sanat,
// iki yanda eğik telefonlar yardımcı alanda (dar ekranlarda kırpılabilir).
function header(img) {
  const W = 3840, H = 1646, s = { x: 1097, y: 493, w: 1646, h: 661 };
  const widgetW = 1100, widgetH = Math.round(widgetW * CROP.widget.h / CROP.widget.w);
  const islandW = 600, islandH = Math.round(islandW * CROP.island.h / CROP.island.w);
  const gap = 50;
  const top = s.y + Math.round((s.h - (islandH + gap + widgetH)) / 2);
  const cx = s.x + s.w / 2;
  return pageShell(W, H, `
    <div class="blob" style="width:1500px;height:1500px;left:-420px;top:-760px;background:#EFDCC4;opacity:.75"></div>
    <div class="blob" style="width:1300px;height:1300px;right:-360px;bottom:-760px;background:#E4CDB0;opacity:.7"></div>
    <div class="blob" style="width:760px;height:760px;left:820px;bottom:-470px;background:#CFEDE5;opacity:.55"></div>
    <div class="blob" style="width:700px;height:700px;right:900px;top:-460px;background:#D9EEE7;opacity:.5"></div>
    <div class="dots"></div>
    ${phone("l", img.lock, 600)}
    ${phone("r", img.teeth, 600)}
    <img class="island soft" src="data:image/png;base64,${img.island}">
    <img class="widget soft" src="data:image/png;base64,${img.widget}">
    ${guide(s)}`, `
    .l{left:${s.x - 860}px;top:250px;transform:rotate(-8deg)}
    .r{left:${s.x + s.w + 260}px;top:250px;transform:rotate(8deg)}
    .island{position:absolute;width:${islandW}px;left:${cx - islandW / 2}px;top:${top}px;border-radius:999px}
    .widget{position:absolute;width:${widgetW}px;left:${cx - widgetW / 2}px;top:${top + islandH + gap}px;border-radius:84px}`);
}

// Search Results 3:2. Aramada küçük görünür: az ve büyük öğe. Güvenli alanda kilit ekranı
// telefonu + Island + widget; yanlarda büyüme grafiği ve diş haritası yardımcı alanda.
function search(img) {
  const W = 3840, H = 2560, s = { x: 836, y: 765, w: 2168, h: 1030 };
  const phoneW = 470;                 // 470 genişlik → ~1021 yükseklik (çerçeve dahil ~1040)
  const widgetW = 1480, widgetH = Math.round(widgetW * CROP.widget.h / CROP.widget.w);
  const islandW = 860, islandH = Math.round(islandW * CROP.island.h / CROP.island.w);
  const groupW = phoneW + 120 + widgetW;
  const left = s.x + Math.round((s.w - groupW) / 2);
  const rightX = left + phoneW + 120;
  const stackH = islandH + 70 + widgetH;
  const stackTop = s.y + Math.round((s.h - stackH) / 2);
  return pageShell(W, H, `
    <div class="blob" style="width:1900px;height:1900px;left:-640px;top:-900px;background:#EFDCC4;opacity:.75"></div>
    <div class="blob" style="width:1600px;height:1600px;right:-500px;bottom:-800px;background:#E4CDB0;opacity:.7"></div>
    <div class="blob" style="width:900px;height:900px;left:700px;bottom:-520px;background:#CFEDE5;opacity:.55"></div>
    <div class="blob" style="width:820px;height:820px;right:880px;top:-420px;background:#D9EEE7;opacity:.5"></div>
    <div class="dots"></div>
    ${phone("al", img.growth, 560)}
    ${phone("ar", img.teeth, 560)}
    ${phone("main", img.lock, phoneW)}
    <img class="island soft" src="data:image/png;base64,${img.island}">
    <img class="widget soft" src="data:image/png;base64,${img.widget}">
    ${guide(s)}`, `
    .al{left:${s.x - 690}px;top:${s.y - 330}px;transform:rotate(-9deg);opacity:.97}
    .ar{left:${s.x + s.w + 150}px;top:${s.y - 120}px;transform:rotate(9deg);opacity:.97}
    .main{left:${left}px;top:${s.y + Math.round((s.h - 1040) / 2)}px}
    .island{position:absolute;width:${islandW}px;left:${rightX + (widgetW - islandW) / 2}px;top:${stackTop}px;border-radius:999px}
    .widget{position:absolute;width:${widgetW}px;left:${rightX}px;top:${stackTop + islandH + 70}px;border-radius:104px}`);
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

function crop(src, box, tmp, name) {
  const out = join(tmp, name + ".png");
  execSync(`magick "${src}" -crop ${box.w}x${box.h}+${box.x}+${box.y} +repage "${out}"`);
  return b64(out);
}

if (!existsSync(CHROME)) { console.error("Chrome bulunamadı"); process.exit(1); }
const tmp = mkdtempSync(join(tmpdir(), "bc-placements-"));
mkdirSync(OUT, { recursive: true });

const homeShot = join(RAW17, "02-ana-ekran.png");
const img = {
  lock: b64(join(RAW17, "01-kilit-ekrani.png")),
  teeth: b64(join(RAW17, "03-dis-gelisimi.png")),
  growth: b64(join(RAW16, "06-buyume.png")),
  island: crop(homeShot, CROP.island, tmp, "island"),
  widget: crop(homeShot, CROP.widget, tmp, "widget"),
};
const suffix = GUIDES ? "-guides" : "";
await shoot(header(img), 3840, 1646, join(GUIDES ? tmp : OUT, `header-3840x1646${suffix}.png`), tmp, "header");
await shoot(search(img), 3840, 2560, join(GUIDES ? tmp : OUT, `search-3840x2560${suffix}.png`), tmp, "search");
if (GUIDES) console.log("Kılavuzlu çıktılar:", tmp);
