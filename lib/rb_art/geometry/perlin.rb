module RbArt
  module Geometry
    # 2D Perlin noise（classic gradient noise），輸出範圍約在 -1..1。
    # 同一個 seed、同樣的座標永遠拿到同樣的值。適合拿來做風吹擺動：
    # 把一維當空間（鄰近位置的植株擺動會互相關聯、不會各自亂跳），
    # 另一維當時間（phase），noise(x, t) 就會隨 t 平滑漂移。
    class Perlin
      def initialize(seed: Random.new_seed)
        rng = Random.new(seed)
        perm = (0...256).to_a.shuffle(random: rng)
        @perm = perm + perm
      end

      def noise(x, y)
        xi = x.floor & 255
        yi = y.floor & 255
        xf = x - x.floor
        yf = y - y.floor

        u = fade(xf)
        v = fade(yf)

        aa = @perm[@perm[xi] + yi]
        ab = @perm[@perm[xi] + yi + 1]
        ba = @perm[@perm[xi + 1] + yi]
        bb = @perm[@perm[xi + 1] + yi + 1]

        x1 = lerp(grad(aa, xf, yf), grad(ba, xf - 1, yf), u)
        x2 = lerp(grad(ab, xf, yf - 1), grad(bb, xf - 1, yf - 1), u)

        lerp(x1, x2, v)
      end

      # 3D 版本：多一維可以拿來繞成一個圓（cos(t)*r, sin(t)*r），
      # t: 0..2π 走一圈時輸入座標會回到起點，noise 也就跟著無縫循環，
      # 不用像 ping-pong 那樣靠「原路播放回去」硬接。
      def noise3(x, y, z)
        xi = x.floor & 255
        yi = y.floor & 255
        zi = z.floor & 255
        xf = x - x.floor
        yf = y - y.floor
        zf = z - z.floor

        u = fade(xf)
        v = fade(yf)
        w = fade(zf)

        aaa = @perm[@perm[@perm[xi] + yi] + zi]
        aba = @perm[@perm[@perm[xi] + yi + 1] + zi]
        aab = @perm[@perm[@perm[xi] + yi] + zi + 1]
        abb = @perm[@perm[@perm[xi] + yi + 1] + zi + 1]
        baa = @perm[@perm[@perm[xi + 1] + yi] + zi]
        bba = @perm[@perm[@perm[xi + 1] + yi + 1] + zi]
        bab = @perm[@perm[@perm[xi + 1] + yi] + zi + 1]
        bbb = @perm[@perm[@perm[xi + 1] + yi + 1] + zi + 1]

        x1 = lerp(grad3(aaa, xf, yf, zf), grad3(baa, xf - 1, yf, zf), u)
        x2 = lerp(grad3(aba, xf, yf - 1, zf), grad3(bba, xf - 1, yf - 1, zf), u)
        y1 = lerp(x1, x2, v)

        x1 = lerp(grad3(aab, xf, yf, zf - 1), grad3(bab, xf - 1, yf, zf - 1), u)
        x2 = lerp(grad3(abb, xf, yf - 1, zf - 1), grad3(bbb, xf - 1, yf - 1, zf - 1), u)
        y2 = lerp(x1, x2, v)

        lerp(y1, y2, w)
      end

      private

      def fade(t) = t * t * t * (t * (t * 6 - 15) + 10)
      def lerp(a, b, t) = a + t * (b - a)

      def grad(hash, x, y)
        case hash & 3
        when 0 then  x + y
        when 1 then -x + y
        when 2 then  x - y
        else         -x - y
        end
      end

      def grad3(hash, x, y, z)
        h = hash & 15
        u = h < 8 ? x : y
        v = h < 4 ? y : (h == 12 || h == 14 ? x : z)
        (h.even? ? u : -u) + ((h & 2).zero? ? v : -v)
      end
    end
  end
end
