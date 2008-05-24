require 'themes/theme'
require 'enumerator'

begin
  require 'ext/expblur'
rescue LoadError
  def expblur(img, radius) end
end

class DefaultBackground
  include Theme
  HALO_DELTA = 0.1
  
  def initialize(squares)
    @squares = squares
  end

  def pixmap(size)
    Qt::Image.painted(Qt::Point.new(size.x * @squares.x, size.y * @squares.y)) do |p|
      (0...@squares.x).each do |x|
        (0...@squares.y).each do |y|
          rect = Qt::RectF.new(size.x * x, size.y * y, size.x, size.y)
          color = if (x + y) % 2 == 0
            Qt::Color.new(0x6b, 0x82, 0x9c)
          else
            Qt::Color.new(0xb8, 0xc0, 0xc0)
          end
          p.fill_rect(rect, Qt::Brush.new(color))
        end
      end
    end.to_pix
  end
  
  def halo(size, color)
    lines = [[[HALO_DELTA, HALO_DELTA], [1.0 - HALO_DELTA, HALO_DELTA]],
             [[HALO_DELTA, 1.0 - HALO_DELTA], [1.0 - HALO_DELTA, 1.0 -HALO_DELTA]],
             [[HALO_DELTA, HALO_DELTA], [HALO_DELTA, 1.0 - HALO_DELTA]],
             [[1.0 - HALO_DELTA, HALO_DELTA], [1.0 - HALO_DELTA, 1.0 - HALO_DELTA]]]
    img = Qt::Image.painted(size) do |p|
      lines.each do |src, dst|
        src = Qt::PointF.new(src[0] * size.x, src[1] * size.y)
        dst = Qt::PointF.new(dst[0] * size.x, dst[1] * size.y)
        p.pen = Qt::Pen.new(Qt::Brush.new(color), size.x * HALO_DELTA)
        p.draw_line Qt::LineF.new(src, dst)
      end
    end
    expblur(img, size.x * HALO_DELTA)
    img.to_pix
  end
  
  def selection(size)
    halo(size, Qt::Color.new(0xff, 0x40, 0x40))
  end
end