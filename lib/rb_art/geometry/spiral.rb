require_relative "point"

module RbArt
  module Geometry
    class Spiral
      def center(p = nil) p ? (@center = p) : @center end
      def rotation(f) @rotation = f end
      def radius(f) @radius = f end
      def end_radius(f) @end_radius = f end
      def end_rotation(f) @end_rotation = f end
      def initialize(&block)
        self.instance_eval(&block)
        @center           = RbArt.unpack_param! @center       || RbArt::Geometry::Point.new(0, 0)
        @rotation         = RbArt.unpack_param! @rotation     || 0
        @radius           = RbArt.unpack_param! @radius       || 0
        @end_radius       = RbArt.unpack_param! @end_radius   || 0
        @end_rotation     = RbArt.unpack_param! @end_rotation || Math::PI * 2
      end

      def point_at(t)
        rotation = @rotation.lerp(@end_rotation, t)
        radius   = @radius.lerp(@end_radius, t)
        RbArt::Geometry::Point.new(
          Math.cos(rotation),
          Math.sin(rotation)
        ) * radius + @center
      end

      def tangent_at(t)
        rotation = @rotation.lerp(@end_rotation, t)
        RbArt::Geometry::Point.new(
          -Math.sin(rotation),
          Math.cos(rotation)
        )
      end
    end
  end
end
