require_relative "point"

module RbArt
  module Geometry
    # Bridson's algorithm：在矩形範圍內取樣一批「彼此間距至少 radius」
    # 但整體看起來仍是隨機分佈的點（blue noise），比規則網格自然，
    # 又比純隨機撒點更均勻（不會擠成一團或留大片空白）。
    #
    #   points = RbArt::Geometry::PoissonDisc.sample(width: 500, height: 500, radius: 60)
    module PoissonDisc
      # width/height：取樣範圍。radius：任兩點最小間距。
      # k：每個活躍點嘗試生出新候選點的次數，越大越密實但越慢，30 是原論文建議值。
      def self.sample(width:, height:, radius:, k: 30)
        cell_size = radius / Math.sqrt(2)
        grid_w = (width / cell_size).ceil
        grid_h = (height / cell_size).ceil
        grid = Array.new(grid_w * grid_h)

        cell_of = ->(p) { [(p.x / cell_size).floor, (p.y / cell_size).floor] }
        in_bounds = ->(p) { p.x >= 0 && p.x < width && p.y >= 0 && p.y < height }

        fits = ->(p) {
          cx, cy = cell_of.(p)
          (-2..2).each { |dx|
            (-2..2).each { |dy|
              gx, gy = cx + dx, cy + dy
              next if gx < 0 || gx >= grid_w || gy < 0 || gy >= grid_h

              other = grid[gy * grid_w + gx]
              next unless other

              return false if (other - p).length < radius
            }
          }
          true
        }

        samples = []
        active = []

        first = Point.new(Random.rand * width, Random.rand * height)
        samples << first
        active << first
        cx, cy = cell_of.(first)
        grid[cy * grid_w + cx] = first

        until active.empty?
          p = active.sample
          placed = false

          k.times {
            theta = Random.rand(Math::PI * 2)
            r = radius * (1 + Random.rand)
            candidate = p + Point.new(Math.cos(theta), Math.sin(theta)) * r

            next unless in_bounds.(candidate) && fits.(candidate)

            samples << candidate
            active << candidate
            gx, gy = cell_of.(candidate)
            grid[gy * grid_w + gx] = candidate
            placed = true
            break
          }

          active.delete(p) unless placed
        end

        samples
      end
    end
  end
end
