/*
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

#include <cstring>
#include "command_queue.h"
#include "base.h"
#include "config.h"

CommandQueue::CommandQueue()
{
    for (int i = 0; i < MAX_COMMAND_COUNT; i++) {
        commands[i][0] = '\0';
    }

    writeIndex = 0;
    readIndex = -1;
}

bool CommandQueue::write(const char *command)
{
    std::unique_lock<std::mutex> lk(mutex);

    if (strlen(commands[writeIndex]) != 0) {
        return false;
    }

    strncpy(commands[writeIndex], command, COMMAND_LENGTH);

    if (readIndex == -1) {
        readIndex = writeIndex;
    }

    if (++writeIndex == MAX_COMMAND_COUNT) {
        writeIndex = 0;
    }

    return true;
}

bool CommandQueue::read(char *dest)
{
    std::unique_lock<std::mutex> lk(mutex);

    if (readIndex == -1) {
        return false;
    }

    strncpy(dest, commands[readIndex], 4096);   // See  uci.cpp LINE_INPUT_MAX_CHAR
    strncpy(commands[readIndex], "", COMMAND_LENGTH);

    if (++readIndex == MAX_COMMAND_COUNT) {
        readIndex = 0;
    }

    if (readIndex == writeIndex) {
        readIndex = -1;
    }

    return true;
}
