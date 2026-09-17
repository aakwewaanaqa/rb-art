module RbArt
  module Geometry
    # 一個由 xmin/xmax/ymin/ymax 描述的矩形範圍，主要用來當作取樣邊界（見 Point.rnd）。
    #
    #   rect = RbArt::Geometry::Rect.new {
    #     xmin 0
    #     xmax 200
    #     ymin 0
    #     ymax 200
    #   }
    class Rect
      def initialize(&block)
        instance_eval(&block) if block
      end

      def xmin(value = nil) = value.nil? ? @xmin : (@xmin = value)
      def xmax(value = nil) = value.nil? ? @xmax : (@xmax = value)
      def ymin(value = nil) = value.nil? ? @ymin : (@ymin = value)
      def ymax(value = nil) = value.nil? ? @ymax : (@ymax = value)

      def width = xmax - xmin
      def height = ymax - ymin
    end
  end
end
