require_relative "../../lib/rb_art"

width = 750
height = 500
RbArt::Canvas.new {
  width width
  height height
  background "#9ED06D"
  svg "out/fern_2.svg"

  rect = RbArt::Geometry::Rect.new {
    xmin width - 50
    xmax width + 50
    ymin 0
    ymax height
  }
  
  p0 = RbArt::Geometry::Point.new(width / 2.0, height)
  p3 = RbArt::Geometry::Point.new(width / 2.0, height / 2.0)
  
  begin
    p1 = RbArt::Geometry::Point.rnd rect
    p2 = RbArt::Geometry::Point.rnd rect
    d = (p1 - p2).length

    curve = RbArt::Geometry::CubicBezier.new(p0, p1, p2, p3)
    curvatures = (0.1..1.0).step(0.1).map { |t| curve.curvature_at(t) }
    is_delta_curvature_too_high = curvatures.each_cons(2).any? { |a, b| (b - a).abs > 0.2 }

    # 曲率的「相鄰差值」平滑，不代表切線方向沒有持續往同一邊轉超過一圈而繞出圈圈，
    # 所以另外算切線角度的累積轉角，轉太多（快接近半圈以上）就當作會自我交叉，重抽。
    angles = (0.0..1.0).step(0.1).map { |t| Math.atan2(curve.tangent_at(t).y, curve.tangent_at(t).x) }
    total_turn = angles.each_cons(2).sum { |a, b|
      delta = (b - a) % (Math::PI * 2)
      delta -= Math::PI * 2 if delta > Math::PI
      delta.abs
    }
    is_looping = total_turn > Math::PI * 0.9
  end while d <= 50 || is_delta_curvature_too_high || is_looping

  length_data = -> {
    n = 8
    growth = 1.35
    base = (0...n).map { |i| 1.6 * (growth**i) }
    sum = base.sum
    t_lengths = (base.map { |v| v / sum.to_f }).reverse
    arc_lengths = curve.split_by_arc_lengths t_lengths

    {
      t_lengths: t_lengths,
      arc_lengths: arc_lengths
    }
  }.()

  # 貝茲曲線的平行位移曲線一般不會剛好也是貝茲曲線，硬把 p1/p2 跟著端點平移
  # 只保證頭尾兩點的厚度對，中間段落厚度會跑掉。改成逐點取樣：
  # 在中線上多取幾個 t，各自用該處的法向量（切線轉 90°）往外推 width_at.(t) 的厚度，
  # 厚度曲線想怎麼設計（線性、指數遞減...）都直接餵給 width_at 這個 lambda 即可。
  # 厚度不能無限大：如果中線在某個 t 彎得比較急（局部曲率半徑小），
  # 推出去的厚度一旦超過那個半徑，位移點就會反穿到中線另一側，
  # 自己繞出一個圈圈（這是位移曲線本身的幾何限制，不是取樣寫錯）。
  # 用「硬夾」（Numeric#clamp）在曲率變化快的地方，前後兩個取樣點之間的厚度會有
  # 一個沒被平滑處理過的斷點（該點前還沒被夾、下一點突然夾很緊），Catmull-Rom
  # 順著這種斷點內插，就會鼓出一個小結——這是位移曲線在曲率劇烈變化／反曲點
  # 附近的經典問題。改成「軟夾」：用類似向量歸一化的連續函數把厚度往安全半徑
  # 壓縮，曲率怎麼變厚度都連續地跟著變，不會有硬轉折。
  offset_points = ->(width_at, samples: 48) {
    (0..samples).map { |i|
      t = i.fdiv(samples)
      n = curve.tangent_at(t).rotate(Math::PI / 2)
      safe_radius = 0.6 / [curve.curvature_at(t).abs, 1e-6].max
      w = width_at.(t)
      w_safe = w * safe_radius / Math.sqrt(safe_radius**2 + w**2)
      curve.point_at(t) + n * w_safe
    }
  }

  # Catmull-Rom：給一串點，反擬合出「精確穿過每個點」的平滑貝茲曲線，
  # 不用像位移公式那樣去解析每個控制點該長怎樣，只要點排列合理，轉出來的
  # 切線方向就會自動跟著點的走勢走，銜接處也會自然平滑（不會有折線的尖角）。
  catmull_rom_segments = ->(points) {
    padded = [points.first] + points + [points.last]
    (1...(padded.size - 2)).map { |i|
      p0_, p1_, p2_, p3_ = padded[i - 1], padded[i], padded[i + 1], padded[i + 2]
      c1 = p1_ + (p2_ - p0_) * (1.0 / 6)
      c2 = p2_ - (p3_ - p1_) * (1.0 / 6)
      [p1_, c1, c2, p2_]
    }
  }

  draw_smooth = ->(points) {
    draw RbArt::Path.new {
      m points.first
      catmull_rom_segments.(points).each { |_, c1, c2, p1| c c1, c2, p1 }

      stroke "black"
      fill "none"
      stroke_width "4pt"
    }
  }

  # 原本用 arc_lengths.first（整條曲線裡最大的一段）* 1.9 當厚度，
  # 幾乎跟整個畫布一樣寬——改用整條曲線總長度的一個小比例，厚度才會合理。
  base_width = curve.arc_length * 0.06
  l_points = offset_points.(->(t) { -base_width * (1 - t) })
  r_points = offset_points.(->(t) { base_width * (1 - t) })

  draw RbArt::Path.new {
    m curve.p0
    c curve.p1, curve.p2, curve.p3

    stroke "black"
    fill "none"
    stroke_width "4pt"
  }
  draw_smooth.(l_points)
  draw_smooth.(r_points)
}