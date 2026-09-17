require_relative "point"
require_relative "functions"

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
