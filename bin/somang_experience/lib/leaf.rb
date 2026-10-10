module RbArt
  class Leaf
    def root(p) @root = p end
    def direction(p) @direction = p end
    def stem_length(f) @stem_length = f end
    def stem_width(f) @stem_width = f end
    def leaf_length(f) @leaf_length = f end
    def leaf_width(f) @leaf_width = f end
    def style(h) @style = h end
    def initialize(&block) 
      self.instance_eval(&block)
      @root        = RbArt.unpack_param! @root        || RbArt::Geometry::Point.new(0, 0)
      @direction   = RbArt.unpack_param! @direction   || RbArt::Geometry::Point.new(0, 0)
      @stem_length = RbArt.unpack_param! @stem_length || 0
      @stem_width  = RbArt.unpack_param! @stem_width  || 0
      @leaf_length = RbArt.unpack_param! @leaf_length || 0
      @leaf_width  = RbArt.unpack_param! @leaf_width  || 0
      @style       = RbArt.unpack_param! @style       || RbArt::DefaultStyle
    end

    def to_svg
      root        = @root       
      direction   = @direction  
      stem_length = @stem_length
      stem_width  = @stem_width 
      leaf_length = @leaf_length
      leaf_width  = @leaf_width 
      style       = @style      

      mirror_seg    = RbArt::Geometry::Segment.new(root, root + direction * (stem_length + leaf_length))
      to_left       = direction.rotate(Math::PI.fdiv(2))
      
      stem_l_root   = root + to_left * stem_width.fdiv(2)
      stem_l_end    = stem_l_root + direction * stem_length
      leaf_l_start  = stem_l_end
      leaf_l_p2     = leaf_l_start + to_left * leaf_width.fdiv(2)
      leaf_l_p3     = (leaf_l_p2 + mirror_seg.b) * 0.5
      
      stem_r_root   = mirror_seg.reflect(stem_l_root)
      stem_r_end    = mirror_seg.reflect(stem_l_end)
      leaf_r_start  = mirror_seg.reflect(leaf_l_start)
      leaf_r_p2     = mirror_seg.reflect(leaf_l_p2)
      leaf_r_p3     = mirror_seg.reflect(leaf_l_p3)

      leaf_end      = mirror_seg.b

      RbArt::Path.new {
        style style

        m stem_r_root
        l stem_l_root
        l stem_l_end
        c leaf_l_p2, leaf_l_p3, leaf_end
        c leaf_r_p3, leaf_r_p2, stem_r_end
        l stem_r_root
        z
      }.to_svg
    end
  end
end