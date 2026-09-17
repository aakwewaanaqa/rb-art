# rb-art

用純 Ruby（不依賴任何 gem）產生 SVG 插畫素材。

## 結構

```
lib/rb_art/
  geometry.rb          # 向量 Point、Ellipse（含輪廓點、法線）等共用幾何工具
  canvas.rb             # 極簡 SVG 文件組裝器
  shapes/
    grass_clump.rb      # 草叢：橢圓分節外刺
bin/generate             # CLI，產生 out/grass.svg
out/                      # 產生的 SVG 輸出（已 gitignore）
```

## 使用

```sh
bin/generate                  # 隨機產生一張
bin/generate --seed 7         # 固定種子，可重現
bin/generate --out out/a.svg
```

## 目前的形狀

- **GrassClump**：橢圓輪廓分成 N 節，整叢是「單一連續外框」（`M ... C ... C ... Z`
  一次畫完，相鄰兩瓣共用同一個根部點），每節向外鼓出一片圓潤的瓣狀刺。根部的
  貝茲把手沿著同一個生長方向（朝尖端）延伸、兩端近乎平行，讓刺先鼓出去再收攏
  到尖端；尖端把手則共線且較長，維持切線連續同時讓尖端渾圓，整體看起來像花朵
  /雲朵的瓣狀輪廓，而不是尖銳的葉片或各瓣獨立疊起來的形狀。

新形狀依樣放進 `lib/rb_art/shapes/`，共用 `Geometry::Ellipse` / `Point`。
