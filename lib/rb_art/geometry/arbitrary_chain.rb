require_relative "cumulative_locator"

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

      # functional_t 是跨整條 chain 的「索引 + 段內 t」組合（整數部分選段，小數
      # 部分是該段自己的 functional_t），不是依真實弧長等距——曲率不同或段落
      # 長度不同時，同樣的 functional_t 增量在畫面上對應的長度不會一樣。
      def item_at_functional_t(functional_t, &block)
        idx                 = functional_t.div(1)
        local_functional_t  = functional_t.modulo(1)
        item                = idx != count ? @items[idx] : @items.last

        block.(item, local_functional_t, idx)
      end

      def point_at functional_t
        idx                 = functional_t.div(1)
        local_functional_t  = functional_t.modulo(1)

        return @items[idx].point_at(local_functional_t) if idx != count
        return @items.last.point_at(1)
      end

      def normal_at functional_t
        idx                 = functional_t.div(1)
        local_functional_t  = functional_t.modulo(1)

        return @items[idx].normal_at(local_functional_t) if idx != count
        return @items.last.normal_at(1)
      end

      # 跨整條 chain 依「真實弧長」比例 spatial_t（0~1）找到對應的段落與段內
      # functional_t，修正各段曲率不同造成 point_at(functional_t) 在畫面上忽密
      # 忽疏的問題（跟 CubicBezier#split_by_spatial_lengths 是同一個道理，只是這裡
      # 是跨段查點而不是切割）。跟 CubicBezier#functional_t_at_spatial_t 一樣是
      # 「在累積弧長表裡定位 target」，只是這裡的累積表是段落長度而非取樣點，
      # 所以共用 CumulativeLocator。
      def item_at_spatial_t(spatial_t, &block)
        target = spatial_t * total_length
        idx, cum = CumulativeLocator.locate(segment_cumulative_lengths, target)
        len = segment_cumulative_lengths[idx] - cum

        local_spatial_t = len.zero? ? 0.0 : (target - cum) / len
        functional_t = @items[idx].functional_t_at_spatial_t(local_spatial_t, table: segment_tables[idx])
        block.(@items[idx], functional_t, idx)
      end

      def point_at_spatial_t(spatial_t)
        item_at_spatial_t(spatial_t) { |item, functional_t, _idx| item.point_at(functional_t) }
      end

      def total_length
        @total_length ||= segment_cumulative_lengths.last
      end

      private

      def segment_tables
        @segment_tables ||= @items.map(&:arc_length_table)
      end

      # 各段長度的累積和（絕對值，非比例），供 CumulativeLocator 在跨段查找時使用。
      def segment_cumulative_lengths
        @segment_cumulative_lengths ||= begin
          cum = 0.0
          segment_tables.map { |table| cum += table.last[1] }
        end
      end
    end
  end
end