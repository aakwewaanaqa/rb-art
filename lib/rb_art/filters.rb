module RbArt
  # 濾鏡描述物件：建立時只記錄參數跟配好 id，不綁定任何特定 Canvas。
  # 真正的 <filter> 定義字串（to_def）跟參照字串（to_ref）都留到被用到時
  # 才產生——跟 Path::Command 把指令資料跟字串化（render）分開是同一個
  # 套路，只是這裡字串化的時機是 Canvas#draw 收到用了這個濾鏡的元素時，
  # 而不是建立濾鏡的當下。
  #
  # 同一個 GlowFilter 物件可以重複丟給多個圖案的 style(filter:)，甚至跨
  # 多個 Canvas 使用；Canvas 會用 id 自動去重，只登記一次 def。
  class GlowFilter
    attr_reader :id

    @@count = 0

    def color(v)         @color = v end
    def std_deviation(f) @std_deviation = f end
    def opacity(f)       @opacity = f end

    def initialize(&block)
      self.instance_eval(&block) if block_given?
      # color 沒有「要不要隨機抽樣」的意義（nil 代表沿用原圖顏色），
      # 不走 unpack_param!，直接存起來。
      @std_deviation = RbArt.unpack_param! @std_deviation || 8
      @opacity       = RbArt.unpack_param! @opacity || 1
      @id = "glow#{@@count += 1}"
    end

    # 畫圖元素拿來填 filter 屬性值用的參照字串。
    def to_ref = "url(##{id})"

    # Canvas 拿來塞進 <defs> 的實際濾鏡定義。
    # 做法是標準的 Gaussian blur + feMerge：模糊一圈疊在原圖下面當光暈，
    # 原圖再蓋在最上層保持銳利。color 沒給就沿用原圖本身的顏色；
    # 給了則用 feFlood 固定成指定顏色。
    def to_def
      color = @color
      std_deviation = @std_deviation
      opacity = @opacity

      if color
        flood = <<~SVG.strip
          <feFlood flood-color="#{color}" flood-opacity="#{opacity}" result="color"/>
          <feComposite in="color" in2="blur" operator="in" result="glowColor"/>
        SVG
        merge_in = "glowColor"
      else
        flood = ""
        merge_in = "blur"
      end

      <<~SVG.strip
        <filter id="#{id}" x="-50%" y="-50%" width="200%" height="200%">
        <feGaussianBlur in="SourceGraphic" stdDeviation="#{std_deviation}" result="blur"/>
        #{flood}<feMerge>
        <feMergeNode in="#{merge_in}"/>
        <feMergeNode in="SourceGraphic"/>
        </feMerge>
        </filter>
      SVG
    end
  end
end
