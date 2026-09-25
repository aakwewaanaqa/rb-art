#!/usr/bin/env ruby

require_relative "../../lib/rb_art"

SFStyle = Struct.new(:stroke, :fill)

sf_styles = [
  SFStyle.new("#DBFD02", "#A8DF11"),
  SFStyle.new("#93BE1D", "#DBFD02"),
  SFStyle.new("#93BE1D", "#C7F251"),
  SFStyle.new("#A8DF11", "#93BE1D"),
  SFStyle.new("#81C217", "#C7F251"),
  SFStyle.new("#81C217", "#DBFD02"),
  SFStyle.new("#DBFD02", "#93BE1D"),
  SFStyle.new("#93BE1D", "#A8DF11"),
  SFStyle.new("#A8DF11", "#81C217"),
  SFStyle.new("#C7F251", "#93BE1D"),
]

animation = RbArt::Animation.new {
  frames 60
  scale 4
  mp4 "out/test.mp4"
  gif "out/test.gif"

  fps 3
}

animation.render { |i, total|
  RbArt::Canvas.new {
    width  200
    height 200
    background "#9ED06D"

    draw RbArt::Path.new {
      ellipse = RbArt::Geometry::Ellipse.new(cx: 100, cy: 100, rx: 25, ry: 25)

      rng = Random.new
      base = rng.rand(0.05..0.12)
      at = 0.0
      points = []
      while at < 1.0 && ((1.0 - at) > (base * 0.5))
        r = at * RbArt::Geometry::TWO_PI
        point = ellipse.point_at(r)
        normal = ellipse.normal_at(r).scale(rng.rand(10..20))
        points << (point + normal)
        at += rng.rand(base .. (base + 0.03))
      end

      center = RbArt::Geometry::Point.new(ellipse.cx, ellipse.cy)
      points.each_index { |i|
        m points[i] if i == 0

        previous_polygon = -> {
          f = points[i-1]
          t = points[i]
          n = outward_normal(f, t, center).scale((f - t).length)
          f_handle = f + n
          t_handle = t + n

          RbArt::Geometry::Polygon.new([f, f_handle, t_handle, t])
        }.()

        current_polygon = -> {
          f = points[i]
          t = points[(i + 1) % points.length]
          n = outward_normal(f, t, center).scale((f - t).length)

          f_handle = f + n
          f_2_f_handle_is_crossing =
            RbArt::Geometry.segments_intersect?(f, f_handle, previous_polygon[1], previous_polygon[2]) ||
            previous_polygon.include?(f_handle)
          if f_2_f_handle_is_crossing
            r = (previous_polygon[2] - previous_polygon[3]).normalize
            f_handle = f + r.scale((f_handle - f).length)
          end

          t_handle = t + n
          if previous_polygon.include?(t_handle)
            t_handle = previous_polygon.closest_point(t_handle).first
          end

          RbArt::Geometry::Polygon.new([f, f_handle, t_handle, t])
        }.()

        c current_polygon[1], current_polygon[2], current_polygon[3]
      }
      z

      sf = sf_styles.sample

      stroke sf.stroke
      fill sf.fill
      stroke_width "4pt"
      attr "stroke-linejoin", "round"
    }
  }
}

animation.write_mp4
animation.write_gif
