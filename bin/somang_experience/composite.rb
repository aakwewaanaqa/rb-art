require_relative "lib/fern"
require_relative "lib/styles"
require_relative "../../lib/rb_art"

WIDTH = 2800
HEIGHT = 2000
RADIUS = 80
AMPLITUDE = 24
WAVE_COUNT = 18
SAMPLES = 600

# --- 第 1 層：草叢（靜態）---
# Fern#to_svg 裡的隨機性是「每次呼叫都重擲」，不是在 initialize 就決定好，
# 所以這裡只呼叫一次 to_svg 把結果快取成字串，之後每一幀都重複貼上同一份，
# 不然動畫每一幀草的形狀都會重新亂長，變成閃爍雜訊。
fern_layer = RbArt::Geometry::PoissonDisc.sample(width: WIDTH, height: HEIGHT, radius: 100).sort_by(&:y).map { |root|
  depth = root.y / HEIGHT.to_f
  scale = 0.85 + 0.65 * depth
  angle = (Random.rand - 0.5) * (Math::PI * 0.3)
  direction = RbArt::Geometry::Point.new(0, -1).rotate(angle)

  styles = RbArt::GrassStyles.map { |fs|
    { fill: fs[:fill], stroke: fs[:stroke], stroke_width: "4pt", weight: fs[:weight] }
  }

  RbArt::Fern.new {
    root root
    direction direction
    length (240 + Random.rand * 120) * scale
    base 2
    growth 1.2 + Random.rand * 0.3
    pointiness (0.6..1.0).step(0.1).to_a.sample
    heartiness (0.6..1.0).step(0.1).to_a.sample
    bend (180 + Random.rand * 240) * scale
    styles styles
  }.to_svg
}.join("\n")

# --- 第 2 層：cry.svg（外部靜態插畫，viewBox 剛好是 2800x2000，可直接當巢狀 <svg> 貼進來）---
# Affinity 匯出 SVG 時完全不寫 mix-blend-mode，"효과"（效果／光暈）那幾層在原始檔裡
# 是 Screen 混合模式，匯出後只剩普通疊色的漸層形狀。這裡直接補回 mix-blend-mode:screen，
# 這樣即使之後從 Affinity 重新匯出覆蓋這份檔案，補丁邏輯還在，不用每次手動改 SVG。
cry_layer = File.read("out/cry.svg")
  .sub(/\A.*?(?=<svg)/m, "") # 去掉 <?xml ...?> 跟 <!DOCTYPE ...>，只留 <svg>...</svg>
  .gsub(/(<g id="효과:screen\d*"(?: serif:id="효과:screen")? transform="[^"]*")>/, '\1 style="mix-blend-mode:screen">')

# --- 第 3 層：波浪外框（動畫，只有這層每幀不同）---
polygon = RbArt::Geometry::Polygon.new([
  RbArt::Geometry::Point.new(100, 100),
  RbArt::Geometry::Point.new(WIDTH - 100, 100),
  RbArt::Geometry::Point.new(WIDTH - 100, HEIGHT - 100),
  RbArt::Geometry::Point.new(100, HEIGHT - 100),
])
chain = polygon.rounded(radius: RADIUS)
total_length = chain.sum(&:arc_length)

wave_points = ->(phase) {
  cum = 0.0
  chain.flat_map { |seg|
    seg_len = seg.arc_length
    seg_samples = [(SAMPLES * seg_len / total_length).round, 1].max

    pts = (0...seg_samples).map { |j|
      t = j / seg_samples.to_f
      base = seg.point_at(t)
      normal = seg.tangent_at(t).rotate(Math::PI / 2)
      progress = (cum + t * seg_len) / total_length
      offset = Math.sin(progress * WAVE_COUNT * Math::PI * 2 + phase) * AMPLITUDE
      base + normal * offset
    }
    cum += seg_len
    pts
  }
}

wave_layer = ->(phase) {
  RbArt::Path.new {
    m 0, 0
    l WIDTH, 0
    l WIDTH, HEIGHT
    l 0, HEIGHT
    z

    wave_points.(phase).each_i_first_last { |p, _idx, is_first, _is_last|
      is_first ? m(p) : l(p)
    }
    z

    fill RbArt::SkinPink
    stroke RbArt::SpiritBlue
    stroke_width "4pt"
    attr "fill-rule", "evenodd"
  }
}

# --- 疊圖順序：background -> 草叢 -> cry 插畫 -> 波浪外框（最上層，中間是透空的窗）---
build_canvas = ->(phase) {
  RbArt::Canvas.new {
    width WIDTH
    height HEIGHT
    background RbArt::BackgroundColor

    draw fern_layer
    draw cry_layer
    draw wave_layer.(phase)
  }
}

RbArt::Animation.new {
  frames 48
  dir "out/composite_frames"
  gif "out/composite.gif"
  fps 24
}.render { |i, total|
  phase = i.fdiv(total) * Math::PI * 2
  build_canvas.(phase)
}.write_gif
