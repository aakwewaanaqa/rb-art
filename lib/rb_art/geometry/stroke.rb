require_relative "point"

module RbArt
  module Geometry
    # 把一條由多段 CubicBezier 組成的中心線「展開」成有寬度的填色外框，
    # 也就是向量軟體常見的 Expand Stroke / Outline Stroke。
    #
    # 貝茲曲線的偏移曲線本身通常不是貝茲曲線，沒有精確解，所以用「取樣折線」
    # 近似：對每段曲線密集取樣 point_at(t) + normal_at(t) * halfwidth，折線夠密
    # 視覺上跟真正的偏移曲線幾乎沒差異。轉角跟端點只做 round join / round cap
    # （用圓弧點取代尖角），不處理 miter，也不處理凹處偏移量過大導致的自我相交
    # ——SVG 預設 fill-rule（nonzero）下，這類自我重疊的小 loop 不會被挖空，
    # 所以視覺上通常無害，只是沒有真正裁掉多畫的部分。
    module StrokeExpand
      module_function

      # beziers: 中心線，可以是單一 CubicBezier、CubicBezier 陣列（首尾相接），
      # 或 ArbitraryChain（會直接拿它的 items）。
      # width: 線寬（跟 stroke-width 語意一致，是總寬度不是半寬）
      # closed: 中心線本身是否封閉（例如沿封閉形狀的邊描邊）
      # samples: 每段曲線取幾等分（實際取 samples+1 個點，含頭尾）
      #
      # 回傳一組 Point 陣列的陣列：closed: false 時只有一個（單一封閉外框，
      # 頭尾已經用 round cap 接起來）；closed: true 時有兩個（外圈、內圈各
      # 自封閉），呼叫端要用 evenodd fill-rule 疊起來才會變成「圈狀」的填色。
      # 每個陣列都可以直接丟給 Path：m(loop.first); l(*loop[1..]); z。
      #
      # @return [Array<Array<Point>>] 一組 loop，每個 loop 是一串首尾相接的 Point
      def outline(beziers, width, closed: false, samples: 16, cap_samples: 8, join_samples: 6)
        beziers = normalize(beziers)
        raise ArgumentError, "beziers can't be empty" if beziers.empty?

        halfwidth = width / 2.0
        left, right = [], []

        beziers.each_with_index { |bez, i|
          seg_left = offset_side(bez, halfwidth, samples)
          seg_right = offset_side(bez, -halfwidth, samples)

          if i.positive?
            joint = bez.point_at(0)
            left.concat(join_arc(joint, left.last, seg_left.first, join_samples))
            right.concat(join_arc(joint, right.last, seg_right.first, join_samples))
          end

          left.concat(seg_left)
          right.concat(seg_right)
        }

        if closed
          joint = beziers.first.point_at(0)
          left.concat(join_arc(joint, left.last, left.first, join_samples))
          right.concat(join_arc(joint, right.last, right.first, join_samples))
          [dedup(left), dedup(right)]
        else
          end_cap = cap_arc(beziers.last.point_at(1), left.last, cap_samples)
          start_cap = cap_arc(beziers.first.point_at(0), right.first, cap_samples)
          [dedup(left + end_cap + right.reverse + start_cap)]
        end
      end

      # 把 outline 接受的三種輸入統一轉成 CubicBezier 陣列。
      def normalize(beziers)
        case beziers
        when CubicBezier then [beziers]
        when ArbitraryChain then beziers.items(nil)
        else beziers
        end
      end

      # 對單一段曲線取樣，沿法線偏移 offset（正負代表左右兩側）。
      def offset_side(bez, offset, samples)
        (0..samples).map { |i|
          t = i.fdiv(samples)
          bez.point_at(t) + bez.normal_at(t).scale(offset)
        }
      end

      # 端點收尾用的圓弧：固定順時針從 from 掃過半圈。這個方向是照 outline
      # 呼叫時 from 的取法（見上面 end_cap / start_cap）反推出來的，兩種情況
      # 剛好都要順時針掃才會往外鼓出去（而不是往線段內部凹進來）。
      def cap_arc(center, from, samples)
        step = Math::PI / (samples + 1)
        rel = from - center
        (1..samples).map { |i| center + rel.rotate(-step * i) }
      end

      # 中間轉角用的圓弧：從 from 掃到 to，走角度差較小的那個方向
      # （凸角會補出真正的圓角，凹角則掃出一個很小、會被蓋掉的重疊弧）。
      def join_arc(center, from, to, samples)
        r = center.dist(from)
        return [to] if r < 1e-9

        a0 = Math.atan2((from - center).y, (from - center).x)
        a1 = Math.atan2((to - center).y, (to - center).x)
        delta = a1 - a0
        delta -= TWO_PI while delta > Math::PI
        delta += TWO_PI while delta < -Math::PI

        rel = from - center
        (1..samples).map { |i| center + rel.rotate(delta * i.fdiv(samples + 1)) }
      end

      # 相鄰兩點幾乎重合時去掉一個，避免折線裡出現退化的 0 長度線段。
      def dedup(points, eps: 1e-6)
        points.each_with_object([]) { |p, acc| acc << p if acc.empty? || acc.last.dist(p) > eps }
      end
    end
  end
end
