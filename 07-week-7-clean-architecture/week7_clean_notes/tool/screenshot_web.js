// Pengambil screenshot aplikasi Flutter web pada viewport layout mobile.
//
// Dijalankan SATU langkah per pemanggilan supaya setiap proses Chrome ditutup
// sebelum langkah berikutnya ("satu-satu, tutup, lalu ganti screenshot
// berikutnya"). Profil Chrome dipakai ulang agar database SQLite (IndexedDB)
// dan preferensi (localStorage) bertahan antar langkah.
//
//   node tool/screenshot_web.js <output.png> <step>
//   FRESH=1 node tool/screenshot_web.js screenshots/03_list_dirty.png list_dirty
//
// Langkah: empty, add_dialog, list_dirty, detail, after_sync, settings,
//          settings_dark, posts, offline, offline_sync, reset
//
// Prasyarat:
//   flutter build web --release
//   node tool/serve_web.js build/web 8123        (terminal terpisah)
//
// Dependensi: puppeteer-core (devDependency, tidak masuk ke aplikasi)
//   npm install puppeteer-core
//
// Koordinat di bawah diambil dari accessibility tree Flutter web, bukan
// ditebak manual:
//   FAB "Catatan"   -> (315, 656)
//   Ikon sinkron    -> (370, 28)
//   Tab bar (y=740) -> Catatan (65), Posts (195), Pengaturan (325)

const puppeteer = require('puppeteer-core');
const path = require('path');
const fs = require('fs');

const CHROME =
  process.env.CHROME_EXECUTABLE ||
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe';
const APP_URL = process.env.APP_URL || 'http://127.0.0.1:8123/';
const PROFILE = process.env.PROFILE_DIR || path.join(__dirname, '.chrome-profile');

// Viewport layout mobile: rasio ponsel, DPR 2 -> berkas 780 x 1560 px.
const VIEW = {
  width: 390,
  height: 780,
  deviceScaleFactor: 2,
  isMobile: true,
  hasTouch: true,
};

const TAB = { catatan: [65, 740], posts: [195, 740], pengaturan: [325, 740] };
const FAB = [315, 656];
const SYNC = [370, 28];

const out = process.argv[2];
const step = process.argv[3];

if (!out || !step) {
  console.error('usage: node tool/screenshot_web.js <output.png> <step>');
  process.exit(2);
}

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

async function tap(page, xy, settle = 600) {
  await page.mouse.click(xy[0], xy[1]);
  await wait(settle);
}

async function fillNote(page, title, body) {
  await tap(page, FAB, 1500);
  await tap(page, [195, 325], 500); // field Judul (autofocus)
  await page.keyboard.type(title, { delay: 45 });
  await wait(200);
  await tap(page, [195, 425], 400); // field Isi
  await page.keyboard.type(body, { delay: 35 });
  await wait(200);
  await tap(page, [263, 519], 1600); // tombol Simpan
}

// Tiga catatan contoh yang dipakai langkah detail / after_sync / offline.
async function seedNotes(page) {
  await fillNote(page, 'Belanja mingguan', 'Beli sayur, buah, dan telur');
  await fillNote(page, 'Rencana refactor', 'Pisahkan domain, data, presentation');
  await fillNote(page, 'Catatan kuliah', 'Clean Architecture: dependensi mengarah ke dalam');
}

async function main() {
  if (step === 'reset') {
    fs.rmSync(PROFILE, { recursive: true, force: true });
    console.log('profile reset');
    return;
  }

  // FRESH=1 -> mulai dari database kosong sehingga tiap langkah deterministik
  // dan tidak menumpuk catatan dari langkah sebelumnya.
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
    page.on('console', (m) => {
      if (m.type() === 'error') {
        console.log('[console.error]', m.text());
      }
    });

    await page.goto(APP_URL, { waitUntil: 'networkidle2', timeout: 240000 });
    await wait(7000); // beri waktu Flutter + SQLite wasm siap

    switch (step) {
      case 'empty':
        break;

      case 'add_dialog':
        await tap(page, FAB, 1500);
        break;

      case 'list_dirty':
        await seedNotes(page);
        break;

      case 'detail':
        await seedNotes(page);
        await tap(page, [195, 119], 1800);
        break;

      case 'after_sync':
        await seedNotes(page);
        await tap(page, SYNC, 2600);
        break;

      case 'settings':
        await tap(page, TAB.pengaturan, 1200);
        break;

      case 'settings_dark':
        await tap(page, TAB.pengaturan, 1200);
        await tap(page, [360, 130], 1500);
        break;

      case 'posts':
        await tap(page, TAB.posts, 6000);
        break;

      case 'offline':
        await seedNotes(page);
        await tap(page, TAB.pengaturan, 1000);
        await tap(page, [360, 380], 800); // toggle Simulasi offline
        await tap(page, TAB.catatan, 1500);
        break;

      case 'offline_sync':
        await seedNotes(page);
        await tap(page, TAB.pengaturan, 1000);
        await tap(page, [360, 380], 800); // toggle Simulasi offline
        await tap(page, TAB.catatan, 1200);
        await tap(page, SYNC, 1200); // coba sinkron saat offline
        break;

      default:
        throw new Error('step tidak dikenal: ' + step);
    }

    // Pindahkan kursor agar tooltip hover tidak ikut terfoto.
    await page.mouse.move(195, 620);
    await wait(400);

    fs.mkdirSync(path.dirname(out), { recursive: true });
    await page.screenshot({ path: out });
    console.log('captured ' + out + ' (step=' + step + ')');
  } finally {
    await browser.close();
  }
}

main().catch((e) => {
  console.error('FAILED:', e.message);
  process.exit(1);
});
