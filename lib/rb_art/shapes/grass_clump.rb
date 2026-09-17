require_relative "../geometry"

module RbArt
  module Shapes
    # 一叢草：橢圓輪廓分成 N 節，每節向外鼓出一片圓潤的瓣狀刺，
    # 整叢是「單一連續外框」（像花朵/雲朵的瓣狀輪廓），而不是每瓣
    # 各自疊起來的獨立形狀。
    #
    # 技巧：
    # - 根部把手（c1、c2）沿著同一個生長方向（朝向尖端）延伸，兩端
    #   把手彼此近乎平行，讓刺從根部先鼓出去、再收攏到尖端，輪廓才會
    #   圓潤，而不是把手各自沿法線發散、在近根部就收斂成尖銳三角形。
    # - 尖端把手（tc1、tip、tc2）共線，兩段曲線在尖端切線連續，加上
    #   較長的把手讓尖端渾圓（不是尖角）。
    # - 相鄰兩瓣共用同一個根部點（這一瓣的 p2 就是下一瓣的 p1），整叢
    #   用一條 M ... C ... C ... Z 路徑一次畫完，瓣與瓣之間自然形成
    #   淺淺的凹谷，不必另外畫底部圓弧。
    class GrassClump
      include Geometry

      def initialize(cx:, cy:, rx:, ry:, segments:, spike_ratio: (0.15..0.5), jitter: 0.35,
                      base_handle_ratio: (0.45..0.7), tip_handle_ratio: 0.55, rng: Random.new)
        @ellipse = Ellipse.new(cx: cx, cy: cy, rx: rx, ry: ry)
        @segments = segments
        @spike_ratio = spike_ratio
        @jitter = jitter
        @base_handle_ratio = base_handle_ratio
        @tip_handle_ratio = tip_handle_ratio
        @rng = rng
      end

      def path_d
        step = TWO_PI / @segments
        angles = Array.new(@segments) { |i| [i * step, (i + 1) * step] }
        start = @ellipse.point_at(angles.first.first)
        curves = angles.map { |a1, a2| spike_curve(a1, a2) }
        "M #{start.to_svg} #{curves.join(' ')} Z"
      end

      def to_svg(fill:, stroke:, stroke_width: 1.4)
        %(<path d="#{path_d}" fill="#{fill}" stroke="#{stroke}" stroke-width="#{stroke_width}" stroke-linejoin="round"/>)
      end

      private

      def spike_curve(a1, a2)
        e = @ellipse
        am = (a1 + a2) / 2.0
        p1, p2 = e.point_at(a1), e.point_at(a2)

        lo, hi = @spike_ratio.first, @spike_ratio.last
        spike_len = e.scale_ref * (lo + @rng.rand * (hi - lo))

        tip_angle = am + (@rng.rand - 0.5) * @jitter
        tip = Point.new(e.cx + (e.rx + spike_len) * Math.cos(tip_angle),
                         e.cy + (e.ry + spike_len) * Math.sin(tip_angle))

        blo, bhi = @base_handle_ratio.first, @base_handle_ratio.last
        growth = Point.new(Math.cos(tip_angle), Math.sin(tip_angle))
        base_handle = spike_len * (blo + @rng.rand * (bhi - blo))
        c1 = p1 + growth.scale(base_handle)
        c2 = p2 + growth.scale(base_handle)

        tip_handle = spike_len * @tip_handle_ratio
        tangent = Point.new(-Math.sin(tip_angle), Math.cos(tip_angle))
        tc1 = tip - tangent.scale(tip_handle)
        tc2 = tip + tangent.scale(tip_handle)

        "C #{c1.to_svg}, #{tc1.to_svg}, #{tip.to_svg} " \
          "C #{tc2.to_svg}, #{c2.to_svg}, #{p2.to_svg}"
      end
    end
  end
end
