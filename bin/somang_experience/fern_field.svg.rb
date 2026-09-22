require_relative "lib/fern"
require_relative "lib/styles"
require_relative "../../lib/rb_art"

RbArt::Canvas.new {
  HEIGHT = 2000
  WIDTH = 2800

  width WIDTH
  height HEIGHT
  background RbArt::BackgroundColor
  svg "out/fern_field.svg"

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
  counts[0] += n - counts.sum # 補足四捨五入造成的誤差

  color_pool = depth_ordered_styles.each_with_index.flat_map { |fs, i| [fs] * counts[i] }
  color_pool.shuffle!

  assigned = roots.zip(color_pool).map { |root, fs|
    { root: root, fs: fs, depth_rank: depth_ordered_styles.index(fs) }
  }

  # 先照顏色深淺分層（深色先畫在下面，淺色後畫蓋上去），
  # 同一層內再照 y 排序，讓近的自然蓋掉遠的。
  draw_order = assigned.sort_by { |a| [a[:depth_rank], a[:root].y] }

  draw_order.each { |a|
    root = a[:root]
    fs = a[:fs]
    depth = root.y / HEIGHT.to_f
    scale = 0.85 + 0.65 * depth

    angle = (Random.rand - 0.5) * (Math::PI * 0.3)
    direction = RbArt::Geometry::Point.new(0, -1).rotate(angle)

    style = {
      fill: fs[:fill],
      stroke: fs[:stroke],
      stroke_width: "4pt",
      weight: fs[:weight],
    }

    draw RbArt::Fern.new {
      root root
      direction direction
      length (240 + Random.rand * 120) * scale
      base 2
      growth 1.2 + Random.rand * 0.3
      pointiness (0.6..1.0).step(0.1).to_a.sample
      heartiness (0.6..1.0).step(0.1).to_a.sample
      bend (180 + Random.rand * 240) * scale
      styles [style]
    }
  }
}