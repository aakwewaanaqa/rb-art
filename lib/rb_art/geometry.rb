# 共用的向量與橢圓幾何工具。
require_relative "geometry/cumulative_locator/cumulative_locator"
require_relative "geometry/arc_length/arc_length"
require_relative "geometry/arbitrary_chain"
require_relative "geometry/point"
require_relative "geometry/segment"
require_relative "geometry/rect"
require_relative "geometry/functions"
require_relative "geometry/ellipse"
require_relative "geometry/polygon"
require_relative "geometry/spiral"
require_relative "geometry/polyline"
require_relative "geometry/bezier"
require_relative "geometry/path_data"
require_relative "geometry/stroke_expand/stroke_expand"
require_relative "geometry/rnd/rnd"
require_relative "geometry/poisson_disc/poisson_disc"
require_relative "geometry/perlin"

module RbArt::Geometry
  Origin = RbArt::Geometry::Point.new(0, 0)
end