require_relative "../../lib/rb_art"

module RbArt
  # 跟背景色差距越大的顏色，被抽到的機率越低；fill/stroke 用同一個顏色
  # 避免葉片邊界過於鋸齒（密集恐懼症）。
  BackgroundColor = RbArt.color_hex("#9ED06D")
  PlantNoramlColor = RbArt.color_hex("#A8DF11")

  GrassColors = [
    RbArt.color_hex("#DBFD02"),
    RbArt.color_hex("#A8DF11"),
    RbArt.color_hex("#93BE1D"),
    RbArt.color_hex("#C7F251"),
    RbArt.color_hex("#81C217"),
  ]

  GrassStyles = GrassColors.map { |color|
    dist = color.dist(PlantNoramlColor)
    {
      fill: color,
      stroke: color,
      weight: 1.0 / (1.0 + (dist / 20.0) ** 4),
    }
  }
end