require_relative "point"

module RbArt
  module Geometry
    # 三次貝茲曲線，基於 blossom（極化形式）做任意切割。
    class CubicBezier
      attr_reader :p0, :p1, :p2, :p3

      def initialize(p0, p1, p2, p3)
        @p0, @p1, @p2, @p3 = p0, p1, p2, p3
      end

      # 把直線 p0->p1 包裝成 CubicBezier（控制點等距落在線上），
      # 這樣直線段跟曲線段可以用同一套 point_at/tangent_at/arc_length API 混著處理。
      def self.line(p0, p1) = CubicBezier.new(p0, p0.lerp(p1, 1.0 / 3), p0.lerp(p1, 2.0 / 3), p1)

      def point_at(t) = blossom(t, t, t)

      # blossom(x, y, z)：對稱、多重仿射，b(t,t,t) = 曲線在 t 的點。
      def blossom(x, y, z)
        s1 = x * (1 - y) * (1 - z) + (1 - x) * y * (1 - z) + (1 - x) * (1 - y) * z
        s2 = x * y * (1 - z) + x * (1 - y) * z + (1 - x) * y * z

        p0.scale((1 - x) * (1 - y) * (1 - z)) +
          p1.scale(s1) +
          p2.scale(s2) +
          p3.scale(x * y * z)
      end

      # 原始曲線 t ∈ [t0, t1] 這一段，回傳同樣是 CubicBezier 的子曲線。
      def segment(t0, t1)
        CubicBezier.new(
          blossom(t0, t0, t0),
          blossom(t0, t0, t1),
          blossom(t0, t1, t1),
          blossom(t1, t1, t1)
        )
      end

      # 在 t0 切一刀，回傳 [左段, 右段]，兩段都是 CubicBezier。
      def split_at(t0) = [segment(0, t0), segment(t0, 1)]

      # 依累積 t 節點切成多段，knots 需為遞增、頭尾為 0 與 1 的陣列。
      # 例如 [0, 0.25, 0.75, 1] 會切成三段。
      def split_at_knots(knots)
        knots.each_cons(2).map { |t0, t1| segment(t0, t1) }
      end

      # 依 t 參數空間上的長度比例切割，lengths 總和須為 1（例如蕨類遞減長度）。
      def split_by_lengths(lengths)
        knots = [0.0]
        lengths.each { |len| knots << knots.last + len }
        split_at_knots(knots)
      end

      # 等分成 n 段。
      def split_into(n) = split_at_knots((0..n).map { |i| i.fdiv(n) })

      # 弧長對應表：用折線逼近，回傳 [[t, 累積弧長], ...]（共 samples+1 筆，t 等距）。
      def arc_length_table(samples: 200)
        ts = (0..samples).map { |i| i.fdiv(samples) }
        pts = ts.map { |t| point_at(t) }
        lengths = [0.0]
        pts.each_cons(2) { |a, b| lengths << lengths.last + (b - a).length }
        ts.zip(lengths)
      end

      def arc_length(samples: 200) = arc_length_table(samples: samples).last[1]

      # 給定「曲線總長度」的累積比例（0~1），反查對應的 t（表格區間內線性插值）。
      def t_at_length_fraction(fraction, table: arc_length_table)
        target = fraction * table.last[1]
        i = table.index { |_, len| len >= target } || table.size - 1
        return table[i][0] if i == 0

        t0, l0 = table[i - 1]
        t1, l1 = table[i]
        return t0 if l1 == l0

        t0 + (t1 - t0) * (target - l0) / (l1 - l0)
      end

      # 依「實際弧長」比例切割（lengths 總和須為 1）。跟 split_by_lengths 不同：
      # split_by_lengths 是照 t 參數比例切，這個是照曲線在畫面上的真實長度比例切，
      # 能修正曲線速度不均勻造成的段落大小失真，但要花數值積分的成本（見 arc_length_table）。
      def split_by_arc_lengths(lengths, samples: 200)
        table = arc_length_table(samples: samples)
        knots = [0.0]
        cum = 0.0
        lengths.each { |len|
          cum += len
          knots << t_at_length_fraction(cum, table: table)
        }
        knots[-1] = 1.0
        split_at_knots(knots)
      end

      # 一階導數（切線方向量，非單位向量）：B'(t)。
      def derivative_at(t)
        mt = 1 - t
        (p1 - p0).scale(3 * mt * mt) +
          (p2 - p1).scale(6 * mt * t) +
          (p3 - p2).scale(3 * t * t)
      end

      # 二階導數：B''(t)。
      def second_derivative_at(t)
        (p2 - p1.scale(2) + p0).scale(6 * (1 - t)) +
          (p3 - p2.scale(2) + p1).scale(6 * t)
      end

      # 單位切線向量。
      def tangent_at(t) = derivative_at(t).normalize

      # 曲率 κ(t) = (x'y'' - y'x'') / |B'(t)|^3，符號代表彎的方向（正負對應左右轉）。
      def curvature_at(t)
        d1 = derivative_at(t)
        d2 = second_derivative_at(t)
        cross = d1.x * d2.y - d1.y * d2.x
        cross / (d1.length ** 3)
      end

      def to_a = [p0, p1, p2, p3]
    end
  end
end
