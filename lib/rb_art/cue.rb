module RbArt
  # 一段動畫：在 [start, finish] 這段時間內，把 0..1 的 temporal_t 餵給 cue block。
  #
  # temporal_t 是「時間軸上的局部進度」，跟 Geometry 那兩種 t 是不同東西——
  # functional_t 是參數空間、spatial_t 是真實弧長比例，都在描述形狀上的位置；
  # temporal_t 只描述這段動畫自己演到哪，與幾何無關。藤蔓生長那種 cue 會把三者
  # 串起來（temporal_t -> easing -> spatial_t -> functional_t -> point_at），
  # 葉子縮放那種則是 temporal_t 直接當 scale 用。
  #
  #   cue = RbArt::Cue.new {
  #     start    0.5
  #     duration 0.4
  #     cue { |temporal_t| leaf.scaled RbArt.ease_in_out(temporal_t) }
  #   }
  #   cue.draw_at(0.6)
  #
  # cue block 的回傳值最後會被餵給 Canvas#draw，必須是以下三種之一（搭配
  # Timeline 使用時，Timeline#draw_at 會 flatten + compact，所以陣列、nil
  # 混在一起也沒問題）：
  #   - nil（這一格不畫任何東西）
  #   - 回應 to_svg 的物件（例如 RbArt::Path、RbArt::Leaf），或是現成的 SVG 字串
  #   - 以上兩種的陣列（例如一次回傳兩片葉子）
  # Canvas#draw 對不符合這個約定的值不會 raise——它只檢查 respond_to?(:to_svg)，
  # 沒有就直接塞進 @elements，到了 Canvas#to_svg 做 join("\n") 時才用 to_s
  # 硬轉成字串。結果是最難抓的那種 bug：畫面空白或冒出奇怪的字串，但程式
  # 完全不會停下來告訴你哪裡錯——所以這個約定只能人工遵守，debug 時先懷疑
  # 這裡。
  # 時間單位是「秒」而不是 frame，所以同一組 cue 換 fps 不用重算；要換算成
  # frame 數交給 Timeline#frame_count。
  #
  # 用 duration 而不是結束時間，是為了讓整段 cue 之後要往後搬（延後出場）時
  # 只改 start 就好，不必連著重算結尾。
  class Cue
    def start   (value = nil) = value.nil? ? @start    : (@start    = value)
    def duration(value = nil) = value.nil? ? @duration : (@duration = value)
    def cue     (&block)      = block.nil? ? @cue      : (@cue      = block)
    def layer   (value = nil) = value.nil? ? @layer    : (@layer    = value)

    def initialize(&block)
      self.instance_eval(&block) if block_given?
      @start    = RbArt.unpack_param! @start || 0
      @duration = RbArt.unpack_param! @duration
      @layer    = RbArt.unpack_param! @layer || 0
      raise ArgumentError, "cue 沒設定要畫什麼：請在設定區塊呼叫 cue { |temporal_t| ... }" unless @cue
    end

    def finish = @start + @duration

    # 時間還沒到回 nil（代表這一格根本不要畫），演完了回 1.0（維持結尾狀態）。
    #
    # 回 nil 而不是 0.0，是為了讓「還沒出場」跟「出場但進度為 0」能分辨——
    # 不然每個 cue block 都得自己判斷要不要畫。
    def temporal_t_at(time)
      return nil if time < @start
      return 1.0 if time >= finish
      (time - @start).fdiv(@duration)
    end

    # 回傳 cue block 的結果（通常是要畫的圖形），還沒出場就回 nil。
    def draw_at(time)
      temporal_t = temporal_t_at(time)
      temporal_t && @cue.(temporal_t)
    end
  end
end
