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

import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:sanmill/common/config.dart';
import 'package:sanmill/generated/l10n.dart';
import 'package:sanmill/style/app_theme.dart';
import 'package:sanmill/widgets/game_settings_page.dart';

enum DrawerIndex {
  humanVsAi,
  humanVsHuman,
  aiVsAi,
  setPosition,
  preferences,
  ruleSettings,
  personalization,
  Help,
  About
}

class DrawerListItem {
  DrawerListItem({this.index, this.title = '', this.icon});

  DrawerIndex? index;
  String title;
  Icon? icon;
}

class HomeDrawer extends StatefulWidget {
  const HomeDrawer(
      {Key? key,
      this.screenIndex,
      this.iconAnimationController,
      this.callBackIndex})
      : super(key: key);

  final AnimationController? iconAnimationController;
  final DrawerIndex? screenIndex;
  final Function(DrawerIndex?)? callBackIndex;

  @override
  _HomeDrawerState createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  DateTime? lastTapTime;

  final String tag = "[home_drawer]";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<DrawerListItem> drawerList = <DrawerListItem>[
      DrawerListItem(
        index: DrawerIndex.humanVsAi,
        title: S.of(context).humanVsAi,
        icon: Icon(Icons.person),
      ),
      DrawerListItem(
        index: DrawerIndex.humanVsHuman,
        title: S.of(context).humanVsHuman,
        icon: Icon(Icons.group),
      ),
      DrawerListItem(
        index: DrawerIndex.aiVsAi,
        title: S.of(context).aiVsAi,
        icon: Icon(Icons.computer),
      ),
      DrawerListItem(
        index: DrawerIndex.setPosition,
        title: S.of(context).setPosition,
        icon: Icon(Icons.place),
      ),
      DrawerListItem(
        index: DrawerIndex.preferences,
        title: S.of(context).preferences,
        icon: Icon(Icons.settings),
      ),
      DrawerListItem(
        index: DrawerIndex.ruleSettings,
        title: S.of(context).ruleSettings,
        icon: Icon(Icons.rule),
      ),
      DrawerListItem(
        index: DrawerIndex.personalization,
        title: S.of(context).personalization,
        icon: Icon(Icons.color_lens),
      ),
      DrawerListItem(
        index: DrawerIndex.Help,
        title: S.of(context).help,
        icon: Icon(Icons.help),
      ),
      DrawerListItem(
        index: DrawerIndex.About,
        title: S.of(context).about,
        icon: Icon(Icons.info),
      ),
    ];

    var rotationTransition = RotationTransition(
      turns: AlwaysStoppedAnimation<double>(Tween<double>(begin: 0.0, end: 24.0)
              .animate(CurvedAnimation(
                  parent: widget.iconAnimationController!,
                  curve: Curves.fastOutSlowIn))
              .value /
          360),
    );

    var scaleTransition = ScaleTransition(
      scale: AlwaysStoppedAnimation<double>(
          1.0 - (widget.iconAnimationController!.value) * 0.2),
      child: rotationTransition,
    );

    var animatedBuilder = AnimatedBuilder(
      animation: widget.iconAnimationController!,
      builder: (BuildContext context, Widget? child) {
        return scaleTransition;
      },
    );

    var animatedTextKit = AnimatedTextKit(
        animatedTexts: [
          ColorizeAnimatedText(
            S.of(context).appName,
            textStyle: TextStyle(
              fontSize: Config.fontSize + 16,
              fontWeight: FontWeight.w600,
            ),
            colors: AppTheme.animatedTextsColors,
            textAlign: TextAlign.start,
            speed: const Duration(milliseconds: 3000),
          ),
        ],
        pause: const Duration(milliseconds: 30000),
        repeatForever: true,
        stopPauseOnTap: true,
        onTap: () {
          if (lastTapTime == null ||
              DateTime.now().difference(lastTapTime!) > Duration(seconds: 1)) {
            lastTapTime = DateTime.now();
            print("$tag Tap again in one second to enable developer mode.");
          } else {
            lastTapTime = DateTime.now();
            Developer.developerModeEnabled = true;
            print("$tag Developer mode enabled.");
          }
        });

    var drawerHeader = Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 0.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            animatedBuilder,
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: animatedTextKit,
            ),
          ],
        ),
      ),
    );

    /*
    var exitListTile = ListTile(
      title: Text(
        S.of(context).exit,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: AppTheme.exitTextColor,
        ),
        textAlign: TextAlign.left,
      ),
      trailing: Icon(
        Icons.power_settings_new,
        color: AppTheme.exitIconColor,
      ),
      onTap: () async {
        if (Config.developerMode) {
          return;
        }

        await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
      },
    );
    */

    /*
    var drawFooter = Column(
      children: <Widget>[
        exitListTile,
        SizedBox(height: MediaQuery.of(context).padding.bottom)
      ],
    );
    */

    var scaffold = Scaffold(
      backgroundColor: AppTheme.drawerBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          drawerHeader,
          const SizedBox(height: 4),
          Divider(height: 1, color: AppTheme.drawerDividerColor),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(0.0),
              itemCount: drawerList.length,
              itemBuilder: (BuildContext context, int index) {
                return buildInkwell(drawerList[index]);
              },
            ),
          ),
          Divider(height: 1, color: AppTheme.drawerDividerColor),
          //drawFooter,
        ],
      ),
    );

    return scaffold;
  }

  Future<void> navigationToScreen(DrawerIndex? index) async {
    widget.callBackIndex!(index);
  }

  Widget buildInkwell(DrawerListItem listItem) {
    var animatedBuilder = AnimatedBuilder(
      animation: widget.iconAnimationController!,
      builder: (BuildContext context, Widget? child) {
        return Transform(
          transform: Matrix4.translationValues(
              (MediaQuery.of(context).size.width * 0.75 - 64) *
                  (1.0 - widget.iconAnimationController!.value - 1.0),
              0.0,
              0.0),
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75 - 64,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.drawerHighlightItemColor,
                borderRadius: new BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(28),
                ),
              ),
            ),
          ),
        );
      },
    );

    var listItemIcon = Icon(listItem.icon!.icon,
        color: widget.screenIndex == listItem.index
            ? AppTheme.drawerHighlightIconColor
            : AppTheme.drawerIconColor);

    var stack = Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Row(
            children: <Widget>[
              Container(
                width: 6.0,
                height: 46.0,
              ),
              const Padding(
                padding: EdgeInsets.all(4.0),
              ),
              listItemIcon,
              const Padding(
                padding: EdgeInsets.all(4.0),
              ),
              Text(
                listItem.title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: Config.fontSize,
                  color: widget.screenIndex == listItem.index
                      ? AppTheme.drawerHighlightTextColor
                      : AppTheme.drawerTextColor,
                ),
              ),
            ],
          ),
        ),
        widget.screenIndex == listItem.index
            ? animatedBuilder
            : const SizedBox()
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: AppTheme.drawerSplashColor,
        highlightColor: AppTheme.drawerHighlightColor,
        onTap: () {
          navigationToScreen(listItem.index);
        },
        child: stack,
      ),
    );
  }
}
