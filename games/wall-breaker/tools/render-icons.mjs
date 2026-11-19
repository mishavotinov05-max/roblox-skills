// Рендер иконок в PNG 512×512 (прозрачный фон) + общий лист-превью.
// Запуск: node render-icons.mjs <папка node_modules со @fontsource>
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright');
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ICONS } from './icons.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const nm = process.argv[2];
const out = path.resolve(here, '../art/icons');
fs.mkdirSync(out, { recursive: true });

const font = (f) => fs.readFileSync(path.join(nm, f)).toString('base64');
const css = `
@font-face{font-family:'Russo One';src:url(data:font/woff2;base64,${font('@fontsource/russo-one/files/russo-one-cyrillic-400-normal.woff2')}) format('woff2');unicode-range:U+0400-04FF;}
@font-face{font-family:'Russo One';src:url(data:font/woff2;base64,${font('@fontsource/russo-one/files/russo-one-latin-400-normal.woff2')}) format('woff2');}
body{margin:0;background:transparent}
.i{width:512px;height:512px;display:inline-block}
`;

const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 1 });

const html = ICONS.map((ic) => `<div class="i" id="${ic.name}"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="512" height="512">${ic.svg()}</svg></div>`).join('');
await page.setContent(`<style>${css}</style>${html}`);
await page.evaluate(() => document.fonts.ready);

for (const ic of ICONS) {
  await page.locator('#' + ic.name).screenshot({ path: path.join(out, ic.name + '.png'), omitBackground: true });
}

// Лист-превью всех иконок
const groups = [['hud', 'Главные кнопки (слева 2×2) и колесо'], ['bar', 'Нижний ряд кнопок'], ['tile', 'Прочие кнопки'], ['stat', 'Показатели'], ['pass', 'Геймпассы (донат)'], ['pick', 'Кирки'], ['ore', 'Руды'], ['egg', 'Яйца']];
const sheet = groups.map(([g, title]) => `<h2>${title}</h2><div class="row">` + ICONS.filter((i) => i.group === g).map((ic) =>
  `<figure><svg viewBox="0 0 256 256" width="128" height="128">${ic.svg()}</svg><figcaption>${ic.label}</figcaption></figure>`).join('') + '</div>').join('');
await page.setViewportSize({ width: 1400, height: 800 });
await page.setContent(`<style>${css}
  body{background:linear-gradient(160deg,#2b1a5e,#4b2a9e 60%,#6a3cc8);padding:28px 36px;font-family:'Russo One';color:#fff}
  h1{margin:0 0 4px;font-size:40px;color:#ffe14d;-webkit-text-stroke:2px #1a1033}
  h2{margin:18px 0 8px;font-size:24px;-webkit-text-stroke:1px #1a1033}
  .row{display:flex;flex-wrap:wrap;gap:12px}
  figure{margin:0;width:150px;text-align:center;background:rgba(255,255,255,.08);border-radius:18px;padding:10px 0}
  figcaption{font-size:15px;margin-top:4px}
</style><h1>Wall Breaking Simulator — иконки</h1>${sheet}`);
await page.evaluate(() => document.fonts.ready);
await page.screenshot({ path: path.resolve(here, '../art/icons_sheet.png'), fullPage: true });
await browser.close();
console.log('icons:', ICONS.length);
