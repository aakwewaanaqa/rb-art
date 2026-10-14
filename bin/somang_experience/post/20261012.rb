require_relative "ref"
ref

GenerateStyle = -> {
  colors = RbArt::GrassColors.sample 2
  {
    stroke: colors.first,
    fill: colors.second,
    stroke_width: "4pt"
  }
}
CanvasSize   = 1000
CanvasCenter = ([CanvasSize.fdiv(2)] * 2).to_point

LeafInterval = (80..200)
LeafRotation = [
  Math::PI.fdiv(32) * 8,
  Math::PI.fdiv(32) * 7,
  Math::PI.fdiv(32) * 6,
]

GrowDuration  = 3.0  # 藤蔓長完要幾秒
LeafBloomTime = 0.4  # 單片葉子展開要幾秒

# ease_in_out 的反函數：給「真實弧長比例」spatial_t，回「這段 cue 內部要
# 演到幾秒」才會長到那個比例。ease_in_out 是單調遞增的三次函數，沒有乾淨的
# closed form，用二分搜尋就好（跟 Polyline#sample 的取樣邏輯同一招）。
TemporalTimeAt = ->(spatial_t, duration) {
  lo, hi = 0.0, 1.0
  30.times do
    mid = lo.lerp(hi, 0.5)
    RbArt.ease_in_out(mid) < spatial_t ? (lo = mid) : (hi = mid)
  end
  lo.lerp(hi, 0.5) * duration
}

Vines = 2.times.map { |idx|
  rotation_offset = idx * Math::PI
  spiral = RbArt::Geometry::Spiral.new {
    center       CanvasCenter
    rotation     rotation_offset
    radius       0
    end_radius   CanvasSize.fdiv(2)
    end_rotation 5.to_rad * 2 + rotation_offset
  }
  polyline = RbArt::Geometry::Polyline.new {
    sample spiral, 5
  }
  style = GenerateStyle.()

  # 只存抽樣完的數值（不是 Leaf 物件）——葉子要在展開動畫期間逐格用不同
  # scale 重建，Leaf#scale 是用倍率相乘、每格呼叫會疊加變形，重建才不會
  # 一直疊乘出錯。
  leaf_specs = -> {
    specs = []
    len   = 0
    while len < polyline.length
      len += RbArt.unpack_param! LeafInterval
      specs << {
        at: len,
        rotation: LeafRotation.sample,
        sides: 2.times.map {
          {
            stem_length: RbArt.unpack_param!(15..17),
            stem_width:  3,
            leaf_length: RbArt.unpack_param!(60..90),
            leaf_width:  RbArt.unpack_param!(75..85),
            style:       GenerateStyle.(),
          }
        }
      }
    end
    specs
  }.()

  { spiral: spiral, polyline: polyline, leaf_specs: leaf_specs, style: style }
}

Timeline = RbArt::Timeline.new {
  fps 12

  grows = Vines.map { |vine|
    cue {
      duration GrowDuration
      layer    0
      cue { |t|
        spatial_t = RbArt.ease_in_out(t)
        len       = vine[:polyline].length * spatial_t
        points    = vine[:polyline].take(len)
        points    = [vine[:polyline].points.first, vine[:polyline].points.second] if points.nil? || points.length < 2
        outline_points = RbArt::Geometry::StrokeExpand.outline_polyline(points, 15).first

        RbArt::Path.new {
          style vine[:style]
          m outline_points.first
          outline_points[1..].each { |p| l p }
          z
        }
      }
    }
  }

  Vines.each_with_index { |vine, idx|
    grow_duration_for_vine = GrowDuration

    vine[:leaf_specs].each { |spec|
      spatial_t  = spec[:at].fdiv(vine[:polyline].length)
      start_time = TemporalTimeAt.(spatial_t, grow_duration_for_vine)

      cue {
        start    start_time
        duration LeafBloomTime
        layer    1
        cue { |t|
          scale        = RbArt.ease_in_out(t)
          functional_t = vine[:polyline].length_t_to_func_t(spec[:at])
          root         = vine[:spiral].point_at(functional_t)
          direction    = vine[:spiral].tangent_at(functional_t)

          [
            [spec[:sides][0], direction.rotate(-spec[:rotation])],
            [spec[:sides][1], direction.rotate(+spec[:rotation])],
          ].map { |attrs, leaf_direction|
            RbArt::Leaf.new {
              root        root
              direction   leaf_direction
              stem_length attrs[:stem_length] * scale
              stem_width  attrs[:stem_width]  * scale
              leaf_length attrs[:leaf_length] * scale
              leaf_width  attrs[:leaf_width]  * scale
              style       attrs[:style]
            }
          }
        }
      }
    }
  }
}

if __FILE__ == $0
RbArt::Animation.new {
  timeline Timeline
  canvas {
    width      CanvasSize
    height     CanvasSize
    background RbArt::BackgroundColor
  }
  dir "out/post/20261012"
  gif "out/post/20261012.gif"
  mp4 "out/post/20261012.mp4"
}.render
end
