module RbArt
  module Geometry
    class ArbitraryChain
      def count
        @items.length
      end
      def items v
        v.nil? ? @items : (@items = v)
      end

      def initialize(&block)
        self.instance_eval(&block)
      end

      def item_t_with_index(t, &block)
        idx  = t.div(1)
        t    = t.modulo(1)
        item = idx != count ? @items[idx] : @items.last

        block.(item, t, idx)
      end

      def point_at t
        idx = t.div(1)
        t   = t.modulo(1)

        return @items[idx].point_at(t) if idx != count
        return @items.last.point_at(1)
      end

      def normal_at t
        idx = t.div(1)
        t   = t.modulo(1)

        return @items[idx].normal_at(t) if idx != count
        return @items.last.normal_at(1)
      end

      # 跨整條 chain 依「真實弧長」比例（0~1）找到對應的段落與段內 t，
      # 修正各段曲率不同造成 point_at(t) 在畫面上忽密忽疏的問題
      # （跟 CubicBezier#split_by_arc_lengths 是同一個道理，只是這裡是跨段查點而不是切割）。
      def item_length_fraction_with_index(fraction, &block)
        target = fraction * total_length
        cum = 0.0

        segment_tables.each_with_index { |table, idx|
          len = table.last[1]

          if idx == segment_tables.size - 1 || target <= cum + len
            local_fraction = len.zero? ? 0.0 : (target - cum) / len
            t = @items[idx].t_at_length_fraction(local_fraction, table: table)
            return block.(@items[idx], t, idx)
          end

          cum += len
        }
      end

      def point_at_length_fraction(fraction)
        item_length_fraction_with_index(fraction) { |item, t, _idx| item.point_at(t) }
      end

      def total_length
        @total_length ||= segment_tables.sum { |table| table.last[1] }
      end

      private

      def segment_tables
        @segment_tables ||= @items.map(&:arc_length_table)
      end
    end
  end
end