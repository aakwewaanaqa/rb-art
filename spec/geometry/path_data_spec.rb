require "minitest/autorun"
require_relative "../../lib/rb_art"

include RbArt::Geometry

def pt(x, y) = Point.new(x, y)

def assert_point(expected, actual, delta = 1e-9)
  assert_in_delta expected.x, actual.x, delta
  assert_in_delta expected.y, actual.y, delta
end

describe "CubicBezier.quadratic" do
  it "升階後跟原本的二次曲線處處重合" do
    p0, q, p2 = pt(0, 0), pt(50, 100), pt(100, 0)
    bez = CubicBezier.quadratic(p0, q, p2)
    [0, 0.25, 0.5, 0.8, 1].each { |t|
      expected = p0.scale((1 - t)**2) + q.scale(2 * t * (1 - t)) + p2.scale(t**2)
      assert_point expected, bez.point_at(t)
    }
  end
end

describe RbArt::Geometry::PathData do
  def parse(d) = PathData.parse(d)

  it "M L Z 產生一條封閉 chain，並補上回起點的線段" do
    chains = parse("M0 0 L10 0 L10 10 Z")
    assert_equal 1, chains.size
    chain = chains.first
    assert chain.closed?
    assert_equal 3, chain.count
    assert_point pt(0, 0), chain.items(nil).last.p3
    assert_in_delta 10 + 10 + Math.sqrt(200), chain.total_length, 1e-6
  end

  it "Z 時已經在起點就不補線段" do
    chain = parse("M0 0 L10 0 L0 0 Z").first
    assert_equal 2, chain.count
  end

  it "沒有 Z 的子路徑不是 closed" do
    refute parse("M0 0 L10 0").first.closed?
  end

  it "相對座標、H/V 與 M 後面隱含的 L" do
    chain = parse("m5 5 10 0 v10 h-10 z").first
    ends = chain.items(nil).map(&:p3)
    assert_equal [pt(15, 5), pt(15, 15), pt(5, 15), pt(5, 5)], ends
  end

  it "多條子路徑各自一個 chain，Z 之後的相對 m 從前一條起點算" do
    chains = parse("M10 10 L20 10 L20 20 Z m5 0 l1 0")
    assert_equal 2, chains.size
    assert_point pt(15, 10), chains[1].items(nil).first.p0
  end

  it "S 鏡射前一段 C 的第二控制點" do
    seg = parse("M0 0 C0 10 10 10 10 0 S20 -10 20 0").first.items(nil)[1]
    assert_point pt(10, -10), seg.p1
  end

  it "S 前面不是 C/S 時，第一控制點就是目前位置" do
    seg = parse("M0 0 L10 0 S20 10 20 0").first.items(nil)[1]
    assert_point pt(10, 0), seg.p1
  end

  it "Q 與 T 鏡射出的控制點跟手動升階一致" do
    segs = parse("M0 0 Q5 10 10 0 T20 0").first.items(nil)
    expected = CubicBezier.quadratic(pt(10, 0), pt(15, -10), pt(20, 0))
    assert_point expected.p1, segs[1].p1
    assert_point expected.p2, segs[1].p2
  end

  it "數字黏在一起的寫法（負號、連續小數點、科學記號）" do
    ends = parse("M0,0L1-2l.5.5L1e1-1e1").first.items(nil).map(&:p3)
    assert_equal [pt(1, -2), pt(1.5, -1.5), pt(10, -10)], ends
  end

  it "fontTools 風格的字形輸出可以沿弧長取點" do
    chain = parse("M58.8 -5.5Q55.3 -3.9 51.35 -1.7Q47.4 0.5 44.2 2.7L40.1 -3.9Z").first
    assert chain.closed?
    assert_point chain.point_at(0), chain.point_at_spatial_t(0), 1e-6
    assert_point pt(58.8, -5.5), chain.point_at_spatial_t(1), 1e-6
  end

  it "A 尚未支援" do
    assert_raises(NotImplementedError) { parse("M0 0 A5 5 0 0 1 10 0") }
  end

  it "開頭沒有指令或數字不足時報錯" do
    assert_raises(ArgumentError) { parse("10 10") }
    assert_raises(ArgumentError) { parse("M0 0 C1 1 2 2") }
  end
end
