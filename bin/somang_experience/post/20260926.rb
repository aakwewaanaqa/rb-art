require_relative "ref"
ref || exit(155)

Width          = 500
Height         = 500
VineGap        = 500.fdiv(3)
VineBumpGap    = 50
VineBump       = 10
VineWidth      = 10
SpatialSamples = 200
Frames         = 60

stem_length      = (5..10).step(1)
stem_width       = 7
leaf_length      = (40..60).step(1)
leaf_width       = (30..40).step(1)
leaf_end_pinch   = (0.1..0.7).step(0.05)
leaf_bottom_pull = (0.5..0.75).step(0.05)

Catmulls = []
Leaves   = []

(0..Width).step(VineGap).to_a.each { |x|
  points = (0..Height).step(VineBumpGap).to_a.each_with_index.map { |y, idx|
    y_is_odd = idx % 2 == 1

    RbArt::Geometry::Point.new(
      y_is_odd ? x + VineBump : x - VineBump,
      y
    )
  }

  chain = RbArt::Geometry::ArbitraryChain.new {
    items RbArt::Geometry::CubicBezier.catmull(
      points,
      tension: 0.6,
    )
  }

  # 依真實弧長均勻取樣，之後每一幀截斷的是這份點，成長速度才會平穩，
  # 不會因為 catmull 各段彎曲程度不同而忽快忽慢。
  spatial_points = (0..SpatialSamples).map { |i| chain.point_at_spatial_t(i.fdiv(SpatialSamples)) }

  vine_colors = RbArt::GrassColors.sample 2
  vine_style = {
    stroke:       vine_colors[0],
    fill:         vine_colors[1],
    stroke_width: "4pt"
  }

  Catmulls << {
    spatial_points: spatial_points,
    style:          vine_style
  }

  # 跟 20260925 同一套長葉子的方法：沿著中心線每隔 1/11 弧長長度取一個
  # spatial_t 當葉子的根，只是這裡額外記住 spatial_t，讓葉子可以在藤蔓
  # 生長到這個位置時才冒出來，而不是一開始就整株全部畫出來。
  # HeartLeaf.new 在這裡就先建好（範圍參數只在這裡抽樣一次），之後每一幀
  # 只是「要不要畫」的差別，形狀不會每幀重新亂數導致抖動。
  (0..1.0).step(1.fdiv(11)).to_a.each { |spatial_t|
    chain.item_at_spatial_t(spatial_t) { |bez, functional_t, idx|
      idx_is_odd = idx % 2 == 1
      r = bez.point_at functional_t
      d = idx_is_odd ?
        RbArt::Geometry::Point.new(+1, 1) :
        RbArt::Geometry::Point.new(-1, 1)

      leaf_colors = RbArt::GrassColors.sample(2)
      leaf_style  = {
        fill:         leaf_colors[0],
        stroke:       leaf_colors[1],
        stroke_width: "4pt"
      }

      leaf = RbArt::HeartLeaf.new {
        root             r
        direction        d
        leaf_length      leaf_length
        leaf_width       leaf_width
        leaf_end_pinch   leaf_end_pinch
        leaf_bottom_pull leaf_bottom_pull
        stem_length      stem_length
        stem_width       stem_width
        style            leaf_style
      }

      Leaves << {
        spatial_t: spatial_t,
        leaf:      leaf
      }
    }
  }
}

# growth: 0.0（還沒長）~ 1.0（長滿），取 spatial_points 的前綴再串成折線段，
# 丟給 StrokeExpand.outline 就能拿到「目前長度」的藤蔓外框（頭端是自然算出的 end_cap）。
def vine_outline_at(spatial_points, growth, width)
  n = (growth * (spatial_points.length - 1)).floor.clamp(1, spatial_points.length - 1)
  grown = spatial_points[0..n]
  segs = grown.each_cons(2).map { |a, b| RbArt::Geometry::CubicBezier.line(a, b) }
  RbArt::Geometry::StrokeExpand.outline(segs, width).first
end

return unless __FILE__ == $0

RbArt::Animation.new {
  frames Frames
  dir "out/post/20260926_frames"
  gif "out/post/20260926.gif"
  mp4 "out/post/20260926.mp4"
  fps 24
}.render { |i, total|
  growth = (i + 1).fdiv(total)

  RbArt::Canvas.new {
    width      Width
    height     Height
    background RbArt::BackgroundColor

    Catmulls.each { |vine|
      draw RbArt::Path.new {
        style vine[:style]

        vine_outline_at(vine[:spatial_points], growth, VineWidth).each_i_first_last { |point, idx, is_first, is_last|
          is_first ? m(point) : l(point)
        }
        z
      }
    }

    Leaves.each { |leaf|
      draw leaf[:leaf] if leaf[:spatial_t] <= growth
    }
  }
}
