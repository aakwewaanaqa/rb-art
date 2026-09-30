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
      # 是跨段查點而不是切割）。
      def item_at_spatial_t(spatial_t, &block)
        target = spatial_t * total_length
        cum = 0.0

        segment_tables.each_with_index { |table, idx|
          len = table.last[1]

          if idx == segment_tables.size - 1 || target <= cum + len
            local_spatial_t = len.zero? ? 0.0 : (target - cum) / len
            functional_t = @items[idx].functional_t_at_spatial_t(local_spatial_t, table: table)
            return block.(@items[idx], functional_t, idx)
          end

          cum += len
        }
      end

      def point_at_spatial_t(spatial_t)
        item_at_spatial_t(spatial_t) { |item, functional_t, _idx| item.point_at(functional_t) }
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