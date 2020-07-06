﻿/*
  Sanmill, a mill game playing engine derived from NineChess 1.5
  Copyright (C) 2015-2018 liuweilhy (NineChess author)
  Copyright (C) 2019-2020 Calcitem <calcitem@outlook.com>

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

#include "option.h"

Options gameOptions;

void Options::setAutoRestart(bool enabled)
{
    isAutoRestart = enabled;
};

bool Options::getAutoRestart()
{
    return isAutoRestart;
}

void Options::setAutoChangeFirstMove(bool enabled)
{
    isAutoChangeFirstMove = enabled;
}

bool Options::getAutoChangeFirstMove()
{
    return isAutoChangeFirstMove;
}

void Options::setGiveUpIfMostLose(bool enabled)
{
    giveUpIfMostLose = enabled;
}

bool Options::getGiveUpIfMostLose()
{
    return giveUpIfMostLose;
}

void Options::setRandomMoveEnabled(bool enabled)
{
    randomMoveEnabled = enabled;
}

bool Options::getRandomMoveEnabled()
{
    return randomMoveEnabled;
}

void Options::setLearnEndgameEnabled(bool enabled)
{
#ifdef ENDGAME_LEARNING_FORCE
    learnEndgame = true;
#else
    learnEndgame = enabled;
#endif
}

bool Options::getLearnEndgameEnabled()
{
#ifdef ENDGAME_LEARNING_FORCE
    return  true;
#else
    return learnEndgame;
#endif
}

void Options::setIDSEnabled(bool enabled)
{
    IDSEnabled = enabled;
}

bool Options::getIDSEnabled()
{
    return IDSEnabled;
}

// DepthExtension

void Options::setDepthExtension(bool enabled)
{
    depthExtension = enabled;
}

bool Options::getDepthExtension()
{
    return depthExtension;
}

// OpeningBook

void Options::setOpeningBook(bool enabled)
{
    openingBook = enabled;
}

bool Options::getOpeningBook()
{
    return openingBook;
}
