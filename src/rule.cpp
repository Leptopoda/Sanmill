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

#include <cstring>

#include "rule.h"

struct Rule rule = {
        "Nine men's morris",      // 莫里斯九子棋
        // 规则说明
        "规则与成三棋基本相同，只是在走子阶段，当一方仅剩3子时，他可以飞子到任意空位。",
        9,          // 双方各9子
        3,          // 飞子条件为剩余3颗子
        3,          // 赛点子数为3
        false,      // 没有斜线
        false,      // 没有禁点，摆棋阶段被提子的点可以再摆子
        false,      // Lasker Morris
        false,      // 先摆棋者先行棋
        false,      // 多个“三连”只能提一子
        false,      // 不能提对手的“三连”子，除非无子可提；
        false,      // 摆子阶段不移除对方未摆的棋子；
        true,       // 摆棋满子（闷棋，只有12子棋才出现）算先手负
        true,       // 走棋阶段不能行动（被“闷”）算负
        true,       // 剩三子时可以飞棋
        100,        // 连续多少步未吃子则和棋
        100,        // 一方只剩3枚棋子时连续多少步未吃子则和棋
        true        // 三次重复局面和
};

const struct Rule RULES[N_RULES] = {
    {
        "成三棋",   // 成三棋
        // 规则说明
        "1. 双方各9颗子，开局依次摆子；\n"
        "2. 凡出现三子相连，就提掉对手一子；\n"
        "3. 不能提对手的“三连”子，除非无子可提；\n"
        "4. 同时出现两个“三连”只能提一子；\n"
        "5. 摆完后依次走子，每次只能往相邻位置走一步；\n"
        "6. 把对手棋子提到少于3颗时胜利；\n"
        "7. 走棋阶段不能行动（被“闷”）算负。",
        9,          // 双方各9子
        3,          // 飞子条件为剩余3颗子
        3,          // 赛点子数为3
        false,      // 没有斜线
        false,      // 没有禁点，摆棋阶段被提子的点可以再摆子
        false,      // Lasker Morris
        false,      // 先摆棋者先行棋
        false,      // 多个“三连”只能提一子
        false,      // 不能提对手的“三连”子，除非无子可提；
        false,      // 摆子阶段不移除对方未摆的棋子；
        true,       // 摆棋满子（闷棋，只有12子棋才出现）算先手负
        true,       // 走棋阶段不能行动（被“闷”）算负
        false,      // 剩三子时不可以飞棋
        100,        // 连续多少步未吃子则和棋
        100,        // 一方只剩3枚棋子时连续多少步未吃子则和棋
        true        // 三次重复局面和
    },
    {
        "打三棋(12连棋)",           // 打三棋
        // 规则说明
        "1. 双方各12颗子，棋盘有斜线；\n"
        "2. 摆棋阶段被提子的位置不能再摆子，直到走棋阶段；\n"
        "3. 摆棋阶段，摆满棋盘算先手负；\n"
        "4. 走棋阶段，后摆棋的一方先走；\n"
        "5. 同时出现两个“三连”只能提一子；\n"
        "6. 其它规则与成三棋基本相同。",
        12,         // 双方各12子
        3,          // 飞子条件为剩余3颗子
        3,          // 赛点子数为3
        true,       // 有斜线
        true,       // 有禁点，摆棋阶段被提子的点不能再摆子
        false,      // Lasker Morris
        true,       // 后摆棋者先行棋
        false,      // 多个“三连”只能提一子
        true,       // 可以提对手的“三连”子
        false,      // 摆子阶段不移除对方未摆的棋子；
        true,       // 摆棋满子（闷棋，只有12子棋才出现）算先手负
        true,       // 走棋阶段不能行动（被“闷”）算负
        false,      // 剩三子时不可以飞棋
        100,        // 连续多少步未吃子则和棋
        100,        // 一方只剩3枚棋子时连续多少步未吃子则和棋
        true        // 三次重复局面和
    },
    {
        "Nine men's morris",      // 莫里斯九子棋
        // 规则说明
        "规则与成三棋基本相同，只是在走子阶段，当一方仅剩3子时，他可以飞子到任意空位。",
        9,          // 双方各9子
        3,          // 飞子条件为剩余3颗子
        3,          // 赛点子数为3
        false,      // 没有斜线
        false,      // 没有禁点，摆棋阶段被提子的点可以再摆子
        false,      // Lasker Morris
        false,      // 先摆棋者先行棋
        false,      // 多个“三连”只能提一子
        false,      // 不能提对手的“三连”子，除非无子可提；
        false,      // 摆子阶段不移除对方未摆的棋子；
        true,       // 摆棋满子（闷棋，只有12子棋才出现）算先手负
        true,       // 走棋阶段不能行动（被“闷”）算负
        true,       // 剩三子时可以飞棋
        100,        // 连续多少步未吃子则和棋
        100,        // 一方只剩3枚棋子时连续多少步未吃子则和棋
        true        // 三次重复局面和
    },
    {
        "Twelve men's morris",      // 莫里斯十二子棋
        // 规则说明
        "1. 双方各12颗子，棋盘有斜线；\n"
        "2. 摆棋阶段被提子的位置不能再摆子，直到走棋阶段；\n"
        "3. 摆棋阶段，摆满棋盘算先手负；\n"
        "4. 走棋阶段，后摆棋的一方先走；\n"
        "5. 同时出现两个“三连”只能提一子；\n"
        "6. 其它规则与成三棋基本相同。",
        12,         // 双方各12子
        3,          // 飞子条件为剩余3颗子
        3,          // 赛点子数为3
        true,       // 有斜线
        false,      // 没有禁点，摆棋阶段被提子的点可以再摆子
        false,      // Lasker Morris
        false,      // 先摆棋者先行棋
        false,      // 多个“三连”只能提一子
        false,      // 不能提对手的“三连”子，除非无子可提；
        false,      // 摆子阶段不移除对方未摆的棋子；
        true,       // 摆棋满子（闷棋，只有12子棋才出现）算先手负
        true,       // 走棋阶段不能行动（被“闷”）算负
        true,       // 剩三子时可以飞棋
        100,        // 连续多少步未吃子则和棋
        100,        // 一方只剩3枚棋子时连续多少步未吃子则和棋
        true        // 三次重复局面和
    },
    {
        "Lasker Morris",      // 莫里斯九子棋
        // 规则说明
        "规则与成三棋基本相同，只是在走子阶段，当一方仅剩3子时，他可以飞子到任意空位。",
        10,         // 双方各9子
        3,          // 飞子条件为剩余3颗子
        3,          // 赛点子数为3
        false,      // 没有斜线
        false,      // 没有禁点，摆棋阶段被提子的点可以再摆子
        true,       // Lasker Morris
        false,      // 先摆棋者先行棋
        false,      // 多个“三连”只能提一子
        false,      // 不能提对手的“三连”子，除非无子可提；
        false,      // 摆子阶段不移除对方未摆的棋子；
        true,       // 摆棋满子（闷棋，只有12子棋才出现）算先手负
        true,       // 走棋阶段不能行动（被“闷”）算负
        true,       // 剩三子时可以飞棋
        100,        // 连续多少步未吃子则和棋
        100,        // 一方只剩3枚棋子时连续多少步未吃子则和棋
        true        // 三次重复局面和
    }
};

bool set_rule(int ruleIdx) noexcept
{
    if (ruleIdx <= 0 || ruleIdx >= N_RULES) {
        return false;
    }

    std::memset(&rule, 0, sizeof(Rule));
    std::memcpy(&rule, &RULES[ruleIdx], sizeof(Rule));

    return true;
}
