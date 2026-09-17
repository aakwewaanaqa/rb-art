require_relative "rb_art/geometry"
require_relative "rb_art/color"
require_relative "rb_art/path"
require_relative "rb_art/canvas"
require_relative "rb_art/animation"
require_relative "rb_art/shapes/grass_clump"

module RbArt
  # 快速從 hex 字串建立 ColorHex，等同 ColorHex.new { code str }。
  #
  #   RbArt.color_hex("#ff0000").to_s #=> "#ff0000ff"
  def self.color_hex(str) = ColorHex.new { code str }
end
