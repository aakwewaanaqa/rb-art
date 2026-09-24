require_relative "../lib"
require_relative "../../../lib/rb_art"

CellSize = 250
WidthCount = 7
HeightCount = 3

RbArt::Canvas.new {
  width  CellSize * WidthCount
  height CellSize * HeightCount
  svg    "out/post/20260923.svg"
  png8   "out/post/20260923.png"

  (0...WidthCount).to_a.each { |w|
    (0...HeightCount).to_a.each { |h|
      origin = RbArt::Geometry::Point.new(
        w * CellSize,
        h * CellSize
      )

      r = RbArt::Geometry::Point.new(
        CellSize.fdiv(2),
        CellSize
      ) + origin

      d = RbArt::Geometry::Point.new(
        0, -1
      )

      colors = RbArt::GrassColors.sample(4)
      style = {
        stroke: colors[0],
        fill:   colors[1],
        stroke_width: "4pt"
      }

      stem_length = (15..25).to_a.sample
      leaf_length = CellSize - stem_length - 10

      draw RbArt::Path.new {
        stroke colors[2]
        fill   colors[3]
        stroke_width "1"

        m origin
        l origin + RbArt::Geometry::Point.new(CellSize, 0)
        l origin + RbArt::Geometry::Point.new(CellSize, CellSize)
        l origin + RbArt::Geometry::Point.new(0, CellSize)
        l origin
        z
      }

      draw RbArt::HeartLeaf.new {
        style style

        root r
        direction d
        stem_length      stem_length
        leaf_length      leaf_length
        stem_width       7
        leaf_width       100
        leaf_end_pinch   (0.1..0.7).step(0.05)
        leaf_bottom_pull (0.5..0.75).step(0.05)
      }
    }
  }
}