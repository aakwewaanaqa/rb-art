require_relative "point"
require_relative "functions"

module RbArt
  module Geometry
    # 由兩個端點 a、b 描述的線段，主要用來做「對線鏡射」「找最近點」這類
    # 跟線段本身相關的查詢；跟多邊形/相交有關的邏輯留在 Geometry module
    # functions（見 functions.rb）裡，這裡只是薄薄包一層方便呼叫。
    class Segment
      attr_reader :a, :b

      def initialize(a, b)
        @a, @b = a, b
      end

      def vector = b - a
      def length = vector.length
      def direction = vector.normalize
      def midpoint = a.lerp(b, 0.5)

      # point 到「a、b 所在直線」上的垂足，不會被夾在線段範圍內
      # （跟 closest_point 不同，closest_point 會夾在 a-b 之間）。
      def foot_of(point)
        a + direction * (point - a).dot(direction)
      end

      # 把 point 以這條直線為鏡射軸做鏡射：先求垂足，垂足當鏡子把 point
      # 反射過去（Point#reflect），等於對整條線鏡射。t 語意同 Point#reflect。
      def reflect(point, t = 1.0) = foot_of(point).reflect(point, t)

      # point 到線段（夾在 a-b 之間，不是整條直線）上最近的點。
      def closest_point(point) = Geometry.closest_point_on_segment(point, a, b)

      def intersects?(other) = Geometry.segments_intersect?(a, b, other.a, other.b)
    end
  end
end
