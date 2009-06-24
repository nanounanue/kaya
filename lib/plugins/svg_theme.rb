require 'qtutils'
require 'plugins/plugin'
require 'plugins/shadow'

class SvgTheme
  include Shadower

  def initialize(opts = {})
    @loader = lambda do |piece, size|
      Qt::Image.from_renderer(size, renderer, piece_id(piece))
    end
    if opts.has_key?(:shadow)
      @loader = with_shadow(@loader)
    end
  end

  def pixmap(piece, size)
    @loader[piece, size].to_pix
  end
  
  def renderer
    @renderer ||= create_renderer
  end
  
  def create_renderer
    Qt::SvgRenderer.new(filename)
  end
  
  def piece_id(piece)
    piece.color.to_s.capitalize + piece.type.to_s.capitalize
  end
  
  def flip(value)
  end
end