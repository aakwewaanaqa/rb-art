module RbArt
  module Geometry
    class Polyline
      attr_reader :length, :acc_lengths, :count

      def points(array = nil)
        return @points if array.nil?

        @points = array
        @count  = array.length
        self._calculate_acc_lengths
        array
      end
      # 沿著 t_sampler（任何提供 point_at(functional_t) 的物件）取樣，
      # 讓相鄰點之間的實際距離逼近 interval（容許誤差 epsilon）。
      # 用二分搜尋在 [last_t, 1.0] 之間找下一個 t；一旦搜尋區間已經逼到終點
      # 且終點離上一點不到 interval，就直接用終點收尾並停止。
      def sample(t_sampler, interval, epsilon: 1, max_bisect_steps: 30)
        raise ArgumentError, "t_sampler does not respond to point_at" unless t_sampler.respond_to?(:point_at)

        pts  = [t_sampler.point_at(0.0)]
        last_t = 0.0

        while last_t < 1.0
          lo, hi = last_t, 1.0
          next_t = hi
          next_point = t_sampler.point_at(next_t)

          max_bisect_steps.times do
            mid       = lo.lerp(hi, 0.5)
            mid_point = t_sampler.point_at(mid)
            dist      = mid_point.dist(pts.last)
            next_t, next_point = mid, mid_point
            break if (dist - interval).abs <= epsilon
            dist > interval ? (hi = mid) : (lo = mid)
          end

          break if next_t >= 1.0 && next_point.dist(pts.last) < interval

          last_t = next_t
          pts << next_point
        end

        pts << t_sampler.point_at(1.0)
        self.points(pts)
      end
      def initialize(&block)
        self.instance_eval(&block)
      end

      def length_t_to_func_t(accumulated_length_t)
        acc = accumulated_length_t
        ceil_idx = @acc_lengths.bsearch_index { |len| len >= acc }
        return 1.0 if ceil_idx.nil?
        return 0.0 if ceil_idx == 0
        return ceil_idx.fdiv(@count) if acc_lengths[ceil_idx] == acc
        floor_idx = ceil_idx - 1
        ceil      = ceil_idx.fdiv(@count)
        ceil_len  = acc_lengths[ceil_idx]
        floor     = floor_idx.fdiv(@count)
        floor_len = acc_lengths[floor_idx]
        return floor.lerp(
          ceil,
          floor_len.dist(acc).fdiv(floor_len.dist(ceil_len))
        )
      end

      def take(accumulated_length_t)
        acc = accumulated_length_t
        idx = @acc_lengths.bsearch_index { |len| len >= acc }
        @points.take idx + 1
      end

      private
      def _calculate_acc_lengths
        return if @points.nil?
        @acc_lengths = @points.each_cons(2).reduce([0.0]) { |acc, (a, b)|
          acc << acc.last + a.dist(b)
        }
        @length = @acc_lengths.last
      end
    end
  end
end
