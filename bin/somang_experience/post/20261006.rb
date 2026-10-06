require_relative "ref"
ref

CellWidth  = 500
CellHeight = 500
StarRadius = 150
StarPointiness = 0.5
StartStrokeWidth = 15
StarStyle = {
  fill: RbArt::BananaYellow,
  stroke: RbArt::BananaYellowShade,
  stroke_linejoin: "round"
}

RbArt::Animation.new {
  frames 35
  dir "out/post/20261006"
  gif "out/post/20261006.gif"
  mp4 "out/post/20261006.mp4"
  fps 35
}.render { |i, total|
  t = Math.sin(i.fdiv(total) * RbArt::TwoPi).abs

  RbArt::Canvas.new {
    width      CellWidth * 2
    height     CellHeight * 2
    background RbArt::BackgroundColor

    (0...2).each { |x|
      (0...2).each { |y|
        cell_center = RbArt::Geometry::Point.new(
          (x + 0.5) * CellWidth,
          (y + 0.5) * CellHeight,
        )

        style = StarStyle
        style[:stroke_width] = "#{15 * t}pt"
        draw RbArt::StraightStar.new {
          style style
          center cell_center
          rotation 0
          radius StarRadius * t
          edge_count 4 + (x + y)
          pointiness StarPointiness
        }    
      }
    }
  }
}