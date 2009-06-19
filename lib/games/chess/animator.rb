require 'animator_helper'

module Chess
  class Animator
    include AnimatorHelper
    attr_reader :board
    
    def initialize(board)
      @board = board
    end

    def specific_move!(piece, src, dst)
      path = if piece.type == :knight
        Path::LShape
      else
        Path::Linear
      end
      move!(src, dst, path)
    end

    def warp(state, opts = { :instant => true })
      res = []
      
      state.board.each_square do |p|
        new_piece = state.board[p]
        old_item = @board.items[p]
        
        if new_piece
          if not old_item
            res << appear_on!(p, new_piece, opts)
          elsif new_piece.name != old_item.name
            res << morph_on!(p, new_piece, opts)
          end
        else
          res << disappear_on!(p, opts) if old_item
        end
      end

      group(*res)
    end
    
    def forward(state, move)
      capture = disappear_on! move.dst
      actual_move = specific_move! state.board[move.dst], move.src, move.dst
      extra = if move.type == :king_side_castling
        move! move.dst + Point.new(1, 0), move.dst - Point.new(1, 0)
      elsif move.type == :queen_side_castling
        move! move.dst - Point.new(2, 0), move.dst + Point.new(1, 0)
      end
      
      rest = warp(state, :instant => false)
      main = group(capture, actual_move, extra)
      
      sequence(main, rest)
    end
    
    def back(state, move)
      actual_move = move! move.dst, move.src
      extra = if move.type == :king_side_castling
        move! move.dst - Point.new(1, 0), move.dst + Point.new(1, 0)
      elsif move.type == :queen_side_castling
        move! move.dst + Point.new(1, 0), move.dst - Point.new(2, 0)
      end
      rest = warp(state, :instant => false)
      
      main = group(actual_move, extra)
      sequence(main, rest)
    end
  end
end
