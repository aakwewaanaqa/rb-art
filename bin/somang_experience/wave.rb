require_relative "lib/styles"
require_relative "../../lib/rb_art"

RbArt::Canvas.new {
  HEIGHT = 2000
  WIDTH = 2800

  width  WIDTH
  height HEIGHT
  background "none"
  svg "out/wave.svg"

  draw RbArt::Path.new {
    m 0,0
    l WIDTH,0
    l WIDTH,HEIGHT
    l 0,HEIGHT
    z

    polygon = RbArt::Geometry::Polygon.new([
      RbArt::Geometry::Point.new(100, 100),
      RbArt::Geometry::Point.new(WIDTH - 100, 100),
      RbArt::Geometry::Point.new(WIDTH - 100, HEIGHT - 100),
      RbArt::Geometry::Point.new(100, HEIGHT - 100),
    ])

    # 先把轉角磨圓，整條外框變成處處平滑的曲線鏈，這樣統一取樣時
    # 每一點的切線都連續，不用特別處理轉角。
    chain = polygon.rounded(radius: 80)
    total_length = chain.sum(&:arc_length)

    amplitude = 24
    wave_count = 18 # 整圈波的個數
    samples = 600

    cum = 0.0
    points = chain.flat_map { |seg|
      seg_len = seg.arc_length
      seg_samples = [(samples * seg_len / total_length).round, 1].max

      pts = (0...seg_samples).map { |j|
        t = j / seg_samples.to_f
        base = seg.point_at(t)
        normal = seg.tangent_at(t).rotate(Math::PI / 2)
        progress = (cum + t * seg_len) / total_length
        offset = Math.sin(progress * wave_count * Math::PI * 2) * amplitude
        base + normal * offset
      }
      cum += seg_len
      pts
    }

    points.each_i_first_last { |p, idx, is_first, is_last|
      if is_first
        m p
      else
        l p
      end
    }
    z

    fill RbArt::SkinPink
    stroke RbArt::SpiritBlue
    stroke_width "4pt"
    attr "fill-rule", "evenodd"
  }
}