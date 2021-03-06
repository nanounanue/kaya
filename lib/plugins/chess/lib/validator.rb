# Copyright (c) 2009 Paolo Capriotti <p.capriotti@gmail.com>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

require 'games/validator_base'

module Chess
  class Validator < ValidatorBase
    def initialize(state)
      super
    end
  
    def [](move)
      move.validate do |m|
        validate(m)
      end
    end
  
    def validate(move, target = nil)
      return false unless proper?(move)
      piece = @state.board[move.src]
      return false unless check_pseudolegality(piece, target, move)
      move.promotion = nil unless move.type == :promotion
      
      @state.try(move) do |tmp|
        validator = self.class.new(tmp)
        legal = validator.check_legality(piece, target, move)
        return false unless legal
      end
      
      true
    end

    def validate_pawn(piece, target, move)
      dir = @state.direction(piece.color)
      en_passant = move.dst == @state.en_passant_square
      
      valid = if target or en_passant
        valid = move.delta.y == dir.y &&
                move.delta.x.abs == 1
        move.type = :en_passant_capture if valid and en_passant
        valid
      else
        case move.delta.y
        when dir.y
          move.delta.x == 0
        when dir.y * 2
          valid = move.src.y == @state.row(1, piece.color) &&
                  move.delta.x == 0 && 
                  !@state.board[move.src + dir]
          move.type = :en_passant_trigger if valid
          valid
        else
          false
        end
      end
      
      if valid and move.dst.y == @state.row(0, @state.opposite_turn(piece.color))
        if move.promotion
          move.type = :promotion
        else
          valid = false
        end
      end
      
      valid
    end
    
    def validate_king(piece, target, move)
      standard = move.delta.x.abs <= 1 &&
                 move.delta.y.abs <= 1
                 
      if not standard
        delta = move.delta
        return false unless delta.x.abs == 2 && delta.y == 0
#         puts "delta ok"
        return false unless move.src == @state.king_starting_position(piece.color)
#         puts "king in place"
        offsets = (delta.x > 0 ? [1,2] : [-1, -2, -3]).map{|i| move.src + Point.new(i, 0) }
        return false unless offsets.all? {|p| not @state.board[p] }
#         puts "free path"
        if delta.x > 0
          return false unless @state.castling_rights.king?(piece.color)
#           puts "king-castling rights ok"
        else
          return false unless @state.castling_rights.queen?(piece.color)
#           puts "queen-castling rights ok"
        end
        validator = self.class.new(@state)
        attack = [0, delta.x.unit, delta.x.unit * 2].all? do |i| 
          p = move.src + Point.new(i, 0)
          not attacked?(p, @state.board[move.src])
        end
        return false unless attack
#         puts "attacks ok"
        
        move.type = delta.x > 0 ? :king_side_castling : :queen_side_castling
        return true
      end
      
      standard
    end
    
    def validate_bishop(piece, target, move)
      range = move.range
      range.diagonal? and
      @state.board.clear_path? range
    end
    
    def validate_rook(piece, target, move)
      range = move.range
      range.parallel? and
      @state.board.clear_path? range
    end
    
    def validate_queen(piece, target, move)
      range = move.range
      range.valid? and
      @state.board.clear_path? range
    end
    
    def validate_knight(piece, target, move)
      [move.delta.x.abs, move.delta.y.abs].sort == [1, 2]
    end
    
    def each_move(src, dst, target)
      piece = @state.board[src]
      if piece
        moves = if piece.type == :pawn and 
                   dst.y == @state.row(0, @state.opposite_turn(piece.color))
          [:knight, :bishop, :rook, :queen].map do |type|
            @state.move_factory.new(src, dst, :promotion => type)
          end
        else
          [@state.move_factory.new(src, dst)]
        end
        
        moves.each do |m|
#           puts "checking #{m}, piece = #{piece}, target = #{target}"
          yield m if check_pseudolegality(piece, target, m)
        end
      end
    end
  end
end
