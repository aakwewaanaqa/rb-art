

module RbArt
  module Geometry
    module Rnd
      def self.inside_unit_circle(rng: Random)
        theta = rng.rand(Math::PI * 2.0)
        radius = rng.rand
        x = Math.sin theta
        y = Math.cos theta
        RbArt::Geometry::Point.new(x, y) * radius
      end
      def self.on_unit_circle
        theta = Random.rand(Math::PI * 2.0)
        x = Math.sin theta
        y = Math.cos theta
        RbArt::Geometry::Point.new(x, y)
      end

      # 按權重隨機取一個元素。items_with_weights 是 [item, weight] 的陣列，
      # weight 可以是任意正數（不必是整數），數字越大越容易被抽到。
      #
      #   Rnd.weighted_sample([["紅", 1], ["綠", 5], ["藍", 2]]) #=> 大機率是 "綠"
      def self.weighted_sample(items_with_weights)
        total = items_with_weights.sum { |_, w| w }
        r = Random.rand * total
        items_with_weights.each { |item, w|
          return item if r < w
          r -= w
        }
        items_with_weights.last&.first
      end
    end
  end
end