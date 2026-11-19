// Рендер 3D-превью: скриншоты зон + видео-ролик.
// Запуск: node render-preview.mjs <node_modules с three и @fontsource> [stills|video|all] [fps]
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const { chromium } = createRequire('/opt/node-tools/')('playwright');

const here = path.dirname(fileURLToPath(import.meta.url));
const nm = process.argv[2];
const mode = process.argv[3] || 'all';
const fps = Number(process.argv[4] || 24);
const out = path.resolve(here, '../art/preview');
fs.mkdirSync(out, { recursive: true });

const files = {
  '/three.module.js': [path.join(nm, 'three/build/three.module.js'), 'text/javascript'],
  '/preview.html': [path.join(here, 'preview.html'), 'text/html'],
};
const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.on('console', (m) => { if (m.type() === 'error') console.log('console:', m.text()); });
page.on('pageerror', (e) => console.log('pageerror:', e.message));
await page.route('http://wb.local/**', (route) => {
  const p = new URL(route.request().url()).pathname;
  let f = files[p];
  if (!f && p.startsWith('/icons/')) f = [path.resolve(here, '../art/icons', path.basename(p)), 'image/png'];
  if (!f && p.startsWith('/fonts/')) f = [path.join(nm, '@fontsource/russo-one/files', path.basename(p)), 'font/woff2'];
  if (!f || !fs.existsSync(f[0])) return route.fulfill({ status: 404, body: 'nf' });
  route.fulfill({ status: 200, body: fs.readFileSync(f[0]), headers: { 'content-type': f[1], 'access-control-allow-origin': '*' } });
});
await page.goto('http://wb.local/preview.html');
await page.waitForFunction(() => window.__ready === true, null, { timeout: 120000 });

if (mode === 'stills' || mode === 'all') {
  const stills = ['hub', 'plan', 'hub_front', 'shop', 'pits', 'eggs', 'trader', 'level', 'reward', 'levels'];
  for (const [i, s] of stills.entries()) {
    await page.evaluate((s) => window.renderAt(0, s), s);
    await page.screenshot({ path: path.join(out, `${String(i + 1).padStart(2, '0')}_${s}.png`) });
    console.log('still', s);
  }
}
if (mode === 'hud' || mode === 'all') {
  // короткий ролик: камера стоит, анимируется только интерфейс
  const dir = path.join(process.env.FRAMES_DIR || '/tmp', 'wb_hud');
  fs.rmSync(dir, { recursive: true, force: true }); fs.mkdirSync(dir, { recursive: true });
  const n = 6 * fps;
  for (let i = 0; i < n; i++) {
    await page.evaluate((t) => window.renderAt(0, 'hub_front', t), i / fps);
    await page.screenshot({ path: path.join(dir, `f${String(i).padStart(4, '0')}.jpg`), type: 'jpeg', quality: 92 });
  }
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-framerate', String(fps), '-i', path.join(dir, 'f%04d.jpg'), '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '24', '-movflags', '+faststart', path.join(out, 'hud_animation.mp4')]);
  console.log('hud done');
}
if (mode === 'video' || mode === 'all') {
  const dir = path.join(process.env.FRAMES_DIR || '/tmp', 'wb_frames');
  fs.rmSync(dir, { recursive: true, force: true }); fs.mkdirSync(dir, { recursive: true });
  const dur = 28; const n = Math.round(dur * fps);
  for (let i = 0; i < n; i++) {
    await page.evaluate((t) => window.renderAt(t), i / fps);
    await page.screenshot({ path: path.join(dir, `f${String(i).padStart(4, '0')}.jpg`), type: 'jpeg', quality: 92 });
    if (i % 48 === 0) console.log('frame', i, '/', n);
  }
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-framerate', String(fps), '-i', path.join(dir, 'f%04d.jpg'), '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '21', '-movflags', '+faststart', path.join(out, 'wall_breaker_preview.mp4')]);
  console.log('video done');
}
await browser.close();
