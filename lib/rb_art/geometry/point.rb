module RbArt
  module Geometry
    TWO_PI = Math::PI * 2

    Point = Struct.new(:x, :y) do
      # 在 rect 範圍內取一個隨機點（Rect 需先設定好 xmin/xmax/ymin/ymax）。
      def self.rnd(rect, rng: Random) = Point.new(rng.rand(rect.xmin..rect.xmax), rng.rand(rect.ymin..rect.ymax))

      def +(other) = Point.new(x + other.x, y + other.y)
      def -(other) = Point.new(x - other.x, y - other.y)
      def scale(s) = Point.new(x * s, y * s)
      def *(s) = scale(s)
      def dot(other) = x * other.x + y * other.y
      def length = Math.hypot(x, y)
      def dist(other) = (self - other).length
      def normalize = scale(1.0 / length)
      def rotate(theta) = Point.new(x * Math.cos(theta) - y * Math.sin(theta), x * Math.sin(theta) + y * Math.cos(theta))
      def to_svg = "#{x.round(2)} #{y.round(2)}"
      def lerp(target, t) = self * (1.0 - t) + target * t
      # self 當鏡子（中心點），把 point 對 self 鏡射過去。
      # t 是「原點 -> 完全鏡射點」之間的插值：t=0 原地不動、t=1 完全鏡射、
      # t=0.5 剛好落在鏡子（self）本身上。
      def reflect(point, t = 1.0) = point.lerp(self * 2 - point, t)
      def set_x(x) = Point.new(x, y)
      def set_y(y) = Point.new(x, y)
    end
  end
end
