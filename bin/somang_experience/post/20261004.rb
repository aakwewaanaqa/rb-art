require_relative "ref"
ref

CellSize     = 250
Column       = 7
Row          = 3
Radius       = 100

RbArt::Animation.new {
  frames 24
  fps 2
  dir "out/post/20261004_frames"
  gif "out/post/20261004.gif"
  mp4 "out/post/20261004.mp4"
}.render { |i, total|
  RbArt::Canvas.new {
    width      CellSize * Column
    height     CellSize * Row
    background RbArt::BackgroundColor

    (0..Column).to_a.each { |col|
      (0..Row).to_a.each { |row|
        colors = RbArt::GrassColors.sample 2
        style  = {
          fill: colors.first,
          stroke: colors.last,
          stroke_width: "4pt"
        }

        center = RbArt::Geometry::Point.new(
          (col + 0.5) * CellSize,
          (row + 0.5) * CellSize,
        )

        draw RbArt::Star.new {
          style      style
          center     center
          rotation   (0..Math::PI).step(0.01)
          radius     (70..120)
          pointiness (0.3..0.7).step(0.1)
          edge_count (3..7)
        }
      }
    }
  }
}