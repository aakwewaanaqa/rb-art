require_relative "../../../lib/rb_art"

module RbArt
  # 跟背景色差距越大的顏色，被抽到的機率越低。
  BackgroundColor = RbArt.color_hex("#9ED06D")
  PlantNoramlColor = RbArt.color_hex("#A8DF11")
  SkinPink = RbArt.color_hex "FFBAE7"
  SpiritBlue = RbArt.color_hex "0BAEFF"

  GrassColors = [
    RbArt.color_hex("#DBFD02"),
    RbArt.color_hex("#A8DF11"),
    RbArt.color_hex("#93BE1D"),
    RbArt.color_hex("#C7F251"),
    RbArt.color_hex("#81C217"),
  ]

  # fill/stroke 分開取色（跟 grass.rb 的 SFStyle 一樣），
  # stroke 固定取比 fill 深一階的顏色（往前一格，循環）避免整株輪廓太搶戲。
  GrassStyles = GrassColors.each_with_index.map { |color, i|
    stroke_color = GrassColors[(i - 1) % GrassColors.length]
    dist = color.dist(PlantNoramlColor)
    {
      fill: color,
      stroke: stroke_color,
      weight: 1.0 / (1.0 + (dist / 20.0) ** 4),
    }
  }
end