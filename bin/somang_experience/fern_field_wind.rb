require_relative "lib/fern"
require_relative "lib/styles"
require_relative "../../lib/rb_art"

HEIGHT = 2000
WIDTH = 2800

roots = RbArt::Geometry::PoissonDisc.sample(width: WIDTH, height: HEIGHT, radius: 100)

# 顏色由深到淺排序（用 HSV 的 v 明度判斷深淺）：
# depth_rank 0 = 最深（當背景，最先畫），
# 最後一個 = 最淺（當前景焦點，最後畫、蓋在最上面）。
depth_ordered_styles = RbArt::GrassStyles.sort_by { |fs| fs[:fill].v }

# 數量權重用半常態分布遞減：以最深色（index 0）為中心，
# sigma 越小衰減越快（深色越壓倒性地多），越大越接近線性遞減。
n = roots.size
sigma = 1.2
weights = depth_ordered_styles.each_index.map { |i| Math.exp(-(i.to_f**2) / (2 * sigma**2)) }
total_weight = weights.sum
counts = weights.map { |w| (n * w / total_weight.to_f).round }
counts[0] += n - counts.sum

color_pool = depth_ordered_styles.each_with_index.flat_map { |fs, i| [fs] * counts[i] }
color_pool.shuffle!

assigned = roots.zip(color_pool).map { |root, fs|
  { root: root, fs: fs, depth_rank: depth_ordered_styles.index(fs) }
}
draw_order = assigned.sort_by { |a| [a[:depth_rank], a[:root].y] }

# 每株的 Fern 物件只建立一次，seed 固定住骨架（控制點、分段數），
# 動畫階段每幀呼叫同一個物件的 to_svg(wind: ...)，形狀骨架不會變，
# 只有 wind 對控制點的偏移量不同。
ferns = draw_order.map { |a|
  root = a[:root]
  fs = a[:fs]
  depth = root.y / HEIGHT.to_f
  scale = 0.85 + 0.65 * depth

  angle = (Random.rand - 0.5) * (Math::PI * 0.3)
  direction = RbArt::Geometry::Point.new(0, -1).rotate(angle)

  style = { fill: fs[:fill], stroke: fs[:stroke], stroke_width: "1", weight: fs[:weight] }

  fern = RbArt::Fern.new {
    root root
    direction direction
    length (240 + Random.rand * 120) * scale
    base 2
    growth 1.2 + Random.rand * 0.3
    pointiness (0.6..1.0).step(0.1).to_a.sample
    heartiness (0.6..1.0).step(0.1).to_a.sample
    bend (180 + Random.rand * 240) * scale
    styles [style]
    seed Random.rand(1_000_000_000)
  }

  { fern: fern, scale: scale }
}

# 3D Perlin noise：x 軸是空間（root.x，讓鄰近植株的風向互相關聯，不會各自
# 亂擺），另外兩軸拿 cos(t)*R, sin(t)*R 繞成一個圓——t: 0..2π 走一圈時這兩個
# 座標會回到起點，noise 值也就跟著無縫循環，不用 ping-pong 硬接。
perlin = RbArt::Geometry::Perlin.new(seed: 42)

WIND_SPATIAL_SCALE = 900.0 # 越大，noise 場在空間上越平緩（鄰近植株擺動越同步）
WIND_TIME_RADIUS = 1.0     # 圓的半徑，越大風力隨時間變化的幅度越大
WIND_AMPLITUDE = 46.0      # 頂端（height_ratio=1）最大位移（px）

build_canvas = ->(t) {
  cx = Math.cos(t) * WIND_TIME_RADIUS
  cy = Math.sin(t) * WIND_TIME_RADIUS

  RbArt::Canvas.new {
    width WIDTH
    height HEIGHT
    background RbArt::BackgroundColor

    ferns.each { |f|
      wind = ->(point, height_ratio) {
        nx = perlin.noise3(point.x / WIND_SPATIAL_SCALE, cx, cy)
        ny = perlin.noise3(point.x / WIND_SPATIAL_SCALE + 37.2, cx, cy)
        RbArt::Geometry::Point.new(nx, ny * 0.3) * (WIND_AMPLITUDE * f[:scale] * height_ratio)
      }
      draw f[:fern].to_svg(wind: wind)
    }
  }
}

RbArt::Animation.new {
  frames 48
  scale 0.25
  dir "out/fern_wind_frames"
  gif "out/fern_wind.gif"
  fps 20
}.render { |i, total|
  t = i.fdiv(total) * Math::PI * 2
  build_canvas.(t)
}.write_gif
