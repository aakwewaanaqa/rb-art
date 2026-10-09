require_relative "cumulative_locator"

module RbArt
  module Geometry
    # 給任何提供 point_at(functional_t)（functional_t ∈ [0,1]）的類別 include，
    # 用折線逼近提供弧長查表、總長度，以及 functional_t ↔ spatial_t 的互查。
    module ArcLength
      # 弧長對應表：用折線逼近，回傳 [[functional_t, 累積弧長], ...]（共 samples+1 筆，functional_t 等距）。
      def arc_length_table(samples: 200)
        functional_ts = (0..samples).map { |i| i.fdiv(samples) }
        pts = functional_ts.map { |functional_t| point_at(functional_t) }
        lengths = [0.0]
        pts.each_cons(2) { |a, b| lengths << lengths.last + (b - a).length }
        functional_ts.zip(lengths)
      end

      def arc_length(samples: 200) = arc_length_table(samples: samples).last[1]

      # 給定「曲線總長度」的累積比例 spatial_t（0~1，真實弧長意義下等距），
      # 反查對應的 functional_t（表格區間內線性插值）。
      def functional_t_at_spatial_t(spatial_t, table: arc_length_table)
        target = spatial_t * table.last[1]
        cums = table.map { |_, len| len }
        idx, l0 = CumulativeLocator.locate(cums, target)
        return table[idx][0] if idx.zero?

        functional_t0, _ = table[idx - 1]
        functional_t1, l1 = table[idx]
        return functional_t0 if l1 == l0

        functional_t0 + (functional_t1 - functional_t0) * (target - l0) / (l1 - l0)
      end
    end
  end
end
