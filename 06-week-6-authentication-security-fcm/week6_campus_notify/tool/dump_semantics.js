// Alat bantu kalibrasi koordinat: membuang accessibility tree Flutter web.
//
//   node tool/dump_semantics.js [langkah]
//
// Flutter web merender ke <canvas>, jadi koordinat tombol TIDAK bisa dibaca
// dari DOM biasa. Accessibility tree-nya hanya aktif setelah placeholder
// "Enable accessibility" diklik — skrip ini melakukannya, lalu mencetak setiap
// node beserta koordinat pusatnya.
//
// Keluarannya dipakai untuk mengisi konstanta koordinat pada
// `tool/screenshot_web.js`, sehingga tidak ada koordinat yang ditebak manual.

const puppeteer = require('puppeteer-core');
const path = require('path');
const fs = require('fs');

const CHROME =
  process.env.CHROME_EXECUTABLE ||
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe';
const APP_URL = process.env.APP_URL || 'http://127.0.0.1:8123/';
const PROFILE = process.env.PROFILE_DIR || path.join(__dirname, '.chrome-profile');

const VIEW = {
  width: 390,
  height: 780,
  deviceScaleFactor: 2,
  isMobile: true,
  hasTouch: true,
};

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

async function enableSemantics(page) {
  const clicked = await page.evaluate(() => {
    const placeholder = document.querySelector('flt-semantics-placeholder');
    if (!placeholder) return false;
    placeholder.click();
    return true;
  });
  await wait(1200);
  return clicked;
}

async function dump(page, label) {
  const nodes = await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics').forEach((el) => {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 && rect.height === 0) return;
      const text = (el.getAttribute('aria-label') || el.textContent || '').trim();
      if (!text) return;
      out.push({
        role: el.getAttribute('role') || '',
        text: text.replace(/\s+/g, ' ').slice(0, 70),
        x: Math.round(rect.x + rect.width / 2),
        y: Math.round(rect.y + rect.height / 2),
      });
    });
    // Text field Flutter web dirender sebagai <input> asli di DOM overlay,
    // bukan sebagai node flt-semantics — jadi perlu didata terpisah.
    document.querySelectorAll('input, textarea').forEach((el) => {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 && rect.height === 0) return;
      out.push({
        role: 'input',
        text: `value="${el.value}"`,
        x: Math.round(rect.x + rect.width / 2),
        y: Math.round(rect.y + rect.height / 2),
      });
    });
    return out;
  });

  console.log(`\n=== ${label} (${nodes.length} node) ===`);
  for (const n of nodes) {
    console.log(`  (${String(n.x).padStart(3)},${String(n.y).padStart(3)})  ${n.role.padEnd(10)} ${n.text}`);
  }
  return nodes;
}

async function tap(page, xy, settle = 700) {
  await page.mouse.click(xy[0], xy[1]);
  await wait(settle);
}

async function main() {
  const step = process.argv[2] || 'login';
  if (process.env.FRESH === '1') {
    fs.rmSync(PROFILE, { recursive: true, force: true });
  }

  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: true,
    userDataDir: PROFILE,
    defaultViewport: VIEW,
    args: [
      '--no-sandbox',
      '--disable-dev-shm-usage',
      '--hide-scrollbars',
      '--force-color-profile=srgb',
      '--enable-unsafe-swiftshader',
      '--window-size=390,780',
    ],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport(VIEW);
    page.on('pageerror', (e) => console.log('[pageerror]', e.message));

    await page.goto(APP_URL, { waitUntil: 'networkidle2', timeout: 240000 });
    await wait(7000);

    const enabled = await enableSemantics(page);
    console.log('semantics placeholder diklik:', enabled);
    await dump(page, step);

    const login = async () => {
      await tap(page, [195, 467], 2500);
    };

    if (step === 'home') {
      await login();
      await dump(page, 'home');
    }

    if (step === 'session') {
      await login();
      await tap(page, [195, 740], 1500);
      await dump(page, 'session');
    }

    if (step === 'push') {
      await login();
      await tap(page, [325, 740], 1500);
      await dump(page, 'push');
    }

    if (step === 'announcement') {
      await login();
      await tap(page, [195, 329], 2500);
      await dump(page, 'announcement');
    }

    if (step === 'logout_dialog') {
      await login();
      await tap(page, [370, 28], 1200);
      await dump(page, 'logout_dialog');
    }
  } finally {
    await browser.close();
  }
}

main().catch((e) => {
  console.error('FAILED:', e.message);
  process.exitCode = 1;
});
