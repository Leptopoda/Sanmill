﻿/*****************************************************************************
 * Copyright (C) 2018-2019 MillGame authors
 *
 * Authors: liuweilhy <liuweilhy@163.com>
 *          Calcitem <calcitem@outlook.com>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

/* 这个类处理场景对象QGraphicsScene
 * 它是本程序MVC模型中唯一的控制模块
 * 它不对主窗口中的控件做任何操作，只向主窗口发出信号
 * 本来可以重载QGraphicsScene实现它，还能省去写事件过滤器的麻烦
 * 但用一个场景类做那么多控制模块的操作看上去不太好
 */

#ifndef GAMECONTROLLER_H
#define GAMECONTROLLER_H

#include <QTime>
#include <QPointF>
#include <QMap>
#include <QList>
#include <QTextStream>
#include <QStringListModel>
#include <QModelIndex>

#include "millgame.h"
#include "gamescene.h"
#include "pieceitem.h"
#include "thread.h"
#include "server.h"
#include "client.h"

class GameController : public QObject
{
    Q_OBJECT

public:
    GameController(GameScene &scene, QObject *parent = nullptr);
    ~GameController() override;

    //主窗口菜单栏明细
    const QMap <int, QStringList> getActions();

    int getRuleNo()
    {
        return ruleNo_;
    }

    int getTimeLimit()
    {
        return timeLimit;
    }

    int getStepsLimit()
    {
        return stepsLimit;
    }

    bool getGiveUpIfMostLose()
    {
        return giveUpIfMostLose_;
    }

    bool getRandomMove()
    {
        return randomMove_;
    }

    bool isAnimation()
    {
        return hasAnimation;
    }

    void setDurationTime(int i)
    {
        durationTime = i;
    }

    int getDurationTime()
    {
        return durationTime;
    }

    QStringListModel *getManualListModel()
    {
        return &manualListModel;
    }

    void setAiDepthTime(depth_t depth1, int time1, depth_t depth2, int time2);
    void getAiDepthTime(depth_t &depth1, int &time1, depth_t &depth2, int &time2);

signals:

    // 玩家1(先手）赢盘数改变的信号
    void score1Changed(const QString &score);

    // 玩家2(后手）赢盘 数改变的信号
    void score2Changed(const QString &score);

    // 和棋数改变的信号
    void scoreDrawChanged(const QString &score);

    // 玩家1(先手）用时改变的信号
    void time1Changed(const QString &time);

    // 玩家2(后手）用时改变的信号
    void time2Changed(const QString &time);

    // 通知主窗口更新状态栏的信号
    void statusBarChanged(const QString &message);

public slots:

    // 设置规则
    void setRule(int ruleNo, step_t stepLimited = UINT16_MAX, int timeLimited = -1);

    // 游戏开始
    void gameStart();

    // 游戏重置
    void gameReset();

    // 设置编辑棋局状态
    void setEditing(bool arg = true);

    // 设置黑白反转状态
    void setInvert(bool arg = true);

    // 让电脑执先手
    void setEngine1(bool arg = true);

    // 让电脑执后手
    void setEngine2(bool arg = true);

    // 是否有落子动画
    void setAnimation(bool arg = true);

    // 是否有落子音效
    void setSound(bool arg = true);

    // 播放声音
    void playSound(const QString &soundPath);

    // 是否必败时认输
    void setGiveUpIfMostLose(bool arg);

    // 是否自动开局
    void setAutoRestart(bool arg = false);

    // AI 是否随机走子
    void setRandomMove(bool arg);

    // 上下翻转
    void flip();

    // 左右镜像
    void mirror();

    // 视图须时针旋转90°
    void turnRight();

    // 视图逆时针旋转90°
    void turnLeft();

    bool isAIsTurn();

    // 根据QGraphicsScene的信号和状态来执行选子、落子或去子
    bool actionPiece(QPointF p);

    // 认输
    bool giveUp();

    // 棋谱的命令行执行
    bool command(const QString &cmd, bool update = true);

    // 历史局面及局面改变
    bool stageChange(int row, bool forceUpdate = false);

    // 更新棋局显示，每步后执行才能刷新局面
    bool updateScence();
    bool updateScence(MillGame &game);

    // 显示网络配置窗口
    void showNetworkWindow();

protected:
    //bool eventFilter(QObject * watched, QEvent * event);
    // 定时器
    void timerEvent(QTimerEvent *event) override;

private:
    // 棋对象的数据模型
    MillGame game_;

    // 棋对象的数据模型（临时）
    MillGame gameTemp;

    // 2个AI的线程
    AiThread ai1, ai2;

    // 棋局的场景类
    GameScene &scene;

    // 所有棋子
    QList<PieceItem *> pieceList;

    // 当前棋子
    PieceItem *currentPiece;

    // 当前浏览的棋谱行
    int currentRow;

    // 玩家1手棋数、玩家2手棋数、待去棋数，没有用到，注释掉
    //int player1_InHand, player2_InHand, num_NeedRemove;

    // 是否处于“编辑棋局”状态
    bool isEditing;

    // 是否黑白反转
    bool isInverted;

    // 是否电脑执先手
    bool isAiPlayer1;

    // 是否电脑执后手
    bool isAiPlayer2;

    // 是否有落子动画
    bool hasAnimation;

    // 动画持续时间
    int durationTime;

    // 是否有落子音效
    bool hasSound;

    // 是否必败时认输
    bool giveUpIfMostLose_;

    // 是否棋局结束后自动重新开局
    bool isAutoRestart;

    // AI 是否随机走子
    bool randomMove_;

    // 定时器ID
    int timeID;

    // 规则号
    int ruleNo_;

    // 规则限时（分钟）
    int timeLimit;

    // 规则限步数
    step_t stepsLimit;

    // 玩家1剩余时间（秒）
    time_t remainingTime1;

    // 玩家2剩余时间（秒）
    time_t remainingTime2;

    // 用于主窗口状态栏显示的字符串
    QString message;

    // 棋谱字符串列表模型
    QStringListModel manualListModel;
};

#endif // GAMECONTROLLER_H