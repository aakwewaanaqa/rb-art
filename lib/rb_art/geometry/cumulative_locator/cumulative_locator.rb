module RbArt
  module Geometry
    # 在遞增的「累積量」陣列（如累積弧長）中定位 target 落在哪一段。
    # 回傳 [index, index 之前的累積值]：target 落在 (cums[index-1], cums[index]] 區間，
    # 超出最後一筆時夾住回傳最後一個 index。
    #
    # CubicBezier#functional_t_at_spatial_t（單條曲線的取樣點累積弧長表）跟
    # ArbitraryChain#item_at_spatial_t（chain 跨段的累積弧長）本質上是同一種查找，
    # 只是作用的累積表層級不同，統一用這個 helper 避免重複實作。
    module CumulativeLocator
      def self.locate(cums, target)
        idx = cums.index { |c| c >= target } || cums.size - 1
        prev = idx.zero? ? 0.0 : cums[idx - 1]
        [idx, prev]
      end
    end
  end
end
