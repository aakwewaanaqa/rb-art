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

      def point_at(functional_t) = blossom(functional_t, functional_t, functional_t)

      # blossom(x, y, z)：對稱、多重仿射，b(t,t,t) = 曲線在 t 的點。
      def blossom(x, y, z)
        s1 = x * (1 - y) * (1 - z) + (1 - x) * y * (1 - z) + (1 - x) * (1 - y) * z
        s2 = x * y * (1 - z) + x * (1 - y) * z + (1 - x) * y * z

        p0.scale((1 - x) * (1 - y) * (1 - z)) +
          p1.scale(s1) +
          p2.scale(s2) +
          p3.scale(x * y * z)
      end

      # 原始曲線 functional_t ∈ [functional_t0, functional_t1] 這一段，回傳同樣是 CubicBezier 的子曲線。
      def segment(functional_t0, functional_t1)
        CubicBezier.new(
          blossom(functional_t0, functional_t0, functional_t0),
          blossom(functional_t0, functional_t0, functional_t1),
          blossom(functional_t0, functional_t1, functional_t1),
          blossom(functional_t1, functional_t1, functional_t1)
        )
      end

      # 在 functional_t 切一刀，回傳 [左段, 右段]，兩段都是 CubicBezier。
      def split_at(functional_t) = [segment(0, functional_t), segment(functional_t, 1)]

      # 依累積 functional_t 節點切成多段，knots 需為遞增、頭尾為 0 與 1 的陣列。
      # 例如 [0, 0.25, 0.75, 1] 會切成三段。
      def split_at_knots(functional_knots)
        functional_knots.each_cons(2).map { |functional_t0, functional_t1| segment(functional_t0, functional_t1) }
      end

      # 依 functional_t 參數空間上的長度比例切割，lengths 總和須為 1（例如蕨類遞減長度）。
      # 跟 split_by_spatial_lengths 不同：這裡切的是參數空間，不是真實弧長，曲率不均勻時
      # 切出來的段落在畫面上長度會不一致。
      def split_by_functional_lengths(functional_lengths)
        knots = [0.0]
        functional_lengths.each { |len| knots << knots.last + len }
        split_at_knots(knots)
      end

      # 等分成 n 段。
      def split_into(n) = split_at_knots((0..n).map { |i| i.fdiv(n) })

      # 弧長對應表：用折線逼近，回傳 [[t, 累積弧長], ...]（共 samples+1 筆，t 等距）。
      # 回傳 [[functional_t, 累積弧長], ...]（共 samples+1 筆，functional_t 等距）。
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
        i = table.index { |_, len| len >= target } || table.size - 1
        return table[i][0] if i == 0

        functional_t0, l0 = table[i - 1]
        functional_t1, l1 = table[i]
        return functional_t0 if l1 == l0

        functional_t0 + (functional_t1 - functional_t0) * (target - l0) / (l1 - l0)
      end

      # 依「實際弧長」比例切割（spatial_lengths 總和須為 1）。跟 split_by_functional_lengths 不同：
      # split_by_functional_lengths 是照 functional_t 參數比例切，這個是照曲線在畫面上的真實長度比例切，
      # 能修正曲線速度不均勻造成的段落大小失真，但要花數值積分的成本（見 arc_length_table）。
      def split_by_spatial_lengths(spatial_lengths, samples: 200)
        table = arc_length_table(samples: samples)
        knots = [0.0]
        cum = 0.0
        spatial_lengths.each { |len|
          cum += len
          knots << functional_t_at_spatial_t(cum, table: table)
        }
        knots[-1] = 1.0
        split_at_knots(knots)
      end

      # 一階導數（切線方向量，非單位向量）：B'(functional_t)。
      def derivative_at(functional_t)
        mt = 1 - functional_t
        (p1 - p0).scale(3 * mt * mt) +
          (p2 - p1).scale(6 * mt * functional_t) +
          (p3 - p2).scale(3 * functional_t * functional_t)
      end

      # 二階導數：B''(functional_t)。
      def second_derivative_at(functional_t)
        (p2 - p1.scale(2) + p0).scale(6 * (1 - functional_t)) +
          (p3 - p2.scale(2) + p1).scale(6 * functional_t)
      end

      # 單位切線向量。
      def tangent_at(functional_t) = derivative_at(functional_t).normalize

      # 單位法線向量（切線逆時針轉 90 度，哪一側是「外側」要看點序自行判斷）。
      def normal_at(functional_t) = tangent_at(functional_t).rotate(Math::PI / 2)

      # 曲率 κ(functional_t) = (x'y'' - y'x'') / |B'(functional_t)|^3，符號代表彎的方向（正負對應左右轉）。
      def curvature_at(functional_t)
        d1 = derivative_at(functional_t)
        d2 = second_derivative_at(functional_t)
        cross = d1.x * d2.y - d1.y * d2.x
        cross / (d1.length ** 3)
      end

      def to_a = [p0, p1, p2, p3]

      # 用 Catmull-Rom spline 平滑通過給定的一串點，轉成首尾相接的 CubicBezier 陣列
      # （每個原始點都會被曲線精準通過，不像 t()/T 那樣只是鏡射前一段控制點）。
      # tension 越大曲線越貼近原始折線（更「緊」），預設 1.0 是標準 Catmull-Rom。
      # closed: true 頭尾相接成封閉曲線（首尾也會平滑銜接）。
      def self.catmull(points, tension: 1.0, closed: false)
        raise ArgumentError, "at least 2 points required" if points.size < 2
        return [line(points[0], points[1])] if points.size == 2

        n = points.size
        at = ->(i) { closed ? points[i % n] : points[i.clamp(0, n - 1)] }
        segments = closed ? (0...n) : (0...(n - 1))

        segments.map { |i|
          p0, p1, p2, p3 = at.(i - 1), at.(i), at.(i + 1), at.(i + 2)

          c1 = p1 + (p2 - p0).scale(1.0 / (6 * tension))
          c2 = p2 - (p3 - p1).scale(1.0 / (6 * tension))

          CubicBezier.new(p1, c1, c2, p2)
        }
      end
    end
  end
end
