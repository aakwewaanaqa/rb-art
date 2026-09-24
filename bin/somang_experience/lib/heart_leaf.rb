require_relative "../../../lib/rb_art"
require_relative "styles"

module RbArt
  class HeartLeaf
    def root(p) @root = p end
    def direction(p) @direction = p end
    def leaf_length(f) @leaf_length = f end
    def leaf_width(f) @leaf_width = f end
    def leaf_end_pinch(f) @leaf_end_pinch = f end
    def leaf_bottom_pull(f) @leaf_bottom_pull = f end
    def stem_length(f) @stem_length = f end
    def stem_width(f) @stem_width = f end
    def style(s) @style = s end

    def initialize(&block)
      self.instance_eval(&block)

      r =                RbArt.unpack_param! @root
      d =                RbArt.unpack_param! @direction
      s_length =         RbArt.unpack_param! @stem_length
      s_width  =         RbArt.unpack_param! @stem_width
      l_length =         RbArt.unpack_param! @leaf_length
      l_width  =         RbArt.unpack_param! @leaf_width
      leaf_end_pinch =   RbArt.unpack_param! @leaf_end_pinch   || 0.5
      leaf_bottom_pull = RbArt.unpack_param! @leaf_bottom_pull || 0.75
      
      d_2_left = d.rotate(Math::PI * -0.5)

      # 整片葉子沿著 root -> direction 這條中軸線左右對稱，所以只算左半邊，
      # 右半邊一律用 axis.reflect 鏡射左半邊算出來，不用再對每個點重算一次。
      axis = RbArt::Geometry::Segment.new(r, r + d)

      _style = @style
      @elements = [] << RbArt::Path.new {
        style _style

        stem_end = r + d * s_length
        stem_l_root = r        + d_2_left * s_width * 0.5
        stem_l_end  = stem_end + d_2_left * s_width * 0.5
        stem_r_root = axis.reflect(stem_l_root)
        stem_r_end  = axis.reflect(stem_l_end)

        leaf_root = stem_end
        leaf_mid = leaf_root + d * l_length * 0.5
        leaf_end = leaf_root + d * l_length

        leaf_l = leaf_mid + d_2_left * l_width * 0.5
        leaf_r = axis.reflect(leaf_l)

        leaf_l_p1 = leaf_root.lerp(leaf_l, 0.5).reflect(leaf_end, leaf_bottom_pull)
        leaf_l_p2 = leaf_l.reflect(leaf_end)

        leaf_r_p1 = axis.reflect(leaf_l_p1)
        leaf_r_p2 = axis.reflect(leaf_l_p2)

        leaf_l_end_p1 = leaf_l.lerp(leaf_end, 0.25)
        leaf_l_end_p2 = axis.reflect(leaf_l.lerp(leaf_end, 0.75), leaf_end_pinch)

        leaf_r_end_p1 = axis.reflect(leaf_l_end_p1)
        leaf_r_end_p2 = axis.reflect(leaf_l_end_p2)

        m r
        l stem_l_root
        l stem_l_end
        c leaf_l_p1, leaf_l_p2, leaf_l
        c leaf_l_end_p1, leaf_l_end_p2, leaf_end
        # 從 leaf_end 往右葉瓣走，是右半邊那條曲線反著畫，
        # 貝茲曲線反向時控制點順序也要反過來（P0,C1,C2,P1 -> P1,C2,C1,P0）。
        c leaf_r_end_p2, leaf_r_end_p1, leaf_r
        c leaf_r_p2, leaf_r_p1, stem_r_end
        l stem_r_root
        l r
        z
      }
    end

    def to_svg
      "<g>#{@elements.map(&:to_svg).join("\n")}</g>"
    end
  end
end