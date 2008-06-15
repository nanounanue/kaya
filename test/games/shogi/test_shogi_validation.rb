require 'test/unit'
require 'games/shogi/state'
require 'games/shogi/validator'
require 'games/chess/move'
require 'games/chess/piece'
require 'games/chess/board'
require 'helpers/validation_helper'

class TestShogiValidation < Test::Unit::TestCase
  include ValidationHelper
  
  def setup
    @board = Chess::Board.new(Point.new(9, 9))
    @state = Shogi::State.new(@board, Chess::Move, Chess::Piece)
    @state.setup
    @validate = Shogi::Validator.new(@state)
  end
  
  def test_invalid_move
    assert_not_valid 32, 3, 3, 1
    assert_not_valid 3, 1, 32, 3
    assert_not_valid 4, 7, 4, 7
  end
  
  def test_black_pawn_push
    assert_valid 4, 6, 4, 5
  end

  def test_white_pawn_push
    @state.turn = :white
    assert_valid 4, 2, 4, 3
  end

  def test_invalid_black_push
    assert_not_valid 4, 6, 4, 4
    assert_not_valid 4, 6, 4, 3
  end
  
  
  def test_pawn_capture
    @board[Point.new(3, 5)] = @board[Point.new(3, 2)]
    assert_valid 3, 6, 3, 5
  end
  
  def test_invalid_chesslike_capture
    @board[Point.new(3, 5)] = @board[Point.new(3, 2)]
    assert_not_valid 4, 6, 3, 5
  end
end
