﻿/*
  This file is part of Sanmill.
  Copyright (C) 2019-2021 The Sanmill developers (see AUTHORS file)

  Sanmill is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Sanmill is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <algorithm>
#include <cassert>
#include <cstring>   // For std::memset
#include <iomanip>
#include <sstream>

#include "bitboard.h"
#include "evaluate.h"
#include "thread.h"

namespace Trace
{

enum Tracing
{
    NO_TRACE, TRACE
};

}

using namespace Trace;

namespace
{
template<Tracing T>
class Evaluation
{
public:
    Evaluation() = delete;
    explicit Evaluation(Position &p) : pos(p)
    {
    }
    Evaluation &operator=(const Evaluation &) = delete;
    Value value();

private:
    Position &pos;
};


// Evaluation::value() is the main function of the class. It computes the various
// parts of the evaluation and returns the value of the position from the point
// of view of the side to move.

template<Tracing T>
Value Evaluation<T>::value()
{
    Value value = VALUE_ZERO;

    int nPiecesInHandDiff;
    int nPiecesOnBoardDiff;
    int remainingPiecesNeedRemove;

    switch (pos.get_phase()) {
    case Phase::ready:
        break;

    case Phase::placing:
        nPiecesInHandDiff = pos.remaining_pieces_in_hand(BLACK) - pos.remaining_pieces_in_hand(WHITE);
        value += nPiecesInHandDiff * VALUE_EACH_PIECE_INHAND;

        nPiecesOnBoardDiff = pos.remaining_pieces_on_board(BLACK) - pos.remaining_pieces_on_board(WHITE);
        value += nPiecesOnBoardDiff * VALUE_EACH_PIECE_ONBOARD;

        switch (pos.get_action()) {
        case Action::select:
        case Action::place:
            break;

        case Action::remove:
            remainingPiecesNeedRemove = (pos.side_to_move() == BLACK) ?
                pos.remaining_pieces_need_remove() : -(pos.remaining_pieces_need_remove());
            value += remainingPiecesNeedRemove * VALUE_EACH_PIECE_PLACING_NEEDREMOVE;
            break;
        default:
            break;
        }

        break;

    case Phase::moving:
        value = pos.remaining_pieces_on_board(BLACK) * VALUE_EACH_PIECE_ONBOARD -
            pos.remaining_pieces_on_board(WHITE) * VALUE_EACH_PIECE_ONBOARD;

#ifdef EVALUATE_MOBILITY
        value += pos.get_mobility_diff(position->turn, position->remainingPiecesInHand[BLACK], position->remainingPiecesInHand[WHITE], false) * 10;
#endif  /* EVALUATE_MOBILITY */

        switch (pos.get_action()) {
        case Action::select:
        case Action::place:
            break;

        case Action::remove:
            remainingPiecesNeedRemove = (pos.side_to_move() == BLACK) ?
                pos.remaining_pieces_need_remove() : -(pos.remaining_pieces_need_remove());
            value += remainingPiecesNeedRemove * VALUE_EACH_PIECE_MOVING_NEEDREMOVE;
            break;
        default:
            break;
        }

        break;

    case Phase::gameOver:
        if (pos.remaining_pieces_on_board(BLACK) + pos.remaining_pieces_on_board(WHITE) >= EFFECTIVE_SQUARE_NB) {
            if (rule.isBlackLoseButNotDrawWhenBoardFull) {
                value -= VALUE_MATE;
            } else {
                value = VALUE_DRAW;
            }
        } else if (pos.get_action() == Action::select &&
                   pos.is_all_surrounded() &&
                   rule.isLoseButNotChangeSideWhenNoWay) {
            Value delta = pos.side_to_move() == BLACK ? -VALUE_MATE : VALUE_MATE;
            value += delta;
        }

        else if (pos.remaining_pieces_on_board(BLACK) < rule.nPiecesAtLeast) {
            value -= VALUE_MATE;
        } else if (pos.remaining_pieces_on_board(WHITE) < rule.nPiecesAtLeast) {
            value += VALUE_MATE;
        }

        break;

    default:
        break;
    }

    if (pos.side_to_move() == WHITE) {
        value = -value;
    }

    return value;
}

} // namespace


/// evaluate() is the evaluator for the outer world. It returns a static
/// evaluation of the position from the point of view of the side to move.

Value Eval::evaluate(Position &pos)
{
    return Evaluation<NO_TRACE>(pos).value();
}


/// trace() is like evaluate(), but instead of returning a value, it returns
/// a string (suitable for outputting to stdout) that contains the detailed
/// descriptions and values of each evaluation term. Useful for debugging.

std::string Eval::trace(Position &pos)
{
    Value v = Evaluation<TRACE>(pos).value();

    v = pos.side_to_move() == BLACK ? v : -v; // Trace scores are from black's point of view

    std::stringstream ss;

    ss << "\nTotal evaluation: " << v << " (black side)\n";

    return ss.str();
}
