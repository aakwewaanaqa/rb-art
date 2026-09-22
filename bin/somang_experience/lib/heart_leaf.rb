require_relative "../../../lib/rb_art"
require_relative "styles"

module RbArt
  class HeartLeaf
    def root(p) @root = p end
    def direction(p) @direction = p end
    def leaf_length(f) @leaf_length = f end
    def leaf_width(f) @leaf_width = f end
    def stem_length(f) @stem_length = f end
    def stem_width(f) @stem_width = f end
    def style(s) @style = s end

    def initialize(&block)
      self.instance_eval(&block)

      r = @root
      d = @direction
      d_2_left  = d.rotate(Math::PI * -0.5)
      d_2_right = d.rotate(Math::PI * +0.5)
      RbArt::Path.new {
        style @style

        stem_end = r + d * @stem_length
        stem_l_root = r        + d_2_left  * @stem_width
        stem_l_end  = stem_end + d_2_left  * @stem_width
        stem_r_root = r        + d_2_right * @stem_width
        stem_r_end  = stem_end + d_2_right * @stem_width

        leaf_root = stem_end
        leaf_mid = leaf_root + d * @leaf_length * 0.5
        leaf_end = leaf_root + d * @leaf_length

        leaf_l   = leaf_mid + d_2_left * @leaf_length * 0.5
        leaf_r   = leaf_mid + d_2_right * @leaf_length * 0.5
        
        leaf_l_p1 = leaf_root + (leaf_l - leaf_end)
        leaf_l_p2 = leaf_l    + (leaf_l - leaf_end)

        leaf_r_p1 = leaf_root + (leaf_r - leaf_end)
        leaf_r_p2 = leaf_l    + (leaf_r - leaf_end)
      }
    end

  end
end