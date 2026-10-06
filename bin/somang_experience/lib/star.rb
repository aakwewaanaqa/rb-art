module RbArt
  class Star
    def translate(p) @center += p end

    def center(p) @center = p end
    def rotation(f) @rotation = f end
    def radius(f) @radius = f end
    def pointiness(f) @pointiness = f end
    def curviness(f) @curviness = f end
    def edge_count(i) @edge_count = i end
    def style(h) @style = h end
    def initialize(&block)
      self.instance_eval(&block)
      # 建立時就把 Range/Array 參數抽樣固定下來，避免 to_svg 每次（每一幀）
      # 被呼叫時都重新抽樣，造成星星形狀逐幀閃爍。
      @center     = RbArt.unpack_param! @center     || RbArt::Geometry::Origin
      @rotation   = RbArt.unpack_param! @rotation   || 0
      @radius     = RbArt.unpack_param! @radius     || 0
      @pointiness = RbArt.unpack_param! @pointiness || 0
      @curviness  = RbArt.unpack_param! @curviness  || 0
      @edge_count = RbArt.unpack_param! @edge_count || 4
      @style      = RbArt.unpack_param! @style      || RbArt::DefaultStyle
    end

    # Canvas#draw 用這個拿到 style 裡用了哪個濾鏡物件，好在畫出來的當下
    # 才去登記對應的 <defs>（見 lib/rb_art/filters.rb 的說明）。
    def filters = RbArt.style_filters(@style)

    def to_svg
      rotation   = @rotation
      center     = @center
      edge_count = @edge_count
      radius     = @radius
      pointiness = @pointiness
      curviness  = @curviness
      style      = @style
      RbArt::Path.new {
        style style

        round  = Math::PI * 2
        edge_points = (0..round).step(round.fdiv(edge_count)).to_a.map { |r|
          center + RbArt::Geometry::Point.new(
            Math.cos(r + rotation),
            Math.sin(r + rotation)
          ) * radius
        }
        
        m edge_points.first
        (0...edge_count).to_a.each { |idx|
          a = edge_points.round_indexer idx
          b = edge_points.round_indexer idx + 1
          mid_of_a_b = ((a + b) * 0.5).lerp(center, pointiness)
          p1 = a.lerp(center, pointiness).lerp(mid_of_a_b, 1 - curviness)
          p2 = b.lerp(center, pointiness).lerp(mid_of_a_b, 1 - curviness)
          c p1, p2, b
        }
        z
      }.to_svg
    end
  end
end