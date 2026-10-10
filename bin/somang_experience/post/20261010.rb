require_relative "ref"
ref

CanvasSize = 1000
SpiralZ = 75 * 2
spiral = -> round {
  {
    root: RbArt::Geometry::Point.new(
      Math.cos(round * Math::PI * 2),
      Math.sin(round * Math::PI * 2),
    ) * round * SpiralZ + RbArt::Geometry::Point.new(CanvasSize.fdiv(2), CanvasSize.fdiv(2)),
    direction: RbArt::Geometry::Point.new(
      Math.cos(round * Math::PI * 2),
      Math.sin(round * Math::PI * 2),
    )
  }
}
LeafCount = 170
RoundCount = 5

# round 均勻增加時，角度也均勻增加，但半徑隨 round 變大，所以外圈同樣的
# 角度間距在畫面上對應的弧長比內圈長——直接用 idx.fdiv(LeafCount) 當
# round 會讓葉子在外圈越疏、內圈越密。這裡用細緻取樣算出 spiral 的
# 弧長對照表，改成依「真實弧長」等距找 round，讓葉子整條螺旋間距固定。
SpiralSamples = 2000
SpiralPoints = (0..SpiralSamples).map { |i| spiral.(i.fdiv(SpiralSamples) * RoundCount)[:root] }
SpiralCumLengths = SpiralPoints.each_cons(2).reduce([0.0]) { |acc, (a, b)| acc << acc.last + a.dist(b) }
SpiralTotalLength = SpiralCumLengths.last

round_at_distance = ->(dist) {
  target = dist.clamp(0.0, SpiralTotalLength)
  idx = SpiralCumLengths.bsearch_index { |l| l >= target } || SpiralCumLengths.size - 1
  idx = [idx, 1].max
  seg_len = SpiralCumLengths[idx] - SpiralCumLengths[idx - 1]
  t = seg_len.zero? ? 0.0 : (target - SpiralCumLengths[idx - 1]).fdiv(seg_len)
  round0 = (idx - 1).fdiv(SpiralSamples) * RoundCount
  round1 = idx.fdiv(SpiralSamples) * RoundCount
  round0 + (round1 - round0) * t
}

LeafStyles = (0...LeafCount).map { |idx|
  colors = RbArt::GrassColors.sample 2
  {
    fill:         colors[0],
    stroke:       colors[1],
    stroke_width: "4pt"
  }
}
VineStyle = -> {
  colors = RbArt::GrassColors.sample 2
  {
    fill:         "none",
    stroke:       colors[1],
    stroke_width: "4pt"
  }  
}.()

RbArt::Animation.new {
  frames 60
  fps 6
  dir "out/post/20261010"
  mp4 "out/post/20261010.mp4"
  gif "out/post/20261010.gif"
}.render { |i, total|
  RbArt::Canvas.new {
    width      CanvasSize
    height     CanvasSize
    background RbArt::BackgroundColor
    svg        "out/post/20261009.svg"
    
    leaf_count = i.fdiv(total) * LeafCount
    (0..leaf_count).to_a.each { |idx|
      round = round_at_distance.(idx.fdiv(LeafCount) * SpiralTotalLength)
      data = spiral.(round)
      offset = 0.1 * Math::PI
      draw RbArt::Leaf.new {
        root        data[:root]
        direction   idx.is_odd? ? data[:direction].rotate(offset) : data[:direction].rotate(Math::PI - offset)
        stem_length 17
        stem_width  3
        leaf_length 60
        leaf_width  75
        style       LeafStyles[idx]
      }
    }

    draw RbArt::Path.new {
      style VineStyle

      vine_count = i.fdiv(total) * SpiralSamples
      (0...vine_count).each { |idx|
        m SpiralPoints.first if idx == 0
        l SpiralPoints[idx]
      }
    }
  }
}