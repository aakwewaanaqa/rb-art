require_relative "../../lib/rb_art"

width = 750
height = 500
param = {
  root: RbArt::Geometry::Point.new(750 * 0.5, 500 * 0.75),
  direction: RbArt::Geometry::Point.new(0, -1),
  length: 200,
  base: 2,
  growth: 1.35,
  pointyness: 0.4,
  bend: 200,
  style: {
    fill: "none",
    stroke: "black",
    stroke_width: "4pt",
  }
}

RbArt::Canvas.new {
  width width
  height height
  background "#9ED06D"
  svg "out/fern_3.svg"

  stage_1 = -> {
    outward = param.dig(:direction) * param.dig(:length)
    o = param.dig(:root)
    control_points = 
      [o, o].map { |cp|
        cp + outward * Random.rand + RbArt::Geometry::Rnd.inside_unit_circle * Random.rand * param.dig(:bend)
      }.sort_by { |cp|
        (o - cp).length
      }

    {
      p0: o,
      p1: control_points[0],
      p2: control_points[1],
      p3: o + outward
    }
  }.()

  p0 = stage_1[:p0]
  p1 = stage_1[:p1]
  p2 = stage_1[:p2]
  p3 = stage_1[:p3]
  curve = RbArt::Geometry::CubicBezier.new(p0, p1, p2, p3)

  stage_2 = -> {
    n = (5..10).to_a.sample
    base = (0...n).map { |i| param.dig(:base) * (param.dig(:growth) ** i) }
    sum = base.sum
    t_lengths = (base.map { |v| v / sum.to_f }).reverse
    arc_segs = curve.split_by_arc_lengths t_lengths

    {
      t_lengths: t_lengths,
      arc_segs: arc_segs
    }
  }.()

  stage_2[:arc_segs].reverse.each_with_index { |seg, idx|
    len = seg.arc_length
    tan = seg.tangent_at 1.0
    ltan = (tan).rotate(Math::PI * -0.5) * len
    rtan = (tan).rotate(Math::PI * +0.5) * len
    lp2 = seg.p3 + ltan + tan * len * param.dig(:pointyness)
    rp2 = seg.p3 + rtan + tan * len * param.dig(:pointyness)
    lp1 = seg.p0 + ltan + tan * len * param.dig(:pointyness)
    rp1 = seg.p0 + rtan + tan * len * param.dig(:pointyness)
    draw RbArt::Path.new {
      m seg.p0
      c lp1, lp2, seg.p3
      m seg.p0
      c rp1, rp2, seg.p3
      m seg.p0
      c seg.p1, seg.p2, seg.p3

      stroke       param.dig(:style, :stroke)
      fill         param.dig(:style, :fill)
      stroke_width param.dig(:style, :stroke_width)
    }
  }
}