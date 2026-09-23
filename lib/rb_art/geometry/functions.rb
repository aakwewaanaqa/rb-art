require_relative "point"

module RbArt
  module Geometry
    module_function

    # p1 -> p2 這條邊的垂直單位法向量，方向挑選遠離 center 的那一側。
    # 作法：把邊向量旋轉 90 度得到候選法向量，再用「邊中點 - center」
    # 的方向跟候選法向量做內積，內積為負就代表選錯邊，取反方向即可。
    def outward_normal(p1, p2, center)
      edge = p2 - p1
      candidate = Point.new(-edge.y, edge.x).normalize

      mid = Point.new((p1.x + p2.x) / 2.0, (p1.y + p2.y) / 2.0)
      to_mid = mid - center

      candidate.dot(to_mid) < 0 ? candidate.scale(-1) : candidate
    end

    # 點 p 到線段 a-b 上最近的點。
    def closest_point_on_segment(p, a, b)
      edge = b - a
      len_sq = edge.dot(edge)
      return a if len_sq.zero?

      t = (p - a).dot(edge).fdiv(len_sq)
      t = t.clamp(0.0, 1.0)
      a + edge.scale(t)
    end

    # p, q, r 三點的轉向：0 共線、1 順時針、2 逆時針。
    def orientation(p, q, r)
      val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
      return 0 if val.zero?

      val.positive? ? 1 : 2
    end

    # 已知 p、q、r 共線，判斷 q 是否落在線段 p-r 的邊界盒內。
    def on_segment?(p, q, r)
      q.x.between?([p.x, r.x].min, [p.x, r.x].max) &&
        q.y.between?([p.y, r.y].min, [p.y, r.y].max)
    end

    # 線段 p1-q1 與 p2-q2 是否相交（含共線重疊、端點相觸）。
    def segments_intersect?(p1, q1, p2, q2)
      o1 = orientation(p1, q1, p2)
      o2 = orientation(p1, q1, q2)
      o3 = orientation(p2, q2, p1)
      o4 = orientation(p2, q2, q1)

      return true if o1 != o2 && o3 != o4

      return true if o1.zero? && on_segment?(p1, p2, q1)
      return true if o2.zero? && on_segment?(p1, q2, q1)
      return true if o3.zero? && on_segment?(p2, p1, q2)
      return true if o4.zero? && on_segment?(p2, q1, q2)

      false
    end

    # 給一個「局部座標系」(root 為原點、direction 為前方 u 軸、其左手法向為 v 軸)
    # 跟一個曲率 curvature（= 1/半徑，正負決定往左或往右彎、0 代表不彎），
    # 回傳一個 (u, v) -> Point 的函式：把「直線局部座標」的點彎成沿圓弧分布。
    # u 是沿弧長走多遠，v 是沿彎曲後法線方向的側向偏移（正值 = 往 left 那側）。
    #
    # 推導：把 direction 沿弧長積分即可得到彎曲後的中心線公式
    #   center_line(u) = root - r*left + r*left.rotate(curvature*u)  (r = 1/curvature)
    # 再加上側向偏移 v（同樣隨角度一起轉）就是完整公式。
    def bend_frame(root, direction, curvature)
      d = direction.normalize
      left = d.rotate(-Math::PI / 2)
      return ->(u, v) { root + d * u + left * v } if curvature.zero?

      r = 1.0 / curvature
      ->(u, v) do
        theta = curvature * u
        left_theta = left.rotate(theta)
        root - left * r + left_theta * (r + v)
      end
    end
  end
end
