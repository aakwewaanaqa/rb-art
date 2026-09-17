#!/usr/bin/env ruby

require_relative "../lib/rb_art"

width  = 1080
height = 1920

RbArt::Canvas.new {
  width  width
  height height
  svg "out/curtain_#{width}x#{height}.svg"

  curtain_gradient = linear_gradient(stops: ["#1B1F3B", "#6C3AC7"])

  draw RbArt::Path.new {
    m 0, 0
    l 0, height

    ripple_count = 10
    (0...ripple_count).each { |i|
      x_from = width * i / ripple_count.to_f
      x_to   = width * (i + 1) / ripple_count.to_f
      depth  = height - width / ripple_count / 2.0

      f_handle = RbArt::Geometry::Point.new(x_from, depth)
      t_handle = RbArt::Geometry::Point.new(x_to, depth)
      t        = RbArt::Geometry::Point.new(x_to, height)

      c f_handle, t_handle, t
    }

    l width, 0
    z

    fill curtain_gradient
  }
}