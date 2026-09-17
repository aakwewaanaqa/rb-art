require_relative "point"

module RbArt
  module Geometry
    # 描述一個橢圓，提供輪廓上的點座標與外向法線（與切線垂直）。
    class Ellipse
      attr_reader :cx, :cy, :rx, :ry

      def initialize(cx:, cy:, rx:, ry:)
        @cx, @cy, @rx, @ry = cx, cy, rx, ry
      end

      # 參數 t（弧度）對應的輪廓座標
      def point_at(t)
        Point.new(cx + rx * Math.cos(t), cy + ry * Math.sin(t))
      end

      # 參數 t 處的外向單位法線（垂直於該點切線，指向橢圓外側）
      def normal_at(t)
        nx = ry * Math.cos(t)
        ny = rx * Math.sin(t)
        len = Math.hypot(nx, ny)
        Point.new(nx / len, ny / len)
      end

      def scale_ref
        Math.hypot(rx, ry)
      end
    end
  end
end
