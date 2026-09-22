require_relative "lib/styles"
require_relative "../../lib/rb_art"

HEIGHT = 2000
WIDTH = 2800
RADIUS = 80
AMPLITUDE = 24
WAVE_COUNT = 18
SAMPLES = 600

polygon = RbArt::Geometry::Polygon.new([
  RbArt::Geometry::Point.new(100, 100),
  RbArt::Geometry::Point.new(WIDTH - 100, 100),
  RbArt::Geometry::Point.new(WIDTH - 100, HEIGHT - 100),
  RbArt::Geometry::Point.new(100, HEIGHT - 100),
])

chain = polygon.rounded(radius: RADIUS)
total_length = chain.sum(&:arc_length)

# phase 是唯一會隨著時間變化的變數，sin(... + phase) 整體相位往前移，
# 視覺上就是波形沿著外框跑動。phase 從 0 跑到 2π 剛好繞回原本的樣子，
# 所以動畫最後一幀跟第一幀無縫銜接，可以做成循環 GIF。
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

build_canvas = ->(phase) {
  RbArt::Canvas.new {
    width WIDTH
    height HEIGHT
    background "none"

    draw RbArt::Path.new {
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
}

RbArt::Animation.new {
  frames 48
  dir "out/wave_frames"
  gif "out/wave.gif"
  fps 24
}.render { |i, total|
  phase = i.fdiv(total) * Math::PI * 2
  build_canvas.(phase)
}.write_gif
