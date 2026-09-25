require_relative "ref"
ref || exit(155)

require_relative "20260925"
require 'pp'

filename = File.basename(__FILE__).gsub(File.extname(__FILE__), '')
frames = Vines[1][:points].length
style = -> {
  colors = RbArt::GrassColors.sample 2
  {
    stroke: colors[0],
    fill: colors[0],
    stroke_width: "4pt"
  }
}.()

RbArt::Animation.new {
  frames frames
  scale 4
  mp4 "out/post/#{filename}.mp4"
  gif "out/post/#{filename}.gif"

  fps 30
}.render { |frame_idx, frame_count|
  points = Vines[1][:points]
  RbArt::Canvas.new {
    width      Width
    height     Height
    background RbArt::BackgroundColor

    draw RbArt::Path.new {
      style style

      points.first(frame_idx + 1).each_i_first_last { |point, idx, f, l|
        if f
          m point
        else
          l point
        end
      }
      z
    }
  }
}