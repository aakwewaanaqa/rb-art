require_relative "ref"
ref

# 20261012 的螺旋藤蔓動畫，最上層疊上 wait.svg，並讓它上下飄動。
# 直接 require 20261012 拿它的 Timeline / CanvasSize（它自己的渲染被
# __FILE__ == $0 擋掉，不會重畫一次）。
require_relative "20261012"

WaitSvgPath   = File.expand_path("../../../out/post/20261014_layers/wait.svg", __dir__)
FloatPeriod   = 2.0 # 飄一輪（上 -> 下 -> 回原位）要幾秒
FloatAmplitude = 15 # 上下各飄幾 px

# 飄動的總長抓成 FloatPeriod 的整數倍，且不短於藤蔓動畫，GIF 循環接回
# 開頭時位置剛好回到原點。
float_duration = (Timeline.duration / FloatPeriod).ceil * FloatPeriod

Timeline.cue {
  duration float_duration
  layer    2 # 藤蔓 0、葉子 1，圖要蓋在最上面
  cue { |t|
    RbArt::SvgImage.new {
      file   WaitSvgPath
      y      RbArt.oscillate(t * float_duration, period: FloatPeriod, amplitude: FloatAmplitude)
      width  CanvasSize
      height CanvasSize
    }
  }
}

RbArt::Animation.new {
  timeline Timeline
  canvas {
    width      CanvasSize
    height     CanvasSize
    background RbArt::BackgroundColor
  }
  dir "out/post/20261014"
  gif "out/post/20261014.gif"
  mp4 "out/post/20261014.mp4"
}.render
