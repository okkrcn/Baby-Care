#!/usr/bin/env node
// App Store pazarlama görselleri üretici.
// Ham screenshot'ları (docs/screenshots/0X-*.png, 1320x2868) marka renginde
// arka plan + telefon çerçevesi + Türkçe başlık ile App Store görseline dönüştürür.
// Çıktı: docs/screenshots/appstore/0X-*.png  (1320x2868, alpha yok)
//
// Render: headless Chrome (pixel-perfect) -> ImageMagick flatten.
// Not: Chrome 149'un eski --headless modu --screenshot'ı doğru üretir ama
// process'i sonlandırmaz; --headless=new ise --screenshot ile takılır.
// Bu yüzden Chrome'u arka planda başlatıp çıktı dosyası oluşunca öldürüyoruz.
//
// Kullanım: node scripts/build-appstore-screenshots.mjs

import { spawn } from "node:child_process";
import { execSync } from "node:child_process";
import { readFileSync, writeFileSync, mkdtempSync, mkdirSync, existsSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");
const SRC = join(ROOT, "docs", "screenshots");
const OUT = join(SRC, "appstore");
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

const W = 1320;
const H = 2868;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Her ekran: kaynak dosya, 2 satırlık başlık, alt destek metni.
const SCREENS = [
  { src: "01-dashboard.png",   t1: "Bebeğinin bakımı", t2: "tek ekranda",          sub: "Uyku, beslenme, bez ve aşı bir bakışta" },
  { src: "02-tracking.png",    t1: "Tek dokunuşla",    t2: "kaydet",               sub: "Beslenme, uyku ve bezi saniyeler içinde gir" },
  { src: "03-charts.png",      t1: "Haftalık",         t2: "grafiklerle takip",    sub: "7 günlük beslenme, bez ve uyku trendleri" },
  { src: "04-vaccination.png", t1: "Hiçbir aşıyı",     t2: "kaçırma",              sub: "Geciken ve yaklaşan aşılar için hatırlatma" },
  { src: "05-growth.png",      t1: "Gelişimi DSÖ",     t2: "persentiliyle izle",   sub: "Kilo, boy ve baş çevresi grafikleri" },
  { src: "06-baby.png",        t1: "Her şey",          t2: "parmaklarının ucunda", sub: "Gelişim rehberi, PDF rapor ve daha fazlası" },
];

function html(screen, b64) {
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:${W}px; height:${H}px; }
  .slide {
    position:relative; width:${W}px; height:${H}px; overflow:hidden;
    display:flex; flex-direction:column; align-items:center;
    padding:168px 92px 0;
    font-family:-apple-system,"SF Pro Display","Helvetica Neue",Helvetica,Arial,sans-serif;
    background:linear-gradient(180deg,#CFEDE5 0%,#B2E1D3 46%,#97D5C3 100%);
  }
  /* yumuşak dekoratif daireler */
  .blob { position:absolute; border-radius:50%; background:#ffffff; opacity:.16; filter:blur(2px); }
  .b1 { width:560px; height:560px; top:-150px; left:-180px; }
  .b2 { width:380px; height:380px; top:140px; right:-150px; opacity:.12; }
  .b3 { width:760px; height:760px; bottom:-340px; left:50%; transform:translateX(-50%); opacity:.10; }
  .title {
    position:relative; text-align:center; color:#0B332D;
    font-weight:800; font-size:108px; line-height:1.04; letter-spacing:-2px;
  }
  .sub {
    position:relative; text-align:center; color:#1C5A4E;
    font-weight:500; font-size:46px; line-height:1.3; letter-spacing:-.5px;
    margin-top:34px; max-width:1020px;
  }
  .frame {
    position:relative; margin-top:96px; width:940px;
    background:#0A0A0C; border-radius:108px; padding:14px;
    box-shadow:0 46px 100px rgba(8,46,40,.40), 0 8px 26px rgba(8,46,40,.22);
  }
  .screen { display:block; width:100%; border-radius:96px; overflow:hidden; }
  .screen img { display:block; width:100%; height:auto; }
  </style></head><body>
  <div class="slide">
    <div class="blob b1"></div><div class="blob b2"></div><div class="blob b3"></div>
    <div class="title">${screen.t1}<br>${screen.t2}</div>
    <div class="sub">${screen.sub}</div>
    <div class="frame"><div class="screen"><img src="data:image/png;base64,${b64}"></div></div>
  </div>
  </body></html>`;
}

// Chrome'u arka planda başlat, çıktı dosyası oluşup boyutu sabitlenince öldür.
async function shoot(htmlPath, rawPng, profile) {
  const args = [
    "--headless", "--disable-gpu", "--no-sandbox", "--hide-scrollbars",
    "--no-first-run", "--no-default-browser-check", `--user-data-dir=${profile}`,
    "--force-device-scale-factor=1", `--window-size=${W},${H}`,
    `--screenshot=${rawPng}`, `file://${htmlPath}`,
  ];
  const child = spawn(CHROME, args, { stdio: "ignore" });
  const deadline = Date.now() + 60000;
  let ok = false;
  while (Date.now() < deadline) {
    await sleep(400);
    if (existsSync(rawPng)) {
      const a = statSync(rawPng).size;
      await sleep(450);
      if (existsSync(rawPng) && statSync(rawPng).size === a && a > 1000) { ok = true; break; }
    }
  }
  try { child.kill("SIGKILL"); } catch {}
  await sleep(200);
  if (!ok) throw new Error("Chrome screenshot üretemedi: " + rawPng);
}

if (!existsSync(CHROME)) { console.error("Chrome bulunamadı:", CHROME); process.exit(1); }
mkdirSync(OUT, { recursive: true });
const tmp = mkdtempSync(join(tmpdir(), "appstore-"));

let i = 0;
for (const s of SCREENS) {
  i++;
  const srcPath = join(SRC, s.src);
  if (!existsSync(srcPath)) { console.error("Kaynak yok:", srcPath); process.exit(1); }
  const b64 = readFileSync(srcPath).toString("base64");
  const htmlPath = join(tmp, s.src.replace(".png", ".html"));
  writeFileSync(htmlPath, html(s, b64));

  const rawPng = join(tmp, "raw-" + s.src);
  const profile = join(tmp, "profile-" + i);
  await shoot(htmlPath, rawPng, profile);

  // App Store alpha kanalı istemez -> beyaza flatten, alpha kapat.
  const outPng = join(OUT, s.src);
  execSync(`magick "${rawPng}" -background white -alpha remove -alpha off "${outPng}"`, { stdio: "pipe" });

  const dims = execSync(`sips -g pixelWidth -g pixelHeight "${outPng}"`).toString().match(/\d+/g);
  console.log(`✓ ${s.src}  ${dims.slice(-2).join("x")}`);
}

console.log("\nTamamlandı →", OUT);
