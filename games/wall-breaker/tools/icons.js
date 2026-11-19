// Генератор иконок Wall Breaking Simulator.
// Каждая иконка — SVG 256×256. Рендерятся в PNG скриптом render-icons.mjs.
// Чтобы поменять цвет кнопки — поменяйте TILE-цвета внизу файла.

const OL = '#1a1033'; // цвет обводки
const SW = 10;        // толщина обводки

let gid = 0;
const uid = (p) => `${p}${++gid}`;

function grad(c1, c2, vertical = true) {
  const id = uid('g');
  const dir = vertical ? 'x1="0" y1="0" x2="0" y2="1"' : 'x1="0" y1="0" x2="1" y2="1"';
  return { id, def: `<linearGradient id="${id}" ${dir}><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${c2}"/></linearGradient>` };
}

// Фон-плитка для кнопок HUD
function tile(c1, c2) {
  const g = grad(c1, c2);
  return {
    defs: g.def,
    body: `<rect x="10" y="10" width="236" height="236" rx="54" fill="url(#${g.id})" stroke="${OL}" stroke-width="${SW}"/>
           <path d="M40 40 Q128 20 216 40 Q220 90 200 96 Q128 80 56 96 Q36 90 40 40Z" fill="#fff" opacity=".22"/>`,
  };
}

const shine = (x, y, rx, ry, rot = -30) =>
  `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" transform="rotate(${rot} ${x} ${y})" fill="#fff" opacity=".55"/>`;

// ---------- Символы ----------

function shop() {
  const stripes = [];
  const cols = ['#ff4d6d', '#fff', '#ff4d6d', '#fff', '#ff4d6d'];
  for (let i = 0; i < 5; i++) {
    const x = 44 + i * 33.6;
    stripes.push(`<path d="M${x} 62 h33.6 v46 a16.8 16.8 0 0 1 -33.6 0Z" fill="${cols[i]}" stroke="${OL}" stroke-width="7"/>`);
  }
  return `
    <rect x="58" y="100" width="140" height="104" rx="8" fill="#ffe7c2" stroke="${OL}" stroke-width="${SW}"/>
    <rect x="72" y="128" width="44" height="34" rx="6" fill="#7fd6ff" stroke="${OL}" stroke-width="7"/>
    <rect x="132" y="128" width="50" height="76" rx="6" fill="#8a5cff" stroke="${OL}" stroke-width="7"/>
    <circle cx="142" cy="168" r="5" fill="${OL}"/>
    <path d="M40 66 L60 40 H196 L216 66Z" fill="#ff8fa3" stroke="${OL}" stroke-width="8" stroke-linejoin="round"/>
    ${stripes.join('')}`;
}

function paw(fill = '#fff') {
  return `
    <path d="M128 132 C 92 132 62 168 66 196 C 70 222 100 214 128 210 C 156 214 186 222 190 196 C 194 168 164 132 128 132Z" fill="${fill}" stroke="${OL}" stroke-width="${SW}"/>
    <ellipse cx="70" cy="112" rx="22" ry="28" transform="rotate(-25 70 112)" fill="${fill}" stroke="${OL}" stroke-width="${SW}"/>
    <ellipse cx="106" cy="74" rx="22" ry="29" transform="rotate(-8 106 74)" fill="${fill}" stroke="${OL}" stroke-width="${SW}"/>
    <ellipse cx="150" cy="74" rx="22" ry="29" transform="rotate(8 150 74)" fill="${fill}" stroke="${OL}" stroke-width="${SW}"/>
    <ellipse cx="186" cy="112" rx="22" ry="28" transform="rotate(25 186 112)" fill="${fill}" stroke="${OL}" stroke-width="${SW}"/>`;
}

function flame() {
  const g = grad('#ffe14d', '#ff5a1f');
  return `<defs>${g.def}</defs>
    <path d="M128 228 C 70 228 46 186 54 146 C 60 116 82 100 88 70 C 108 86 112 104 110 118 C 120 92 134 62 128 28 C 172 52 204 104 204 152 C 204 196 176 228 128 228Z"
      fill="url(#${g.id})" stroke="${OL}" stroke-width="${SW}" stroke-linejoin="round"/>
    <path d="M128 216 C 98 216 86 194 92 172 C 96 158 108 150 112 134 C 122 146 124 156 122 166 C 134 152 142 138 140 118 C 162 136 170 158 168 178 C 166 202 150 216 128 216Z"
      fill="#fff6b0" stroke="${OL}" stroke-width="6" stroke-linejoin="round"/>`;
}

function rebirth() {
  // две дуговые стрелки
  const arc = (d) => `<path d="${d}" fill="none" stroke="${OL}" stroke-width="40" stroke-linecap="round"/>
                      <path d="${d}" fill="none" stroke="#fff" stroke-width="22" stroke-linecap="round"/>`;
  return `
    ${arc('M62 118 A 68 68 0 0 1 176 78')}
    ${arc('M194 138 A 68 68 0 0 1 80 178')}
    <path d="M150 50 L212 62 L184 118Z" fill="#fff" stroke="${OL}" stroke-width="9" stroke-linejoin="round"/>
    <path d="M106 206 L44 194 L72 138Z" fill="#fff" stroke="${OL}" stroke-width="9" stroke-linejoin="round"/>`;
}

function wheel() {
  const cols = ['#ff4d6d', '#ffd23f', '#3ddc84', '#3fa9ff', '#a65bff', '#ff8a3d', '#ff5fd2', '#33e0d0'];
  const cx = 128, cy = 136, r = 92;
  let s = '';
  for (let i = 0; i < 8; i++) {
    const a0 = (i / 8) * Math.PI * 2 - Math.PI / 2, a1 = ((i + 1) / 8) * Math.PI * 2 - Math.PI / 2;
    s += `<path d="M${cx} ${cy} L${cx + r * Math.cos(a0)} ${cy + r * Math.sin(a0)} A${r} ${r} 0 0 1 ${cx + r * Math.cos(a1)} ${cy + r * Math.sin(a1)}Z" fill="${cols[i]}" stroke="${OL}" stroke-width="5"/>`;
  }
  let dots = '';
  for (let i = 0; i < 16; i++) {
    const a = (i / 16) * Math.PI * 2;
    dots += `<circle cx="${cx + (r + 9) * Math.cos(a)}" cy="${cy + (r + 9) * Math.sin(a)}" r="4.5" fill="#fff6b0"/>`;
  }
  return `
    <circle cx="${cx}" cy="${cy}" r="${r + 18}" fill="#7a3cff" stroke="${OL}" stroke-width="${SW}"/>
    ${dots}${s}
    <circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="${OL}" stroke-width="7"/>
    <circle cx="${cx}" cy="${cy}" r="20" fill="#ffd23f" stroke="${OL}" stroke-width="8"/>
    <path d="M110 14 H146 L128 50Z" fill="#fff" stroke="${OL}" stroke-width="8" stroke-linejoin="round"/>`;
}

function gift() {
  return `
    <rect x="50" y="112" width="156" height="104" rx="10" fill="#ff4d6d" stroke="${OL}" stroke-width="${SW}"/>
    <rect x="38" y="82" width="180" height="40" rx="10" fill="#ff7b93" stroke="${OL}" stroke-width="${SW}"/>
    <rect x="112" y="82" width="32" height="134" fill="#ffd23f" stroke="${OL}" stroke-width="8"/>
    <path d="M128 82 C 100 40 60 46 70 72 C 76 86 110 84 128 82Z" fill="#ffd23f" stroke="${OL}" stroke-width="8" stroke-linejoin="round"/>
    <path d="M128 82 C 156 40 196 46 186 72 C 180 86 146 84 128 82Z" fill="#ffd23f" stroke="${OL}" stroke-width="8" stroke-linejoin="round"/>`;
}

function gear() {
  const cx = 128, cy = 128, n = 8, ro = 92, ri = 70;
  let d = '';
  for (let i = 0; i < n * 4; i++) {
    const a = (i / (n * 4)) * Math.PI * 2;
    const r = (i % 4 === 0 || i % 4 === 1) ? ro : ri;
    const aa = a + (i % 4 === 1 || i % 4 === 3 ? -0.05 : 0.05);
    d += `${i ? 'L' : 'M'}${cx + r * Math.cos(aa)} ${cy + r * Math.sin(aa)} `;
  }
  return `<path d="${d}Z" fill="#dfe6f5" stroke="${OL}" stroke-width="${SW}" stroke-linejoin="round"/>
          <circle cx="${cx}" cy="${cy}" r="30" fill="#7d8aa8" stroke="${OL}" stroke-width="${SW}"/>`;
}

// Кирка. head — цвет металла (2 цвета градиента), handle — цвет рукояти
function pickaxe(h1, h2, handle = '#a86a3c', glow = null) {
  const g = grad(h1, h2, false);
  const glowEl = glow ? `<circle cx="128" cy="128" r="104" fill="${glow}" opacity=".28"/>` : '';
  return `<defs>${g.def}</defs>${glowEl}
    <g transform="rotate(45 128 128)">
      <rect x="114" y="70" width="28" height="170" rx="12" fill="${handle}" stroke="${OL}" stroke-width="${SW}"/>
      <rect x="114" y="196" width="28" height="12" fill="${OL}" opacity=".35"/>
      <path d="M22 108 C 60 46 196 46 234 108 L 218 120 C 180 82 76 82 38 120Z"
        fill="url(#${g.id})" stroke="${OL}" stroke-width="${SW}" stroke-linejoin="round"/>
      <rect x="106" y="58" width="44" height="40" rx="8" fill="url(#${g.id})" stroke="${OL}" stroke-width="${SW}"/>
      <path d="M50 92 C 90 62 166 62 206 92" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".6"/>
    </g>`;
}

function crossedPickaxes() {
  return `<g transform="translate(-18 0)">${pickaxe('#e8f1ff', '#8ea3c7')}</g>
          <g transform="translate(274 0) scale(-1 1)">${pickaxe('#8af3ff', '#2f9bff')}</g>`;
}

function house() {
  return `
    <path d="M40 124 L128 46 L216 124" fill="none" stroke="${OL}" stroke-width="34" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M40 124 L128 46 L216 124" fill="none" stroke="#ff6b4a" stroke-width="18" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M66 120 L128 66 L190 120 V210 H66Z" fill="#fff3d6" stroke="${OL}" stroke-width="${SW}" stroke-linejoin="round"/>
    <rect x="108" y="150" width="40" height="60" rx="6" fill="#8a5cff" stroke="${OL}" stroke-width="7"/>`;
}

function backArrow() {
  return `<path d="M168 196 C 214 196 220 110 168 110 H 92" fill="none" stroke="${OL}" stroke-width="40" stroke-linecap="round"/>
          <path d="M168 196 C 214 196 220 110 168 110 H 92" fill="none" stroke="#fff" stroke-width="22" stroke-linecap="round"/>
          <path d="M108 60 L38 110 L108 160Z" fill="#fff" stroke="${OL}" stroke-width="10" stroke-linejoin="round"/>`;
}

function minecart() {
  return `
    <path d="M72 70 L96 50 L118 66 L140 44 L166 62 L184 70Z" fill="#ffd23f" stroke="${OL}" stroke-width="8" stroke-linejoin="round"/>
    <path d="M44 74 H212 L192 172 H64Z" fill="#8d97ad" stroke="${OL}" stroke-width="${SW}" stroke-linejoin="round"/>
    <rect x="44" y="70" width="168" height="20" rx="6" fill="#b7c0d3" stroke="${OL}" stroke-width="8"/>
    <path d="M86 108 H170 M92 140 H164" stroke="${OL}" stroke-width="7" stroke-linecap="round" opacity=".45"/>
    <circle cx="92" cy="186" r="24" fill="#55607a" stroke="${OL}" stroke-width="${SW}"/><circle cx="92" cy="186" r="8" fill="#d9deea"/>
    <circle cx="164" cy="186" r="24" fill="#55607a" stroke="${OL}" stroke-width="${SW}"/><circle cx="164" cy="186" r="8" fill="#d9deea"/>
    <path d="M20 222 H236" stroke="${OL}" stroke-width="10" stroke-linecap="round"/>`;
}

function merchant() {
  // тележка-магазин (торговец)
  return `
    <path d="M30 56 H66 L92 160 H196 L216 86 H76" fill="none" stroke="${OL}" stroke-width="30" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M30 56 H66 L92 160 H196 L216 86 H76" fill="none" stroke="#fff" stroke-width="14" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M86 92 H206 L192 148 H100Z" fill="#3ddc84" stroke="${OL}" stroke-width="8" stroke-linejoin="round"/>
    <circle cx="104" cy="204" r="18" fill="#fff" stroke="${OL}" stroke-width="${SW}"/>
    <circle cx="186" cy="204" r="18" fill="#fff" stroke="${OL}" stroke-width="${SW}"/>`;
}

function trophy(c1 = '#fff27a', c2 = '#ffae00') {
  const g = grad(c1, c2);
  return `<defs>${g.def}</defs>
    <path d="M70 62 C 20 62 22 140 84 140 M186 62 C 236 62 234 140 172 140" fill="none" stroke="${OL}" stroke-width="30" stroke-linecap="round"/>
    <path d="M70 62 C 20 62 22 140 84 140 M186 62 C 236 62 234 140 172 140" fill="none" stroke="${c2}" stroke-width="14" stroke-linecap="round"/>
    <path d="M62 38 H194 V92 C 194 140 162 164 128 164 C 94 164 62 140 62 92Z" fill="url(#${g.id})" stroke="${OL}" stroke-width="${SW}" stroke-linejoin="round"/>
    <rect x="110" y="160" width="36" height="30" fill="${c2}" stroke="${OL}" stroke-width="8"/>
    <rect x="72" y="186" width="112" height="36" rx="8" fill="#8a5cff" stroke="${OL}" stroke-width="${SW}"/>
    <path d="M88 52 V100" stroke="#fff" stroke-width="12" stroke-linecap="round" opacity=".6"/>
    <path d="M128 70 l9 18 20 3 -14 14 3 20 -18 -9 -18 9 3 -20 -14 -14 20 -3Z" fill="#fff" opacity=".85"/>`;
}

function bicep() {
  const g = grad('#ffe066', '#ffa21f');
  // все части сначала рисуются толстой обводкой, потом заливкой — получается единый силуэт
  const parts = [
    'M28 222 L28 178 C 28 152 50 140 84 140 L 176 146 L 214 196 C 206 220 186 226 160 226 Z',
    'M132 204 L 122 104 L 190 96 L 218 196 Z',
  ];
  const ell = '<ellipse cx="96" cy="146" rx="60" ry="46"/>';
  const fist = '<rect x="112" y="34" width="96" height="78" rx="28"/>';
  const shapes = (attrs) => `<g ${attrs}>${parts.map((d) => `<path d="${d}"/>`).join('')}${ell}${fist}</g>`;
  return `<defs>${g.def}</defs>
    ${shapes(`fill="${OL}" stroke="${OL}" stroke-width="${SW * 2}" stroke-linejoin="round"`)}
    ${shapes(`fill="url(#${g.id})"`)}
    <path d="M60 170 C 80 186 116 186 140 166" fill="none" stroke="${OL}" stroke-width="7" stroke-linecap="round" opacity=".7"/>
    <path d="M140 40 V70 M164 38 V70 M188 40 V70" stroke="${OL}" stroke-width="7" stroke-linecap="round" opacity=".7"/>
    <path d="M112 84 C 130 76 150 80 158 96" fill="none" stroke="${OL}" stroke-width="7" stroke-linecap="round" opacity=".7"/>
    <path d="M58 134 C 66 116 84 108 104 106" fill="none" stroke="#fff" stroke-width="10" stroke-linecap="round" opacity=".6"/>`;
}

function clover() {
  const leaf = `M128 128 C 84 118 74 66 102 58 C 116 54 128 66 128 78 C 128 66 140 54 154 58 C 182 66 172 118 128 128 Z`;
  let s = `<path d="M128 140 C 136 180 150 206 176 228" fill="none" stroke="${OL}" stroke-width="22" stroke-linecap="round"/>
           <path d="M128 140 C 136 180 150 206 176 228" fill="none" stroke="#2fbf5b" stroke-width="10" stroke-linecap="round"/>`;
  for (const r of [0, 90, 180, 270]) {
    s += `<path d="${leaf}" transform="rotate(${r} 128 128) translate(0 6)" fill="#3ddc84" stroke="${OL}" stroke-width="9" stroke-linejoin="round"/>`;
  }
  return s + `<circle cx="128" cy="128" r="10" fill="#1f9e4a"/>` + shine(98, 82, 10, 6);
}

function egg(c1, c2, spot, extra = '') {
  const g = grad(c1, c2);
  const spots = [[100, 90, 14], [150, 120, 18], [96, 160, 16], [150, 186, 12], [126, 60, 8]]
    .map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${spot}" stroke="${OL}" stroke-width="5"/>`).join('');
  const id = uid('c');
  return `<defs>${g.def}<clipPath id="${id}"><path d="M128 30 C 175 30 205 110 205 155 C 205 205 170 230 128 230 C 86 230 51 205 51 155 C 51 110 81 30 128 30 Z"/></clipPath></defs>
    ${extra}
    <path d="M128 30 C 175 30 205 110 205 155 C 205 205 170 230 128 230 C 86 230 51 205 51 155 C 51 110 81 30 128 30 Z" fill="url(#${g.id})"/>
    <g clip-path="url(#${id})">${spots}</g>
    <path d="M128 30 C 175 30 205 110 205 155 C 205 205 170 230 128 230 C 86 230 51 205 51 155 C 51 110 81 30 128 30 Z" fill="none" stroke="${OL}" stroke-width="${SW}"/>
    ${shine(96, 84, 14, 26, 20)}`;
}

const sparkles = (col) => [[40, 50, 14], [214, 70, 10], [206, 210, 12], [46, 196, 9]]
  .map(([x, y, r]) => `<path d="M${x} ${y - r * 2} Q${x} ${y} ${x + r * 2} ${y} Q${x} ${y} ${x} ${y + r * 2} Q${x} ${y} ${x - r * 2} ${y} Q${x} ${y} ${x} ${y - r * 2}Z" fill="${col}" stroke="${OL}" stroke-width="4"/>`).join('');

// Кусок породы с вкраплениями
function oreRock(rock1, rock2, nug1, nug2) {
  const g = grad(rock1, rock2);
  const n = grad(nug1, nug2);
  const nugs = [[96, 104, 18], [154, 92, 14], [140, 150, 20], [88, 168, 12], [182, 140, 10]]
    .map(([x, y, r]) => `<path d="M${x - r} ${y} L${x - r / 3} ${y - r} L${x + r} ${y - r / 2} L${x + r / 1.5} ${y + r / 1.3} L${x - r / 2} ${y + r}Z" fill="url(#${n.id})" stroke="${OL}" stroke-width="5" stroke-linejoin="round"/>`).join('');
  return `<defs>${g.def}${n.def}</defs>
    <path d="M40 140 L62 70 L128 42 L198 64 L222 136 L190 206 L110 220 L52 196Z" fill="url(#${g.id})" stroke="${OL}" stroke-width="${SW}" stroke-linejoin="round"/>
    <path d="M62 70 L98 120 L128 42 M98 120 L52 196 M98 120 L190 206 M198 64 L170 118 L222 136" fill="none" stroke="${OL}" stroke-width="4" opacity=".25"/>
    ${nugs}`;
}

// Огранённый кристалл
function gem(c1, c2, c3) {
  return `
    <path d="M70 60 H186 L226 104 L128 222 L30 104Z" fill="${c2}" stroke="${OL}" stroke-width="${SW}" stroke-linejoin="round"/>
    <path d="M70 60 L96 104 H160 L186 60" fill="${c1}" stroke="${OL}" stroke-width="5" stroke-linejoin="round"/>
    <path d="M30 104 H96 L128 222Z" fill="${c1}" opacity=".9" stroke="${OL}" stroke-width="5" stroke-linejoin="round"/>
    <path d="M160 104 H226 L128 222Z" fill="${c3}" stroke="${OL}" stroke-width="5" stroke-linejoin="round"/>
    <path d="M96 104 L128 60 L160 104" fill="none" stroke="${OL}" stroke-width="5" stroke-linejoin="round"/>
    <path d="M70 60 H186 L226 104 L128 222 L30 104Z" fill="none" stroke="${OL}" stroke-width="${SW}" stroke-linejoin="round"/>
    ${shine(90, 82, 14, 7, -20)}`;
}

function textBadge(txt, col = '#fff', size = 64, y = 222) {
  return `<text x="128" y="${y}" text-anchor="middle" font-family="Russo One" font-size="${size}" fill="${col}"
    stroke="${OL}" stroke-width="12" paint-order="stroke" stroke-linejoin="round">${txt}</text>`;
}

function close() {
  return `<path d="M78 78 L178 178 M178 78 L78 178" stroke="${OL}" stroke-width="44" stroke-linecap="round"/>
          <path d="M78 78 L178 178 M178 78 L78 178" stroke="#fff" stroke-width="24" stroke-linecap="round"/>`;
}

function lock() {
  return `<path d="M84 116 V86 C 84 30 172 30 172 86 V116" fill="none" stroke="${OL}" stroke-width="34"/>
          <path d="M84 116 V86 C 84 30 172 30 172 86 V116" fill="none" stroke="#cfd6e6" stroke-width="16"/>
          <rect x="56" y="110" width="144" height="110" rx="18" fill="#ffd23f" stroke="${OL}" stroke-width="${SW}"/>
          <circle cx="128" cy="154" r="14" fill="${OL}"/><rect x="121" y="156" width="14" height="36" rx="6" fill="${OL}"/>`;
}

function inventory() {
  return `<rect x="50" y="76" width="156" height="140" rx="20" fill="#c77b3c" stroke="${OL}" stroke-width="${SW}"/>
          <path d="M96 76 V58 C 96 40 160 40 160 58 V76" fill="none" stroke="${OL}" stroke-width="12"/>
          <rect x="50" y="110" width="156" height="30" fill="#a65f2a" stroke="${OL}" stroke-width="8"/>
          <rect x="114" y="104" width="28" height="42" rx="6" fill="#ffd23f" stroke="${OL}" stroke-width="7"/>`;
}

function quest() {
  return `<rect x="58" y="34" width="140" height="190" rx="16" fill="#fff3d6" stroke="${OL}" stroke-width="${SW}"/>
          <rect x="96" y="24" width="64" height="28" rx="8" fill="#8a5cff" stroke="${OL}" stroke-width="8"/>
          <path d="M80 92 l12 12 22 -24 M80 146 l12 12 22 -24" fill="none" stroke="#2fbf5b" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M128 98 H178 M128 152 H178 M84 196 H178" stroke="${OL}" stroke-width="9" stroke-linecap="round" opacity=".55"/>`;
}

function portal() {
  return `<path d="M44 226 V110 C 44 50 212 50 212 110 V226Z" fill="#6b6f86" stroke="${OL}" stroke-width="${SW}" stroke-linejoin="round"/>
          <path d="M72 226 V118 C 72 76 184 76 184 118 V226Z" fill="#c14dff" stroke="${OL}" stroke-width="8"/>
          <path d="M92 226 V126 C 92 98 164 98 164 126 V226Z" fill="#ff9cf5" opacity=".75"/>
          <path d="M112 226 V136 C 112 120 144 120 144 136 V226Z" fill="#fff" opacity=".8"/>
          <path d="M44 118 H72 M184 118 H212 M44 170 H72 M184 170 H212" stroke="${OL}" stroke-width="5" opacity=".4"/>`;
}

function donate() {
  // кристалл-монета с плюсом (донат-магазин)
  return `<circle cx="128" cy="128" r="96" fill="#3ddc84" stroke="${OL}" stroke-width="${SW}"/>
          <circle cx="128" cy="128" r="72" fill="#7cf0a8" stroke="${OL}" stroke-width="7"/>
          <g transform="translate(128 132) scale(.52) translate(-128 -128)">${gem('#e6fff0', '#ffffff', '#c7f5d9')}</g>
          <circle cx="196" cy="62" r="30" fill="#ffd23f" stroke="${OL}" stroke-width="8"/>
          <path d="M196 46 V78 M180 62 H212" stroke="${OL}" stroke-width="9" stroke-linecap="round"/>`;
}

// ---------- Список иконок ----------
// group: hud — кнопки с фоном-плиткой; item — предметы без фона

const T = {
  shop: ['#ff7aa8', '#e8336d'], pets: ['#c79bff', '#7a3cff'], auras: ['#ff9f43', '#ff3d3d'],
  rebirth: ['#5ee7ff', '#1f7bff'], wheel: ['#ffe46b', '#ff9e1f'], daily: ['#ff9de0', '#d63cff'],
  settings: ['#b8c4dc', '#5f6c8a'], levels: ['#9d8cff', '#4b3bd6'], lobby: ['#7cf0a8', '#1fae5b'],
  cart: ['#ffd27a', '#e07b1f'], trade: ['#7ef0ce', '#1fae8f'], close: ['#ff7a7a', '#d62828'],
  inventory: ['#ffcf8a', '#d67b2a'], quests: ['#9be8ff', '#2c95e0'], lock: ['#bfc6d8', '#6b7590'],
  robux: ['#9ff2b8', '#22a85a'],
};

function withTile(name, sym, scale = 0.78) {
  const t = tile(...T[name]);
  return `<defs>${t.defs}</defs>${t.body}<g transform="translate(128 128) scale(${scale}) translate(-128 -128)">${sym}</g>`;
}

export const ICONS = [
  // --- Кнопки HUD (2×2 слева и верхние справа) ---
  { group: 'hud', name: 'btn_shop', label: 'Магазин', svg: () => withTile('shop', shop()) },
  { group: 'hud', name: 'btn_pets', label: 'Питомцы', svg: () => withTile('pets', paw()) },
  { group: 'hud', name: 'btn_auras', label: 'Ауры', svg: () => withTile('auras', flame()) },
  { group: 'hud', name: 'btn_rebirth', label: 'Перерождение', svg: () => withTile('rebirth', rebirth()) },
  { group: 'hud', name: 'btn_wheel', label: 'Колесо удачи', svg: () => withTile('wheel', wheel(), 0.82) },
  { group: 'hud', name: 'btn_daily', label: 'Ежедн. награды', svg: () => withTile('daily', gift()) },
  { group: 'hud', name: 'btn_settings', label: 'Настройки', svg: () => withTile('settings', gear()) },
  { group: 'hud', name: 'btn_inventory', label: 'Инвентарь', svg: () => withTile('inventory', inventory()) },
  { group: 'hud', name: 'btn_quests', label: 'Задания', svg: () => withTile('quests', quest()) },
  { group: 'hud', name: 'btn_levels', label: 'Уровни', svg: () => withTile('levels', crossedPickaxes(), 0.72) },
  { group: 'hud', name: 'btn_lobby', label: 'В лобби', svg: () => withTile('lobby', house()) },
  { group: 'hud', name: 'btn_back', label: 'Назад', svg: () => withTile('lobby', backArrow()) },
  { group: 'hud', name: 'btn_cart', label: 'Вагонетка', svg: () => withTile('cart', minecart()) },
  { group: 'hud', name: 'btn_trade', label: 'Торговец', svg: () => withTile('trade', merchant()) },
  { group: 'hud', name: 'btn_close', label: 'Закрыть', svg: () => withTile('close', close(), 0.7) },
  { group: 'hud', name: 'btn_lock', label: 'Закрыто', svg: () => withTile('lock', lock()) },
  { group: 'hud', name: 'btn_donate', label: 'Донат', svg: () => withTile('robux', donate()) },

  // --- Статы (без фона, прозрачные) ---
  { group: 'stat', name: 'stat_wins', label: 'Победы', svg: () => trophy() },
  { group: 'stat', name: 'stat_strength', label: 'Сила', svg: () => bicep() },
  { group: 'stat', name: 'stat_luck', label: 'Удача', svg: () => clover() },

  // --- Геймпассы ---
  { group: 'pass', name: 'pass_wins_x3', label: '×3 Победы', svg: () => `<g transform="translate(0 -16)">${trophy()}</g>${textBadge('x3', '#ffe14d', 76, 236)}` },
  { group: 'pass', name: 'pass_strength_x2', label: '×2 Сила', svg: () => `<g transform="translate(0 -16)">${bicep()}</g>${textBadge('x2', '#ff8a3d', 76, 236)}` },
  { group: 'pass', name: 'pass_luck_x2', label: '×2 Удача', svg: () => `<g transform="translate(0 -16)">${clover()}</g>${textBadge('x2', '#3ddc84', 76, 236)}` },
  { group: 'pass', name: 'pass_auto_click', label: 'Автоклик', svg: () => `<g transform="translate(0 -12) scale(.9) translate(14 0)">${pickaxe('#8af3ff', '#2f9bff')}</g>${textBadge('AUTO', '#5ee7ff', 54, 232)}` },

  // --- Руды ---
  { group: 'ore', name: 'ore_coal', label: 'Уголь', svg: () => oreRock('#8d93a3', '#565b6b', '#3a3d48', '#111218') },
  { group: 'ore', name: 'ore_iron', label: 'Железо', svg: () => oreRock('#9aa1b2', '#5d6475', '#ffe2c8', '#d29a72') },
  { group: 'ore', name: 'ore_gold', label: 'Золото', svg: () => oreRock('#9aa1b2', '#5d6475', '#fff27a', '#ffae00') },
  { group: 'ore', name: 'ore_emerald', label: 'Изумруд', svg: () => gem('#8affb8', '#22c76a', '#11843f') },
  { group: 'ore', name: 'ore_ruby', label: 'Рубин', svg: () => gem('#ff9aa8', '#ef2b4a', '#a3122a') },

  // --- Яйца ---
  { group: 'egg', name: 'egg_common', label: 'Обычное', svg: () => egg('#f2f8ff', '#a9c8ff', '#5aa9ff') },
  { group: 'egg', name: 'egg_rare', label: 'Редкое', svg: () => egg('#fff27a', '#ff9e1f', '#ff6a00') },
  { group: 'egg', name: 'egg_epic', label: 'Эпическое', svg: () => egg('#f0a6ff', '#9a3cff', '#5d1fcc', sparkles('#ffd6ff')) },
  { group: 'egg', name: 'egg_legendary', label: 'Легендарное', svg: () => egg('#9effff', '#ff5fd2', '#ffe14d', sparkles('#fff6b0')) },
];

// Кирки: от дешёвой к дорогой (совпадает с PickaxeConfig)
const PICKS = [
  ['pick_01_wood', 'Деревянная', '#d9a066', '#8a5428', '#6b3f1d'],
  ['pick_02_stone', 'Каменная', '#c3c8d2', '#6f7684'],
  ['pick_03_copper', 'Медная', '#ffb27a', '#c2571f'],
  ['pick_04_iron', 'Железная', '#f1f4fa', '#9aa3b5'],
  ['pick_05_gold', 'Золотая', '#fff27a', '#ffae00'],
  ['pick_06_emerald', 'Изумрудная', '#8affb8', '#18a85a', null, '#3ddc84'],
  ['pick_07_ruby', 'Рубиновая', '#ff9aa8', '#d61f3e', null, '#ff4d6d'],
  ['pick_08_diamond', 'Алмазная', '#c8ffff', '#26b8f0', null, '#5ee7ff'],
  ['pick_09_obsidian', 'Обсидиановая', '#b07cff', '#2a1250', '#3b2a55', '#a65bff'],
  ['pick_10_netherite', 'Незеритовая', '#7a5b60', '#2b1e22', '#3b2a2e', '#ff5a1f'],
  ['pick_11_crystal', 'Кристальная', '#ffd6ff', '#ff5fd2', '#8a5cff', '#ff9cf5'],
  ['pick_12_rainbow', 'Радужная', '#ffe14d', '#ff3dd6', '#5ee7ff', '#fff'],
];
for (const [name, label, h1, h2, handle, glow] of PICKS) {
  ICONS.push({ group: 'pick', name, label, svg: () => pickaxe(h1, h2, handle || '#a86a3c', glow || null) });
}
