require_relative "point"
require_relative "bezier"
require_relative "arbitrary_chain"

module RbArt
  module Geometry
    # 把 SVG path 的 d 字串解析成 Geometry 物件，讓外部來的輪廓（例如
    # text2path 轉出的字形、Affinity 匯出的路徑）也能取樣、量弧長、求法線。
    #
    # 每條子路徑（M 開頭的一段）變成一個 ArbitraryChain，所有線段一律統一成
    # CubicBezier：L/H/V 走 CubicBezier.line、Q/T 走 CubicBezier.quadratic、
    # S/T 的隱含控制點先鏡射算出來，相對座標也在這裡轉成絕對座標。
    # Z 會補一段直線回到起點（已經在起點就不補），並把 chain 標成 closed。
    #
    #   chains = PathData.parse("M0 0 L10 0 Q10 10 0 10 Z")
    #   chains.first.point_at_spatial_t(0.5)
    #
    # A（橢圓弧）沒辦法精確轉成貝茲，目前遇到會直接報錯。
    module PathData
      COMMAND = /[MmLlHhVvCcSsQqTtAaZz]/
      NUMBER  = /[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?/
      TOKEN   = Regexp.union(COMMAND, NUMBER)

      # 每個指令一次吃幾個數字，同一個指令後面接更多數字就是重複同一指令。
      ARITY = { "M" => 2, "L" => 2, "H" => 1, "V" => 1, "C" => 6, "S" => 4, "Q" => 4, "T" => 2, "A" => 7, "Z" => 0 }.freeze

      def self.parse(d) = Parser.new(d).parse
    end
  end
end

require_relative "path_data/parser"
