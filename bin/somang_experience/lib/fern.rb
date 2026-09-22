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

    # 固定這株的隨機骨架（控制點、分段數），同一個 seed 每次 to_svg 都會拿到
    # 一樣的基礎形狀，只有 wind 造成的偏移不同——這樣才能在動畫裡逐幀呼叫
    # to_svg(wind: ...) 而形狀不會亂跳。不設就每次 initialize 都用新亂數。
    def seed(v) @seed = v end

    def initialize(&block)
      self.instance_eval(&block)
      @rng = Random.new(@seed || Random.new_seed)
      @base_curve = build_base_curve
      @n = (5..10).to_a.sample(random: @rng)
    end

    # wind: 可選的 proc，簽名 ->(point, height_ratio) { offset_point }。
    # height_ratio 是 0（根部，固定不動）~1（頂端，位移最大）。純函式重算，
    # 不會動到 @rng，所以同一株在不同 frame 呼叫骨架都一樣，只有 wind 偏移不同。
    def to_svg(wind: nil)
      p0 = @base_curve[:p0]
      p1 = offset_point(@base_curve[:p1], wind, 0.4)
      p2 = offset_point(@base_curve[:p2], wind, 0.75)
      p3 = offset_point(@base_curve[:p3], wind, 1.0)
      curve = RbArt::Geometry::CubicBezier.new(p0, p1, p2, p3)

      stage_2 = -> {
        base = (0...@n).map { |i| @base * (@growth ** i) }
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
            stroke plant_style[:fill]
            stroke_width "1"
          },
          RbArt::Path.new {
            m seg.p0
            c rp1, rp2, seg.p3
            c seg.p2, seg.p1, seg.p0
            z

            fill plant_style[:fill]
            stroke plant_style[:fill]
            stroke_width "1"
          },
        ]
      }

      "<g>\n#{svg_elements.map(&:to_svg).join("\n")}\n</g>"
    end

    private

    def build_base_curve
      outward = @direction * @length
      o = @root
      control_points =
        [o, o].map { |cp|
          cp + outward * @rng.rand + RbArt::Geometry::Rnd.inside_unit_circle(rng: @rng) * @rng.rand * @bend
        }.sort_by { |cp|
          o.dist(cp)
        }

      {
        p0: o,
        p1: control_points[0],
        p2: control_points[1],
        p3: o + outward
      }
    end

    def offset_point(p, wind, height_ratio)
      return p unless wind

      p + wind.call(p, height_ratio)
    end
  end
end
