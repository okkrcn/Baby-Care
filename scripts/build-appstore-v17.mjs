#!/usr/bin/env node
// 1.7 mağaza görselleri: yeni özellik ekran görüntüleri + arama/başlık (universal) görseli.
//
// Girdi: docs/screenshots/v1.7/raw/ (iPhone 17 Pro Max simülatörü, 1320x2868, durum çubuğu 09:41)
//   01-kilit-ekrani.png   kilit ekranı, emzirme Live Activity açık
//   02-ana-ekran.png      ana ekran, orta boy widget + Dynamic Island sayacı
//   03-dis-gelisimi.png   Diş Gelişimi ekranı
// Çıktı:
//   docs/screenshots/v1.7/appstore/0X-*.png   1320x2868, alpha yok (iPhone 6.9")
//   docs/screenshots/v1.7/creative/universal-5244x2950.png   başlık + arama sonuçları
//
// Görsel dil 1.6 setinden gelir: krem arka plan (v1.6/background-generated.png),
// koyu kahverengi serif başlık, ince koyu çerçeveli gerçek ekran görüntüsü.
// Uygulama pikselleri yeniden çizilmez; yalnız ölçeklenir ve kırpılır.
//
// Kullanım: node scripts/build-appstore-v17.mjs

import { spawn, execSync } from "node:child_process";
import { readFileSync, writeFileSync, mkdtempSync, mkdirSync, existsSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const V17 = join(ROOT, "docs", "screenshots", "v1.7");
const RAW = join(V17, "raw");
const BG = join(ROOT, "docs", "screenshots", "v1.6", "background-generated.png");
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const b64 = (p) => readFileSync(p).toString("base64");

// Kırpma kutuları ham görüntü pikselinde (1320x2868). Ana ekrandan yalnız
// Dynamic Island satırı ve Baby Care widget'ı alınır; diğer uygulamalar görünmez.
const CROP = JSON.parse(readFileSync(join(V17, "crop.json"), "utf8"));

const COLORS = { title: "#3B2417", sub: "#6B4A36", frame: "#2A1F19" };
const SERIF = `"Georgia","Iowan Old Style","Times New Roman",serif`;

function pageShell(w, h, body, extraCss = "") {
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:${w}px;height:${h}px;overflow:hidden}
  ${extraCss}
  </style></head><body>${body}</body></html>`;
}

// 1.6 ile aynı yerleşim: başlık üstte, ekran 148px kenar boşluğu ve 12px çerçeveyle.
function phoneSlide({ title, rawB64 }) {
  return pageShell(1320, 2868, `
  <div class="slide">
    <img class="bg" src="data:image/png;base64,${b64(BG)}">
    <div class="title">${title}</div>
    <div class="frame"><img src="data:image/png;base64,${rawB64}"></div>
  </div>`, `
  .slide{position:relative;width:1320px;height:2868px}
  .bg{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
  .title{position:absolute;top:104px;left:70px;right:70px;text-align:center;
    font-family:${SERIF};font-weight:700;font-size:92px;line-height:1.08;color:${COLORS.title};letter-spacing:-.5px}
  .frame{position:absolute;left:148px;top:587px;width:1024px;border:12px solid ${COLORS.frame};background:#000}
  .frame img{display:block;width:100%;height:auto}`);
}

// Widget slaytı: telefon çerçevesi yerine gerçek widget ve Dynamic Island kırpıntıları.
function widgetSlide({ title, sub, islandB64, widgetB64, islandW, widgetW }) {
  return pageShell(1320, 2868, `
  <div class="slide">
    <img class="bg" src="data:image/png;base64,${b64(BG)}">
    <div class="title">${title}</div>
    <div class="sub">${sub}</div>
    <img class="island" src="data:image/png;base64,${islandB64}">
    <img class="widget" src="data:image/png;base64,${widgetB64}">
    <div class="cap c1">Dynamic Island'da canlı sayaç</div>
    <div class="cap c2">Emzir, Uyut, Çiş, Kaka: tek dokunuş</div>
  </div>`, `
  .slide{position:relative;width:1320px;height:2868px}
  .bg{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
  .title{position:absolute;top:104px;left:70px;right:70px;text-align:center;
    font-family:${SERIF};font-weight:700;font-size:92px;line-height:1.08;color:${COLORS.title};letter-spacing:-.5px}
  .sub{position:absolute;top:330px;left:210px;right:210px;text-align:center;
    font-family:${SERIF};font-size:46px;line-height:1.3;color:${COLORS.sub}}
  .island{position:absolute;left:50%;transform:translateX(-50%);top:720px;width:${islandW}px;
    border-radius:999px;box-shadow:0 30px 70px rgba(59,36,23,.35)}
  .widget{position:absolute;left:50%;transform:translateX(-50%);top:1260px;width:${widgetW}px;
    border-radius:82px;box-shadow:0 40px 90px rgba(59,36,23,.38)}
  .cap{position:absolute;left:0;right:0;text-align:center;font-family:${SERIF};font-size:44px;color:${COLORS.sub}}
  .c1{top:1050px}.c2{top:2150px}`);
}

// Universal creative asset: 5244x2950, ana sanat güvenli alan (1402x962 @ 1921,660) içinde.
// Metin yok; App Store uygulama adını zaten gösterir. Arka plan kenarlara kadar uzar.
function universal({ lockB64, widgetB64, teethB64, islandB64 }) {
  const W = 5244, H = 2950;
  const safe = { x: 1921, y: 660, w: 1402, h: 962 };
  return pageShell(W, H, `
  <div class="c">
    <div class="blob b1"></div><div class="blob b2"></div><div class="blob b3"></div><div class="blob b4"></div>
    <div class="dots"></div>
    <div class="phone side"><img src="data:image/png;base64,${teethB64}"></div>
    <img class="island" src="data:image/png;base64,${islandB64}">
    <div class="phone main"><img src="data:image/png;base64,${lockB64}"></div>
    <img class="widget" src="data:image/png;base64,${widgetB64}">
  </div>`, `
  .c{position:relative;width:${W}px;height:${H}px;overflow:hidden;
    background:radial-gradient(ellipse at 50% 40%,#FBF4EA 0%,#F3E6D4 55%,#E9D6BD 100%)}
  .blob{position:absolute;border-radius:50%;filter:blur(8px)}
  .b1{width:1900px;height:1900px;left:-500px;top:-700px;background:#EFDCC4;opacity:.75}
  .b2{width:1500px;height:1500px;right:-380px;bottom:-640px;background:#E4CDB0;opacity:.7}
  .b3{width:900px;height:900px;left:900px;bottom:-420px;background:#CFEDE5;opacity:.55}
  .b4{width:800px;height:800px;right:1100px;top:-380px;background:#D9EEE7;opacity:.5}
  .dots{position:absolute;inset:0;background-image:radial-gradient(#C9AE8E 3px,transparent 3.5px);
    background-size:120px 120px;opacity:.18}
  /* Güvenli alan: ${safe.w}x${safe.h} @ ${safe.x},${safe.y}. Telefon + widget bu kutuda. */
  .phone{position:absolute;width:470px;
    border:10px solid ${COLORS.frame};border-radius:64px;overflow:hidden;background:#000;
    box-shadow:0 50px 110px rgba(59,36,23,.38)}
  .phone img{display:block;width:100%;height:auto}
  .main{left:${safe.x + 70}px;top:${safe.y - 10}px}
  /* Yardımcı sanat alanı: geniş kırpımlarda (başlık, arama) görünür, dar kırpımda kesilebilir. */
  .side{left:${safe.x - 700}px;top:${safe.y + 160}px;transform:rotate(-7deg);opacity:.96}
  .island{position:absolute;left:${safe.x + 1560}px;top:${safe.y + 120}px;width:820px;border-radius:999px;
    box-shadow:0 30px 70px rgba(59,36,23,.3)}
  .widget{position:absolute;left:${safe.x + 620}px;top:${safe.y + 300}px;width:720px;border-radius:58px;
    box-shadow:0 40px 90px rgba(59,36,23,.35)}`);
}

// Uygulama içi etkinlik görselleri: metinsiz (App Store etkinlik adını üstüne yazar).
// Kart 16:9 (1920x1080), detay 9:16 (1080x1920). Ana sanat ortada, alt üçte bir
// sakin bırakılır çünkü App Store metni oraya bindirir.
function eventCard({ lockB64, widgetB64 }) {
  return pageShell(1920, 1080, `
  <div class="c">
    <div class="blob b1"></div><div class="blob b2"></div><div class="blob b3"></div>
    <div class="phone"><img src="data:image/png;base64,${lockB64}"></div>
    <img class="widget" src="data:image/png;base64,${widgetB64}">
  </div>`, `
  .c{position:relative;width:1920px;height:1080px;overflow:hidden;
    background:radial-gradient(ellipse at 50% 35%,#FBF4EA 0%,#F3E6D4 60%,#E9D6BD 100%)}
  .blob{position:absolute;border-radius:50%;filter:blur(6px)}
  .b1{width:800px;height:800px;left:-260px;top:-300px;background:#EFDCC4;opacity:.8}
  .b2{width:700px;height:700px;right:-200px;bottom:-320px;background:#CFEDE5;opacity:.6}
  .b3{width:420px;height:420px;right:520px;top:-180px;background:#D9EEE7;opacity:.5}
  .phone{position:absolute;left:560px;top:70px;width:300px;border:8px solid ${COLORS.frame};border-radius:46px;
    overflow:hidden;background:#000;box-shadow:0 34px 80px rgba(59,36,23,.38)}
  .phone img{display:block;width:100%;height:auto}
  .widget{position:absolute;left:910px;top:200px;width:470px;border-radius:38px;box-shadow:0 26px 60px rgba(59,36,23,.33)}`);
}

function eventDetail({ teethB64, widgetB64, islandB64 }) {
  return pageShell(1080, 1920, `
  <div class="c">
    <div class="blob b1"></div><div class="blob b2"></div>
    <img class="island" src="data:image/png;base64,${islandB64}">
    <img class="widget" src="data:image/png;base64,${widgetB64}">
    <div class="phone"><img src="data:image/png;base64,${teethB64}"></div>
  </div>`, `
  .c{position:relative;width:1080px;height:1920px;overflow:hidden;
    background:radial-gradient(ellipse at 50% 30%,#FBF4EA 0%,#F3E6D4 60%,#E9D6BD 100%)}
  .blob{position:absolute;border-radius:50%;filter:blur(6px)}
  .b1{width:900px;height:900px;left:-380px;top:-300px;background:#EFDCC4;opacity:.8}
  .b2{width:800px;height:800px;right:-300px;bottom:-200px;background:#CFEDE5;opacity:.55}
  .island{position:absolute;left:50%;transform:translateX(-50%);top:150px;width:640px;border-radius:999px;
    box-shadow:0 22px 50px rgba(59,36,23,.3)}
  .widget{position:absolute;left:50%;transform:translateX(-50%);top:330px;width:820px;border-radius:58px;
    box-shadow:0 30px 70px rgba(59,36,23,.33)}
  .phone{position:absolute;left:50%;transform:translateX(-50%);top:780px;width:440px;border:10px solid ${COLORS.frame};
    border-radius:60px;overflow:hidden;background:#000;box-shadow:0 34px 80px rgba(59,36,23,.38);height:760px}
  .phone img{display:block;width:100%;height:auto}`);
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
const tmp = mkdtempSync(join(tmpdir(), "bc-v17-"));
const OUT = join(V17, "appstore");
const CREATIVE = join(V17, "creative");
mkdirSync(OUT, { recursive: true });
mkdirSync(CREATIVE, { recursive: true });

const lockRaw = join(RAW, "01-kilit-ekrani.png");
const homeRaw = join(RAW, "02-ana-ekran.png");
const teethRaw = join(RAW, "03-dis-gelisimi.png");

await shoot(phoneSlide({ title: "Sayaç kilit ekranında,<br>bir dokunuşla bitir", rawB64: b64(lockRaw) }),
  1320, 2868, join(OUT, "01-kilit-ekrani.png"), tmp, "s1");

const islandB64 = crop(homeRaw, CROP.island, tmp, "island");
const widgetB64 = crop(homeRaw, CROP.widget, tmp, "widget");
await shoot(widgetSlide({
  title: "Uygulamayı açmadan<br>kaydedin",
  sub: "Son beslenme, uyku ve bez değişimi ana ekranınızda",
  islandB64, widgetB64, islandW: 1100, widgetW: 1180,
}), 1320, 2868, join(OUT, "02-widget.png"), tmp, "s2");

await shoot(phoneSlide({ title: "Süt dişlerini<br>tek tek işaretleyin", rawB64: b64(teethRaw) }),
  1320, 2868, join(OUT, "03-dis-gelisimi.png"), tmp, "s3");

await shoot(universal({ lockB64: b64(lockRaw), widgetB64, teethB64: b64(teethRaw), islandB64 }), 5244, 2950,
  join(CREATIVE, "universal-5244x2950.png"), tmp, "universal");

const EVENT = join(V17, "event");
mkdirSync(EVENT, { recursive: true });
await shoot(eventCard({ lockB64: b64(lockRaw), widgetB64 }), 1920, 1080, join(EVENT, "event-card-1920x1080.png"), tmp, "evcard");
await shoot(eventDetail({ teethB64: b64(teethRaw), widgetB64, islandB64 }), 1080, 1920, join(EVENT, "event-detail-1080x1920.png"), tmp, "evdetail");

console.log("\nTamamlandı →", V17.replace(ROOT + "/", ""));
