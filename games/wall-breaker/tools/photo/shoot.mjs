// Делает «фото» игры из WallBreaker.rbxlx: node shoot.mjs <node_modules> <tree.json> <outDir>
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const { chromium } = createRequire('/opt/node-tools/')('playwright');

const here = path.dirname(fileURLToPath(import.meta.url));
const [NM, TREE, OUT] = process.argv.slice(2);
const ART = path.resolve(here, '../../art');
fs.mkdirSync(OUT, { recursive: true });

const ICON_LIST = ['ref_shop', 'ref_pets', 'ref_auras', 'ref_rebirth', 'ref_wheel', 'ref_settings', 'ref_quests', 'ref_rewards', 'ref_wins', 'ref_strength', 'ref_luck', 'ref_level_sword', 'ref_power_sword', 'layer_tile_shop', 'layer_sym_shop', 'layer_tile_pets', 'layer_sym_pets', 'layer_tile_auras', 'layer_sym_auras',
  'layer_tile_rebirth', 'layer_sym_rebirth', 'layer_wheel_base', 'layer_wheel_disc', 'layer_wheel_top', 'bar_settings', 'bar_daily',
  'bar_rewards', 'stat_wins', 'stat_strength', 'stat_luck', 'icon_sword', 'icon_sword_dark'];

// Как будто иконки уже загружены в Roblox и вставлены в IconConfig
const IMG = {
  'LeftMenu.ShopButton.Tile': 'ref_shop', 'LeftMenu.PetsButton.Tile': 'ref_pets',
  'LeftMenu.AurasButton.Tile': 'ref_auras', 'LeftMenu.RebirthButton.Tile': 'ref_rebirth',
  'TopRight.WheelButton.Disc': 'ref_wheel',
  'TopRight.SettingsButton.Icon': 'ref_settings', 'TopRight.QuestsButton.Icon': 'ref_quests', 'TopRight.RewardsButton.Icon': 'ref_rewards',
  'Stats.WinsRow.Icon': 'ref_wins', 'Stats.StrengthRow.Icon': 'ref_strength', 'Stats.LuckRow.Icon': 'ref_luck', 'Stats.RebirthRow.Icon': 'layer_sym_rebirth',
  'PowerPanel.LevelBar.Icon': 'ref_level_sword', 'PowerPanel.PowerStrikeButton.Icon': 'ref_power_sword',
};
const SHOW = {}, BG = {}, NOSTROKE = {};
for (const p of Object.keys(IMG)) {
  SHOW[p] = true;
  SHOW[p.replace(/\.(Tile|Symbol|Icon|Base|Disc|Top)$/, '.Fallback')] = false;
  if (p.endsWith('.Tile')) { const b = p.replace(/\.Tile$/, ''); BG[b] = 1; NOSTROKE[b] = true; }
}
SHOW['TopRight.RewardsButton.Badge'] = true;
for (const b of ['ShopButton', 'PetsButton', 'AurasButton', 'RebirthButton']) SHOW[`LeftMenu.${b}.Label`] = false;
for (const b of ['SettingsButton', 'QuestsButton', 'WheelButton', 'RewardsButton']) SHOW[`TopRight.${b}.Label`] = false;

const HUD_TEXT = {
  'Stats.WinsRow.Value': '7.45K', 'Stats.StrengthRow.Value': '360M', 'Stats.LuckRow.Value': '12.5%', 'Stats.RebirthRow.Value': '3',
  'PowerPanel.StrengthBig': '360M Сила', 'PowerPanel.LevelBar.Level': 'Уровень 272', 'PowerPanel.LevelBar.Xp': '3.82M / 4.99M',
  'PowerPanel.XpButtons.XpSmallButton': '+2.5M очков\nопыта', 'PowerPanel.XpButtons.XpMediumButton': '+15M очков\nопыта',
  'PowerPanel.XpButtons.XpBigButton': '+74.9M очков\nопыта', 'PowerPanel.PowerStrikeButton.Text': 'Мощный\nудар',
};
const hud = (extra = {}) => ({ fill: 0.77, ...extra, gui: true, images: IMG, show: { ...SHOW, ...(extra.show || {}) }, bgOverride: BG, noStroke: NOSTROKE,
  texts: { ...HUD_TEXT, ...(extra.texts || {}) }, mutate: extra.mutate || 'fillHub' });

const HD = 76;
const SHOTS = {
  '01_lobby_hud': { cam: [0, 9, 52], target: [0, 5, 10], avatar: [0, 40, Math.PI, 0x9ff8ff], ...hud() },
  '02_pits': { cam: [-6, 22, 40], target: [-40, -2, 4], fov: 62, avatar: [-20, 30, -Math.PI / 2, 0x9ff8ff] },
  '03_eggs': { cam: [22, 14, HD - 44], target: [22, 6, HD - 8], fov: 72 },
  '04_egg_preview': { cam: [54, 10, HD - 34], target: [56, 5, HD - 10], avatar: [57, HD - 23, 0, 0x9ff8ff],
    ...hud({ mutate: 'fillEggPreview', egg: 'chicken', show: { PowerPanel: false } }) },
  '05_egg_spin': { cam: [54, 10, HD - 34], target: [56, 5, HD - 10],
    ...hud({ mutate: 'fillRoulette', egg: 'chicken', offset: -300, show: { PowerPanel: false, LeftMenu: false, Stats: false, TopRight: false } }) },
  '06_egg_win': { cam: [54, 10, HD - 34], target: [56, 5, HD - 10],
    ...hud({ mutate: 'fillRoulette', egg: 'chicken', offset: -300, win: 'fox_cub', show: { PowerPanel: false, LeftMenu: false, Stats: false, TopRight: false } }) },
  '07_pickaxes': { cam: [14, 16, 30], target: [54, 6, -4], fov: 62 },
  '08_level_pads': { cam: [-2, 12, -HD - 4 - 50], target: [22, 2, -HD - 4 - 62], avatar: [8, -HD - 4 - 56, -2.2, 0x9ff8ff] },
  '09_overview': { cam: [-10, 165, 120], target: [-2, 0, -6], fov: 55 },
};

const files = { '/three.module.js': [path.join(NM, 'three/build/three.module.js'), 'text/javascript'], '/photo.html': [path.join(here, 'photo.html'), 'text/html'],
  '/tree.json': [TREE, 'application/json'] };
const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1350, height: 760 } });
page.on('pageerror', (e) => console.log('pageerror:', e.message));
page.on('console', (m) => { if (m.type() === 'error') console.log('console:', m.text()); });
await page.route('http://p.local/**', (route) => {
  const p = new URL(route.request().url()).pathname;
  let f = files[p];
  if (!f && p.startsWith('/icons/ref_')) f = [path.join(ART, 'icons_ref', path.basename(p)), 'image/png'];
  if (!f && p.startsWith('/icons/')) f = [path.join(ART, 'icons', path.basename(p)), 'image/png'];
  if (!f && p.startsWith('/textures/')) f = [path.join(ART, 'textures', path.basename(p)), 'image/png'];
  if (!f && p.startsWith('/fonts/')) f = [path.join(NM, '@fontsource/rubik/files', path.basename(p)), 'font/woff2'];
  if (!f || !fs.existsSync(f[0])) return route.fulfill({ status: 404, body: 'nf' });
  route.fulfill({ status: 200, body: fs.readFileSync(f[0]), headers: { 'content-type': f[1] } });
});
await page.goto('http://p.local/photo.html');
await page.evaluate((icons) => window.setup({ icons }), ICON_LIST);
await page.waitForFunction(() => window.__ready === true, null, { timeout: 180000 });
const only = process.env.ONLY ? process.env.ONLY.split(',') : null;
for (const [name, s] of Object.entries(SHOTS)) {
  if (only && !only.includes(name)) continue;
  await page.evaluate((s) => window.shot(s), s);
  await page.screenshot({ path: path.join(OUT, name + '.png') });
  console.log('shot', name);
}
await browser.close();
