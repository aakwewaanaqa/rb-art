require_relative "../lib/rb_art"
require_relative "../bin/somang_experience/lib/styles"
require_relative "../bin/somang_experience/lib/heart_leaf"

WIDTH = HEIGHT = 500
RbArt::Canvas.new {
  width  WIDTH
  height HEIGHT
  background RbArt::BackgroundColor
  svg "out/heart_leaf.t.svg"

  draw RbArt::HeartLeaf.new {
    colors = RbArt::GrassColors.sample 2
    style({
      stroke:       colors.first,
      fill:         colors.last,
      stroke_width: "4pt"
    })

    root RbArt::Geometry::Point.new(WIDTH * 0.5, HEIGHT * 0.75)
    direction RbArt::Geometry::Point.new(0, -1)
    stem_width  5.0
    stem_length 7.0
    leaf_width  WIDTH  * 0.2
    leaf_length HEIGHT * 0.25
  }
}