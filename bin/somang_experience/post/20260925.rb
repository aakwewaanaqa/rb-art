require_relative "ref"
ref || exit(155)

Width       = 500
Height      = 500
VineGap     = 500.fdiv(3)
VineBumpGap = 50
VineBump    = 10
VineWidth   = 10

stem_length      = (5..10).step(1)
stem_width       = 7
leaf_length      = (40..60).step(1)
leaf_width       = (30..40).step(1)
leaf_end_pinch   = (0.1..0.7).step(0.05)
leaf_bottom_pull = (0.5..0.75).step(0.05)

RbArt::Canvas.new {
  width      Width
  height     Height
  background RbArt::BackgroundColor
  svg        "out/post/20260925.svg"
  png8       "out/post/20260925.png"

  leaves = []
  vines  = []
  (0..Width).step(VineGap).to_a.each { |x|
    points = (0..Height).step(VineBumpGap).to_a.each_with_index.map { |y, idx|
      y_is_odd = idx % 2 == 1

      RbArt::Geometry::Point.new(
        y_is_odd ? x + VineBump : x - VineBump,
        y
      )
    }

    vine = RbArt::Geometry::ArbitraryChain.new {
      items RbArt::Geometry::CubicBezier.catmull_rom_chain(
        points,
        tension: 0.6,
      )

      (0..1.0).step(1.fdiv(11)).to_a.each { |fraction|
        item_length_fraction_with_index(fraction) { |bez, t, idx|
          idx_is_odd = idx % 2 == 1
          r = bez.point_at t
          d = idx_is_odd ? 
            RbArt::Geometry::Point.new(+1, 1) :
            RbArt::Geometry::Point.new(-1, 1)

          colors = RbArt::GrassColors.sample(2)
          style  = {
            fill:         colors[0],
            stroke:       colors[1],
            stroke_width: "4pt"
          }

          leaves << {
            root:             r,
            direction:        d,
            leaf_length:      leaf_length,
            leaf_width:       leaf_width,
            leaf_end_pinch:   leaf_end_pinch,
            leaf_bottom_pull: leaf_bottom_pull,
            stem_length:      stem_length,
            stem_width:       stem_width,
            style:            style,
          }
        }
      }
    }

    vines << {
      points: RbArt::Geometry::StrokeExpand
        .outline(vine, VineWidth)
        .first,
      style: -> {
        colors = RbArt::GrassColors.sample(2)
        {
          fill:         colors[0],
          stroke:       colors[1],
          stroke_width: "4pt"
        }
      }.()
    }
  }

  vines.each { |vine|
    draw RbArt::Path.new {
      style vine[:style]

      vine[:points].each_i_first_last { |point, idx, is_first, is_last|
        if is_first then
          m point
        else
          l point
        end
      }
      z
    }
  }

  leaves.each { |leaf|
    draw RbArt::HeartLeaf.new {
      root             leaf[:root]
      direction        leaf[:direction]
      leaf_length      leaf[:leaf_length]
      leaf_width       leaf[:leaf_width]
      leaf_end_pinch   leaf[:leaf_end_pinch]
      leaf_bottom_pull leaf[:leaf_bottom_pull]
      stem_length      leaf[:stem_length]
      stem_width       leaf[:stem_width]
      style            leaf[:style]
    }
  }
}