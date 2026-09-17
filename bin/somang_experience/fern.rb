module RbArt
  class Fern
    def root(v) @root = v end
    def direction(v) @direction = v end
    def length(v) @length = v end
    def base(v) @base = v end
    def growth(v) @growth = v end
    def pointiness(v) @pointiness = v end
    def heartiness(v) @heartiness = v end
    def bend(v) @bend = v end
    def styles(v) @styles = v end

    def initialize(&block)
      self.instance_eval(&block)
    end

    def to_svg
      stage_1 = -> {
        outward = @direction * @length
        o = @root
        control_points = 
          [o, o].map { |cp|
            cp + outward * Random.rand + RbArt::Geometry::Rnd.inside_unit_circle * Random.rand * @bend
          }.sort_by { |cp|
            o.dist(cp)
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
        base = (0...n).map { |i| @base * (@growth ** i) }
        sum = base.sum
        t_lengths = (base.map { |v| v / sum.to_f }).reverse
        arc_segs = curve.split_by_arc_lengths t_lengths
    
        {
          t_lengths: t_lengths,
          arc_segs: arc_segs
        }
      }.()
    
      plant_style = RbArt::Geometry::Rnd.weighted_sample(@styles.map { |s| [s, s[:weight] || 1] })

      svg_elements = []
      stage_2[:arc_segs].reverse.each_with_index { |seg, idx|
        len = seg.arc_length
        tan = seg.tangent_at 1.0
        lnorm = (tan).rotate(Math::PI * -0.5) * len
        rnorm = (tan).rotate(Math::PI * +0.5) * len

        lp1 = seg.p0 + lnorm + tan * len * @heartiness
        lp2 = seg.p3 + lnorm + tan * len * @heartiness
        lpmid = (lp1 + lp2) * 0.5
        lp1 = lp1.lerp(lpmid, @pointiness)
        lp2 = lp2.lerp(lpmid, @pointiness)
        
        rp2 = seg.p3 + rnorm + tan * len * @heartiness
        rp1 = seg.p0 + rnorm + tan * len * @heartiness
        rpmid = (rp1 + rp2) * 0.5
        rp1 = rp1.lerp(rpmid, @pointiness)
        rp2 = rp2.lerp(rpmid, @pointiness)

        svg_elements.concat [
          RbArt::Path.new {
            m seg.p0
            c lp1, lp2, seg.p3
            c seg.p2, seg.p1, seg.p0
            z

            fill plant_style[:fill]
            stroke "none"
          },
          RbArt::Path.new {
            m seg.p0
            c rp1, rp2, seg.p3
            c seg.p2, seg.p1, seg.p0
            z

            fill plant_style[:fill]
            stroke "none"
          },
        ]
      }

      "<g>\n#{svg_elements.map(&:to_svg).join("\n")}\n</g>"
    end
  end
end