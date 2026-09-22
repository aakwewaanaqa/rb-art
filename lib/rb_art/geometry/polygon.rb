require_relative "point"
require_relative "functions"
require_relative "bezier"

module RbArt
  module Geometry
    # 由頂點陣列描述的簡單多邊形，提供內外判定與最近邊界點查詢。
    class Polygon
      attr_reader :points

      def initialize(points)
        @points = points
      end

      def [](index)
        @points[index]
      end

      # Ray casting：從查詢點往水平方向發射射線，計算與各邊的交點數。
      def include?(point)
        inside = false
        n = points.size

        j = n - 1
        n.times do |i|
          pi, pj = points[i], points[j]

          if (pi.y > point.y) != (pj.y > point.y) &&
             point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x
            inside = !inside
          end

          j = i
        end

        inside
      end

      # 線段 a-b 是否穿越了這個多邊形（貫穿、或至少一端落在內部）。
      def crosses_segment?(a, b)
        return true if include?(a) || include?(b)

        n = points.size
        n.times do |i|
          p1 = points[i]
          p2 = points[(i + 1) % n]
          return true if Geometry.segments_intersect?(a, b, p1, p2)
        end

        false
      end

      # 沿多邊形周長（視為封閉環）取點，t ∈ [0, 1] 是整圈周長的累積比例，
      # 跟 CubicBezier#point_at 同語意（0 = 第一個頂點，1 繞回起點）。
      def point_at(t)
        n = points.size
        edge_lengths = (0...n).map { |i| (points[(i + 1) % n] - points[i]).length }
        total = edge_lengths.sum
        return points.first if total.zero?

        target = (t % 1.0) * total
        cum = 0.0

        n.times do |i|
          len = edge_lengths[i]
          if cum + len >= target
            local_t = len.zero? ? 0.0 : (target - cum) / len
            return points[i].lerp(points[(i + 1) % n], local_t)
          end
          cum += len
        end

        points.first
      end

      # 把每個頂點磨成圓角，回傳一串首尾相接的 CubicBezier（圓角、直線邊交錯）,
      # 整圈繞回起點。圓角用「頂點自己當控制點」的二次貝茲升階而成，
      # 在起訖點精確跟兩側直線邊相切——所以整條路徑處處平滑，沒有真正的尖角，
      # 可以直接對這串曲線統一用 point_at/tangent_at 取樣，不用特別處理轉角。
      #
      # radius 是每個轉角「切掉多長」，若比相鄰邊短一半還長會自動夾住避免重疊。
      def rounded(radius:)
        n = points.size

        corners = (0...n).map { |i|
          prev = points[(i - 1) % n]
          curr = points[i]
          nxt = points[(i + 1) % n]

          len_in = (curr - prev).length
          len_out = (nxt - curr).length
          r_in = [radius, len_in / 2.0].min
          r_out = [radius, len_out / 2.0].min

          start_pt = curr.lerp(prev, r_in / len_in)
          end_pt = curr.lerp(nxt, r_out / len_out)

          Geometry::CubicBezier.new(start_pt, start_pt.lerp(curr, 2.0 / 3), end_pt.lerp(curr, 2.0 / 3), end_pt)
        }

        (0...n).flat_map { |i| [corners[i], Geometry::CubicBezier.line(corners[i].p3, corners[(i + 1) % n].p0)] }
      end

      # 邊界上離 point 最近的點，回傳 [最近點, 距離]。
      def closest_point(point)
        n = points.size
        best_point = nil
        best_dist = Float::INFINITY

        n.times do |i|
          a = points[i]
          b = points[(i + 1) % n]
          candidate = Geometry.closest_point_on_segment(point, a, b)
          dist = (point - candidate).length

          if dist < best_dist
            best_dist = dist
            best_point = candidate
          end
        end

        [best_point, best_dist]
      end
    end
  end
end
