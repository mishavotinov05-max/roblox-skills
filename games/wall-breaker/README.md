# Wall Breaking Simulator — материалы проекта

Это подготовительный этап. Пока у вас не установлен Roblox Studio, здесь лежат **иконки** для интерфейса и **3D-превью** (макет) того, как будет выглядеть карта.

## Что здесь лежит

```
art/
  icons/              ← 45 иконок PNG 512×512 с прозрачным фоном (готовы к загрузке в Roblox)
  icons_sheet.png     ← все иконки на одном листе
  preview/            ← скриншоты 3D-превью и видео wall_breaker_preview.mp4
tools/                ← исходники, из которых сгенерированы иконки и превью
```

### Иконки (`art/icons/`)

| Группа | Файлы |
|---|---|
| Кнопки интерфейса | `btn_shop`, `btn_pets`, `btn_auras`, `btn_rebirth` (квадрат 2×2), `btn_wheel` (колесо удачи), `btn_daily`, `btn_settings`, `btn_inventory`, `btn_quests`, `btn_levels`, `btn_lobby`, `btn_back`, `btn_cart`, `btn_trade`, `btn_close`, `btn_lock`, `btn_donate` |
| Показатели | `stat_wins` (победы), `stat_strength` (сила), `stat_luck` (удача) |
| Геймпассы | `pass_wins_x3`, `pass_strength_x2`, `pass_luck_x2`, `pass_auto_click` |
| Кирки (12 шт.) | `pick_01_wood` … `pick_12_rainbow` |
| Руды | `ore_coal`, `ore_iron`, `ore_gold`, `ore_emerald`, `ore_ruby` |
| Яйца | `egg_common`, `egg_rare`, `egg_epic`, `egg_legendary` |

**Как они попадут в игру.** Когда у вас будет Studio, откройте **View → Asset Manager → Bulk Import** и выберите все PNG из `art/icons/`. Roblox выдаст каждой картинке ID вида `rbxassetid://123…`. Эти ID мы впишем в один конфиг `IconConfig`, и кнопки возьмут их оттуда. Изображения проходят модерацию Roblox, обычно она занимает несколько минут.

### 3D-превью (`art/preview/`)

Это **не Roblox**, а макет в браузере (three.js), собранный по вашему ТЗ, чтобы вы могли заранее проверить планировку:

- вход в уровни стоит на центральной оси, яйца напротив него;
- магазин кирок на правой стене, в 3 ряда;
- ямы прокачки напротив магазина, торговец в углу, центральный проход свободный;
- 10 уровней идут по прямой, в каждом по 10 слоёв;
- между уровнями ниша с наградой (+1 / +3 победы) и кнопкой «В лобби».

В Roblox Studio карта будет собрана из обычных Part и Model с такими же размерами и расположением. Всё можно будет двигать инструментами Move, Scale и Rotate.

## Как пересобрать (для разработчика)

```bash
npm i three@0.160.0 @fontsource/russo-one@5.0.18      # в любой папке
node tools/render-icons.mjs   <путь к node_modules>
node tools/render-preview.mjs <путь к node_modules> all 24
```
