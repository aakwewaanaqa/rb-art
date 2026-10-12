require_relative "ref"
ref

generate_style = -> {
  colors = RbArt::GrassColors.sample 2
  {
    stroke: colors.first,
    fill: colors.second,
    stroke_width: "4pt"
  }
}

CanvasSize   = 1000
CanvasCenter = ([CanvasSize.fdiv(2)] * 2).to_point
LeafRotation = [
  Math::PI.fdiv(32) * 8,
  Math::PI.fdiv(32) * 7,
  Math::PI.fdiv(32) * 6,
]
SpiralVine   = RbArt::Geometry::Spiral.new {
  center       CanvasCenter
  rotation     0
  radius       0
  end_radius   CanvasSize.fdiv(2)
  end_rotation 5.to_rad * 2
}
VinePolyline = -> {
  points = (0...2000).map { |idx|
    SpiralVine.point_at(idx.fdiv(2000))
  }
  RbArt::Geometry::Polyline.new {
    points points
  }
}.()
VineStyle = -> {
  colors = RbArt::GrassColors.sample 2
  {
    fill: colors.second,
    stroke: colors.first,
    stroke_width: "4pt"
  }
}.()
LeafInterval = (80..200)
LeafData = -> {
  data = []
  at = 0
  while at < VinePolyline.length
    at += RbArt.unpack_param! LeafInterval
    data << {
      leaves: [
        RbArt::Leaf.new {
          stem_length (15..17)
          stem_width  3
          leaf_length (60..90)
          leaf_width  (75..85)
          style(generate_style.())
        },
        RbArt::Leaf.new {
          stem_length (15..17)
          stem_width  3
          leaf_length (60..90)
          leaf_width  (75..85)
          style(generate_style.())
        },
      ],
      at: at,
      rotation: LeafRotation.sample
    }
  end
  data
}.()
RbArt::Animation.new {
  frames 60
  fps 12
  dir "out/post/20261011"
  mp4 "out/post/20261011.mp4"
  gif "out/post/20261011.gif"
}.render { |i, total|
  RbArt::Canvas.new {
    width      CanvasSize
    height     CanvasSize
    background RbArt::BackgroundColor
    svg "out/post/20261011.svg"

    t = i.fdiv(total)
    current_grow_length = VinePolyline.length * t

    polyline_point_count = VinePolyline.acc_lengths.count { |len| len <= current_grow_length }.clamp(2, VinePolyline.points.count)
    polyline_points      = VinePolyline.points.take(polyline_point_count)
    outline_points       = RbArt::Geometry::StrokeExpand.outline_polyline(
      polyline_points,
      15
    ).first

    draw RbArt::Path.new {
      style VineStyle

      m outline_points.first
      outline_points[1..].each { |p|
        l p
      }
      z
    }

    -> {
      idx = 0
      while idx < LeafData.count && LeafData[idx][:at] <= current_grow_length
        at          = LeafData[idx][:at]
        t           = VinePolyline.length_t_to_func_t(at)
        root        = SpiralVine.point_at(t)
        direction   = SpiralVine.tangent_at(t)
        l_direction = direction.rotate(-LeafData[idx][:rotation])
        r_direction = direction.rotate(+LeafData[idx][:rotation])
        LeafData[idx][:leaves][0].root root
        LeafData[idx][:leaves][0].direction l_direction
        draw LeafData[idx][:leaves][0]
        LeafData[idx][:leaves][1].root root
        LeafData[idx][:leaves][1].direction r_direction
        draw LeafData[idx][:leaves][1]
        idx += 1
      end
    }.()
  }
}