require_relative "../lib"
require_relative "../../../lib/rb_art"

Width  = 500
Height = 500

RbArt::Canvas.new {
  width      Width
  height     Height
  background RbArt::BackgroundColor
  svg        "out/post/20260924.svg"
  png8       "out/post/20260924.png"

  cx = Width.fdiv(2)
  cy = Height.fdiv(2)

  data = []
  (50..300).step(50).to_a.each { |radius|
    ellipse = RbArt::Geometry::Ellipse.new(
      cx: cx,
      cy: cy,
      rx: radius,
      ry: radius
    )

    leaf_width  = 50
    arc_length  = 2 * Math::PI * radius
    leaf_count  = arc_length / leaf_width

    (0...1).step(1.fdiv(leaf_count)).to_a.each { |t|
      colors = RbArt::GrassColors.sample(2)
      style  = {
        stroke: colors[0],
        fill: colors[1],
        stroke_width: "4pt"
      }

      t_jiggle = (0..0.01).step(0.001).to_a.sample
      t += t_jiggle
      r = ellipse.point_at(t * Math::PI * 2.0)

      d_jiggle = (-0.3..0.3).step(0.001).to_a.sample
      d = ellipse.normal_at(t * Math::PI * 2.0).rotate(d_jiggle)

      leaf_length = (70..150).step(10).to_a.sample
      stem_length = (10..15).step(1).to_a.sample
      stem_width  = 7

      data << {
        style:            style,
        root:             r,
        direction:        d,
        stem_length:      stem_length,
        stem_width:       stem_width,
        leaf_length:      leaf_length,
        leaf_width:       leaf_width,
        leaf_end_pinch:   (0.1..0.7).step(0.05),
        leaf_bottom_pull: (0.5..0.75).step(0.05)
      }
    }
  }
  
  data.scramble.each { |d|  
    draw RbArt::HeartLeaf.new {
      style            d[:style]
      root             d[:root]
      direction        d[:direction]
      stem_length      d[:stem_length]
      stem_width       d[:stem_width]
      leaf_length      d[:leaf_length]
      leaf_width       d[:leaf_width]
      leaf_end_pinch   d[:leaf_end_pinch]
      leaf_bottom_pull d[:leaf_bottom_pull]
    }
  }
}