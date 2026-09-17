require_relative "fern"
require_relative "styles"
require_relative "../../lib/rb_art"

RbArt::Canvas.new {
  HEIGHT = 2000
  WIDTH = 2800

  width WIDTH
  height HEIGHT
  background RbArt::BackgroundColor.to_s
  svg "out/fern_field.svg"
  png8 "out/fern_field.png", colors: 64

  roots = RbArt::Geometry::PoissonDisc.sample(width: WIDTH, height: HEIGHT, radius: 100).sort_by { |p|
    p.y
  }

  roots.each { |root|
    depth = root.y / HEIGHT.to_f
    scale = 0.85 + 0.65 * depth

    angle = (Random.rand - 0.5) * (Math::PI * 0.3)
    direction = RbArt::Geometry::Point.new(0, -1).rotate(angle)

    styles = RbArt::GrassStyles.map { |fs|
      {
        fill: fs[:fill].to_s,
        stroke: fs[:stroke].to_s,
        stroke_width: "4pt",
        weight: fs[:weight],
      }
    }

    draw RbArt::Fern.new {
      root root
      direction direction
      length (240 + Random.rand * 120) * scale
      base 2
      growth 1.2 + Random.rand * 0.3
      pointiness (0.6..1.0).step(0.1).to_a.sample
      heartiness (0.6..1.0).step(0.1).to_a.sample
      bend (180 + Random.rand * 240) * scale
      styles styles
    }
  }
}