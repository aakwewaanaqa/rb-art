require_relative "../point"
require_relative "../bezier"
require_relative "../arbitrary_chain"

module RbArt
  module Geometry
    module PathData
      class Parser
        def initialize(d)
          @tokens = d.scan(TOKEN)
          @chains = []
          @segments = []
          @current = @start = Point.new(0, 0)
          @last_cubic_ctrl = @last_quad_ctrl = nil
          @closed = false
        end

        def parse
          cmd = nil
          until @tokens.empty?
            if @tokens.first.match?(COMMAND)
              cmd = @tokens.shift
            elsif cmd.nil? || cmd.upcase == "Z"
              raise ArgumentError, "path data 在 #{@tokens.first} 之前缺少指令"
            end

            execute(cmd, take(ARITY[cmd.upcase]))
            # M 後面多出來的座標對是隱含的 L（大小寫跟著 M）
            cmd = cmd == "M" ? "L" : "l" if cmd.upcase == "M"
          end
          flush
          @chains
        end

        private

        def take(n)
          raise ArgumentError, "path data 數字不足" if @tokens.size < n

          nums = @tokens.shift(n)
          raise ArgumentError, "path data 參數不是數字：#{nums.inspect}" unless nums.all? { |t| t.match?(NUMBER) }

          nums.map(&:to_f)
        end

        def execute(cmd, args)
          relative = cmd == cmd.downcase
          # H/V 只有單軸數值、A 的參數不是座標對，這幾個在 case 裡自己處理
          pts = %w[H V A].include?(cmd.upcase) ? [] :
            args.each_slice(2).map { |x, y| relative ? @current + Point.new(x, y) : Point.new(x, y) }
          cubic_ctrl = quad_ctrl = nil

          case cmd.upcase
          when "M"
            flush
            @current = @start = pts[0]
          when "L"
            line_to(pts[0])
          when "H"
            line_to(Point.new(relative ? @current.x + args[0] : args[0], @current.y))
          when "V"
            line_to(Point.new(@current.x, relative ? @current.y + args[0] : args[0]))
          when "C"
            add(CubicBezier.new(@current, *pts))
            cubic_ctrl = pts[1]
          when "S"
            c1 = @last_cubic_ctrl ? @current.reflect(@last_cubic_ctrl) : @current
            add(CubicBezier.new(@current, c1, *pts))
            cubic_ctrl = pts[0]
          when "Q"
            add(CubicBezier.quadratic(@current, *pts))
            quad_ctrl = pts[0]
          when "T"
            q = @last_quad_ctrl ? @current.reflect(@last_quad_ctrl) : @current
            add(CubicBezier.quadratic(@current, q, pts[0]))
            quad_ctrl = q
          when "Z"
            line_to(@start) unless @current.dist(@start) < 1e-9
            @closed = true
            flush
          when "A"
            raise NotImplementedError, "PathData 尚未支援 A（橢圓弧）指令"
          end

          # S / T 只在緊接著同類曲線時才鏡射前一個控制點，其他指令會清掉
          @last_cubic_ctrl = cubic_ctrl
          @last_quad_ctrl  = quad_ctrl
        end

        def line_to(point) = add(CubicBezier.line(@current, point))

        def add(bezier)
          @segments << bezier
          @current = bezier.p3
        end

        # 收掉目前的子路徑。Z 之後 current 回到起點，下一條子路徑沒寫 M
        # 也會從這裡接著畫（SVG 規範）。只有 M、沒有線段的子路徑直接丟掉。
        def flush
          unless @segments.empty?
            segs, is_closed = @segments, @closed
            @chains << ArbitraryChain.new { items segs; closed is_closed }
          end
          @segments = []
          @closed = false
          @current = @start
        end
      end
    end
  end
end
