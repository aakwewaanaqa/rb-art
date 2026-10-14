module RbArt
  # 把外部的 SVG 檔（例如 Affinity 匯出的圖）當成一個可以 draw 的元素，
  # 以巢狀 <svg> 的形式放進 Canvas：x / y 是左上角，width / height 是要
  # 縮放到的大小，原檔的 viewBox 會負責把它的座標縮進這個框。
  #
  #   RbArt::SvgImage.new {
  #     file   "out/post/20261014_layers/wait.svg"
  #     x 0; y 0
  #     width  1000
  #     height 1000
  #   }
  #
  # 動畫裡每格重建一個新的 SvgImage 只改位置就好——同一個檔案只會讀一次、
  # 清理一次，之後從快取拿，不會每格重讀檔案。
  class SvgImage
    def file  (v = nil) = v.nil? ? @file   : (@file   = v)
    def x     (v = nil) = v.nil? ? @x      : (@x      = v)
    def y     (v = nil) = v.nil? ? @y      : (@y      = v)
    def width (v = nil) = v.nil? ? @width  : (@width  = v)
    def height(v = nil) = v.nil? ? @height : (@height = v)

    # 一次設定左上角，吃 Point。
    def at(point)
      x point.x
      y point.y
    end

    @@sources = {}

    def initialize(&block)
      self.instance_eval(&block) if block_given?
      raise ArgumentError, "SvgImage 沒設定檔案：請在設定區塊呼叫 file \"...\"" unless @file
      @x      = RbArt.unpack_param! @x || 0
      @y      = RbArt.unpack_param! @y || 0
      @width  = RbArt.unpack_param! @width
      @height = RbArt.unpack_param! @height
    end

    def to_svg
      SvgImage.source(@file).sub(/<svg\b/) {
        %(<svg x="#{@x.round(2)}" y="#{@y.round(2)}" width="#{@width}" height="#{@height}")
      }
    end

    # 讀檔並清理成可以巢狀放進別的 <svg> 的樣子：
    #   - 去掉 XML 宣告跟 DOCTYPE（放在文件中間是不合法的）
    #   - 去掉根 <svg> 原本的 x / y / width / height（Affinity 匯出的是
    #     100%，留著會跟我們設定的值打架），之後由 to_svg 補上
    def self.source(path)
      @@sources[File.expand_path(path)] ||= begin
        svg = File.read(path).sub(/\A.*?(?=<svg\b)/m, "")
        svg.sub(/<svg\b[^>]*>/) { |tag| tag.gsub(/\s(?:x|y|width|height)="[^"]*"/, "") }
      end
    end
  end
end
