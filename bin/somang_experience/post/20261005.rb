require_relative "ref"
ref

module RbArt
  class GloryRay
    def center(p) @center = p end
    def radius(p) @radius = p end
    def rotation(f) @rotation = f end
    def division_count(i) @divion_count = i end
    def style(h) @style = h end
    def initialize(&block) self.instance_eval(&block) end
    def to_svg
      division_count = @divion_count
      center = @center
      radius = @radius
      single_arc_rotation = RbArt::TwoPi.fdiv(division_count)
      style = @style

      (0...division_count).to_a.map { |idx|
        start_angle = single_arc_rotation * idx
        s = center + RbArt::Geometry::Point.new(Math.cos(start_angle), Math.sin(start_angle)) * radius

        end_angle = single_arc_rotation * (idx + 1)
        t = center + RbArt::Geometry::Point.new(Math.cos(end_angle), Math.sin(end_angle)) * radius

        is_greater_arc = single_arc_rotation > Math::PI ? 1 : 0
        RbArt::Path.new {
          style style

          m center
          l s
          a radius, radius, 0, is_greater_arc, 1, t.x, t.y
          l center
          z
        }
      }
    end
  end
end

CanvasWidth = 500
CanvasHeight = 500
CanvasCenter = RbArt::Geometry::Point.new(
  CanvasWidth.fdiv(2),
  CanvasHeight.fdiv(2),
)
FrameCount = 180
BurstInterval = 10..20
StarPerBusrt = (5..10)
StarVelocity = (10..30)
FrameIndicesOfBurst = -> {
  bursts = []
  interval = RbArt.unpack_param! BurstInterval
  at = 0
  until at > FrameCount
    at = at + interval
    bursts << at
  end

  bursts
}.()

stars = []
RbArt::Animation.new {
  frames FrameCount
  dir "out/post/20261005"
  gif "out/post/20261005.gif"
  mp4 "out/post/20261005.mp4"
  fps 60
}.render { |i, total|
  if FrameIndicesOfBurst.include? i
    (RbArt.unpack_param! StarPerBusrt).times {
      colors = RbArt::GrassColors.sample 2
      style = {
        stroke: colors[0],
        fill: colors[1],
        stroke_width: "4pt"
      }
      stars << {
        velocity: RbArt::Geometry::Rnd.on_unit_circle * RbArt.unpack_param!(StarVelocity),
        star: RbArt::Star.new {
          rotation Random.rand * 2 * Math::PI
          center CanvasCenter
          radius (30..100)
          pointiness (0.5..0.7).step(0.01)
          edge_count (5..7)
          style style
        }
      }
    }
  end

  stars.each { |star|
    star[:star].translate star[:velocity] 
  }

  RbArt::Canvas.new {
    width  CanvasWidth
    height CanvasHeight
    background RbArt::BackgroundColor

    stars.each { |star|
      draw star[:star]
    }
  }
}