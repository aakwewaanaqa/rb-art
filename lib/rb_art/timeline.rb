module RbArt
  # 一堆 Cue 的容器：Cue 只知道「我自己演到哪」，Timeline 知道「整齣戲多長、
  # 這一格該畫哪些東西、用什麼順序畫」。
  #
  #   timeline = RbArt::Timeline.new {
  #     fps 12
  #     grow = cue {
  #       duration 3.0
  #       cue { |temporal_t| vine.grown_to RbArt.ease_in_out(temporal_t) }
  #     }
  #     leaves.each { |leaf|
  #       cue {
  #         start    grow.time_at_length(leaf[:at])
  #         duration 0.4
  #         layer    1
  #         cue { |temporal_t| leaf.scaled RbArt.ease_in_out(temporal_t) }
  #       }
  #     }
  #     after(grow) { duration 0.5; cue { } }   # 結尾多停半拍
  #   }
  #
  #   RbArt::Animation.new {
  #     timeline timeline   # fps 跟 frames 都從 timeline 拿
  #     canvas { width 1000; height 1000 }
  #   }.render   # 不給 block，Animation 自動組 Canvas、畫 timeline 的內容
  #
  # 需要自訂每格畫法（例如要疊圖層以外的特殊處理）時，照舊自己給 render block：
  #
  #   RbArt::Animation.new {
  #     timeline timeline
  #   }.render { |i, _|
  #     RbArt::Canvas.new {
  #       timeline.draw_at_frame(i).each { |element| draw element }
  #     }
  #   }
  #
  # 總長度是算出來的（最晚結束的那個 cue），不是設定的——所以隨機生成的東西
  # （例如隨機分佈的葉子）多幾個少幾個都不用回頭改 frame 數。
  #
  # fps 設在這裡、由 Animation#timeline 去拿，而不是兩邊各設一次，是為了讓
  # 「秒 -> frame」的換算只有一個來源：所有 cue 都只講秒，整份專案只有這裡
  # 知道一秒是幾格。兩邊各設一次的話一旦不一致（這裡用 12fps 取樣、ffmpeg
  # 用 24fps 編碼）動畫就會快兩倍，而且不會報錯。
  class Timeline
    attr_reader :cues

    def fps(value = nil) = value.nil? ? @fps : (@fps = value)

    def initialize(&block)
      @cues = []
      @fps  = 24
      self.instance_eval(&block) if block_given?
    end

    # 排一個 cue，回傳建好的 Cue——接住它就能給別人當 after 的參照，或是
    # 問它 finish 是幾秒。
    def cue(&block)
      Cue.new(&block).tap { @cues << _1 }
    end

    # 排一個接在 other 結束之後的 cue。block 裡的 start 這時代表「比 other
    # 的結尾再晚幾秒」（不寫就是緊接著），所以 other 之後要整段往後挪時，
    # 不必手動去加減絕對秒數。
    def after(other, &block)
      cue(&block).tap { _1.start _1.start + other.finish }
    end

    # 整齣戲的長度（秒）：最晚結束的那個 cue 決定。
    def duration = @cues.map(&:finish).max || 0

    # 多算一格，讓最後一格剛好落在 duration 上——不然結尾狀態會永遠差一格
    # 演不完（例如葉子永遠縮放不到 1.0）。
    def frame_count(frames_per_second = @fps) = (duration * frames_per_second).ceil + 1

    def time_at_frame(frame, frames_per_second = @fps) = frame.fdiv(frames_per_second)

    # 這一刻要畫的東西，依 layer 由小到大排好（同 layer 維持排進來的順序）。
    #
    # 出場時間跟 z-order 是兩件事——藤蔓從頭演到尾、葉子中途才出場，但藤蔓
    # 得畫在葉子底下，所以不能照 cue 的時間順序畫。
    #
    # cue block 回傳陣列（例如一次兩片葉子）會被攤平；回 nil（還沒出場）會被丟掉。
    def draw_at(time)
      @cues
        .each_with_index
        .sort_by { |cue, idx| [cue.layer, idx] }
        .filter_map { |cue, _| cue.draw_at(time) }
        .flatten
        .compact
    end

    def draw_at_frame(frame, frames_per_second = @fps) = draw_at(time_at_frame(frame, frames_per_second))
  end
end
