#ifndef CONFIG_H
#define CONFIG_H

// 调试模式
#define DEBUG

// 播放声音
#ifndef DEBUG
#define PLAY_SOUND
#endif

// Alpha-Beta 随机排序孩子结点
#ifdef DEBUG
#define AB_RANDOM_SORT_CHILDREN
#endif

// 调试博弈树 (耗费大量内存)
#ifdef DEBUG
#define DEBUG_AB_TREE
#endif

// 摆棋阶段动态调整搜索深度
#ifndef DEBUG
#define GAME_PLACING_DYNAMIC_DEPTH
#endif

// 摆棋阶段固定搜索深度
#ifdef DEBUG
#define GAME_PLACING_FIXED_DEPTH  3
#endif


// 走棋阶段固定搜索深度
#ifdef DEBUG
#define GAME_MOVING_FIXED_DEPTH  3
#else
#define GAME_MOVING_FIXED_DEPTH  10
#endif


// 绘制 SEAT 编号
#ifdef DEBUG
#define DRAW_SEAT_NUMBER
#endif

// 摆棋阶段在叉下面显示被吃的子
#define GAME_PLACING_SHOW_CAPTURED_PIECES

// 启动时窗口最大化
//#define SHOW_MAXIMIZED_ON_LOAD

#endif // CONFIG_H