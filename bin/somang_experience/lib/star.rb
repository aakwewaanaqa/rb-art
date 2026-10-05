module RbArt
  class Star
    def translate(p) @center += p end

    def rotation(f) @rotation = f end
    def center(p) @center = p end
    def radius(f) @radius = f end
    def pointiness(f) @pointiness = f end
    def edge_count(i) @edge_count = i end
    def style(h) @style = h end
    def initialize(&block)
      self.instance_eval(&block)
      # 建立時就把 Range/Array 參數抽樣固定下來，避免 to_svg 每次（每一幀）
      # 被呼叫時都重新抽樣，造成星星形狀逐幀閃爍。
      @rotation   = RbArt.unpack_param! @rotation
      @center     = RbArt.unpack_param! @center
      @edge_count = RbArt.unpack_param! @edge_count
      @radius     = RbArt.unpack_param! @radius
      @pointiness = RbArt.unpack_param! @pointiness
      @style      = RbArt.unpack_param! @style
    end

    def to_svg
      rotation   = @rotation
      center     = @center
      edge_count = @edge_count
      radius     = @radius
      pointiness = @pointiness
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
          p1 = a.lerp(center, pointiness)
          p2 = b.lerp(center, pointiness)
          c p1, p2, b
        }
        z  
      }.to_svg
    end
  end
end