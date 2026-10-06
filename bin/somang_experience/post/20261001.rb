require_relative "ref"
ref

CanvasWidth = 500
CanvasHeight = 500
Shrink = (0..1).step(0.1).to_a.sample
Filename = File.basename(__FILE__)

Step = 0.02
Fill = RbArt::GrassColors.sample

RbArt::Animation.new {
  frames(1.fdiv(Step).to_i)
  dir "out/post/#{Filename}_frames"
  gif "out/post/#{Filename}.gif"
  mp4 "out/post/#{Filename}.mp4"
  fps 6
}.render { |i, total|
  shrink = i.fdiv(total)

  RbArt::Canvas.new {
    width CanvasWidth
    height CanvasHeight
    background RbArt::BackgroundColor

    colors = RbArt::GrassColors.sample 2
    style = {
      stroke: colors[0],
      fill: Fill,
      stroke_width: "4pt"
    }

    draw RbArt::Path.new {
      style style

      center = RbArt::Geometry::Point.new(
        CanvasWidth.fdiv(2),
        CanvasHeight.fdiv(2)
      )

      corners = [
          RbArt::Geometry::Point.new(
            CanvasWidth.fdiv(2),
            0
        ),
          RbArt::Geometry::Point.new(
            CanvasWidth,
            CanvasHeight.fdiv(2)
        ),
          RbArt::Geometry::Point.new(
            CanvasWidth.fdiv(2),
            CanvasHeight
        ),
          RbArt::Geometry::Point.new(
            0,
            CanvasHeight.fdiv(2)
        ),
      ]

      m corners.first
      (0...corners.length).each { |i|
        p1 = corners[i].lerp(center, shrink)
        p2 = corners.round_indexer(i + 1).lerp(center, shrink)
        c p1, p2, corners.round_indexer(i + 1)
      }
      z
    }
  }
}