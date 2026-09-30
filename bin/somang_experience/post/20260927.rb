require_relative "ref"
ref || extit(155)

GridSize = 250
GridWidthCount = 7
GridHeightCount = 3
Width = GridSize * GridWidthCount
Height = GridSize * GridHeightCount
Frames = 60
Filename = File.basename(__FILE__)

# 在 GrassColors 這個調色盤上做「完美循環」的插值：t 每經過 1/n 就換到下一組
# 顏色，t=0 跟 t=1 會算出同一個顏色，所以拿 t = i.fdiv(frames)（i 從 0 到
# frames-1）逐幀取樣，最後一幀跟第一幀會自然銜接，GIF/MP4 才能無縫循環。
def cyclic_color(colors, t)
  n = colors.length
  scaled = (t % 1.0) * n
  i = scaled.floor % n
  frac = scaled - scaled.floor
  colors[i].lerp(colors[(i + 1) % n], frac)
end

return unless __FILE__ == $0

# 每一格記住固定的 stroke 顏色，以及 top / bottom 兩個相位（隨機錯開），
# 讓每格漸層循環的節奏不同步，看起來像顏色各自在流動而不是整格一起閃爍。
Cells = (0..Width).step(GridSize).flat_map { |x|
  (0..Height).step(GridSize).map { |y|
    colors = RbArt::GrassColors.sample 3
    {
      x: x,
      y: y,
      stroke: colors[0],
      top_phase: rand,
      bottom_phase: rand,
    }
  }
}

RbArt::Animation.new {
  frames Frames
  dir "out/post/20260927_frames"
  gif "out/post/#{Filename}.gif"
  mp4 "out/post/#{Filename}.mp4"
  fps 24
}.render { |i, total|
  t = i.fdiv(total)

  RbArt::Canvas.new {
    width Width
    height Height
    svg "out/post/#{Filename}.svg" if i.zero?

    Cells.each { |cell|
      style = {
        stroke: cell[:stroke],
        fill: linear_gradient(
          direction: :top_to_bottom,
          stops: {
            0 => cyclic_color(RbArt::GrassColors, t + cell[:top_phase]),
            100 => cyclic_color(RbArt::GrassColors, t + cell[:bottom_phase]),
          }
        )
      }
      r = RbArt::Geometry::Point.new(cell[:x], cell[:y])

      draw RbArt::Path.new {
        style style

        m r
        l RbArt::Geometry::Point.new(cell[:x] + GridSize, cell[:y])
        l RbArt::Geometry::Point.new(cell[:x] + GridSize, cell[:y] + GridSize)
        l RbArt::Geometry::Point.new(cell[:x], cell[:y] + GridSize)
        z
      }
    }
  }
}
