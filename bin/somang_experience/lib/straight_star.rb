module RbArt
  class StraightStar
    def center(p) @center = p end
    def rotation(p) @rotation = p end
    def radius(f) @radius = f end
    def edge_count(i) @edge_count = i end
    def pointiness(f) @pointiness = f end
    def style(h) @style = h end
    def initialize(&block) 
      self.instance_eval(&block)
      @center     = RbArt.unpack_param! @center     || RbArt::Geometry::Origin
      @rotation   = RbArt.unpack_param! @rotation   || 0
      @radius     = RbArt.unpack_param! @radius     || 0
      @edge_count = RbArt.unpack_param! @edge_count || 5
      @pointiness = RbArt.unpack_param! @pointiness || 0.5
      @style      = RbArt.unpack_param! @style      || RbArt::DefaultStyle
    end

    # Canvas#draw 用這個拿到 style 裡用了哪個濾鏡物件，好在畫出來的當下
    # 才去登記對應的 <defs>（見 lib/rb_art/filters.rb 的說明）。
    def filters = RbArt.style_filters(@style)

    def to_svg
      center = @center
      radius = @radius
      edge_count = @edge_count
      pointiness = @pointiness
      style = @style
      radian_per_edge = RbArt::TwoPi.fdiv(edge_count)
      RbArt::Path.new {
        style style

        (0...edge_count).each { |idx|
          r = radian_per_edge * idx
          f = RbArt::Geometry::Point.new(
            Math.cos(r),
            Math.sin(r),
          ) * radius + center

          r = radian_per_edge * (idx + 1)
          t = RbArt::Geometry::Point.new(
            Math.cos(r),
            Math.sin(r),
          ) * radius + center

          mid = ((f + t) * 0.5).lerp(center, pointiness)

          m f if idx == 0
          l mid
          l t
          z if idx + 1 == edge_count
        }
      }.to_svg
    end
  end
end