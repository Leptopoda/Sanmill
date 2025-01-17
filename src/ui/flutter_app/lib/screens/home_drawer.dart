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

part of 'package:sanmill/screens/navigation_home_screen.dart';

enum DrawerIndex {
  humanVsAi,
  humanVsHuman,
  aiVsAi,
  preferences,
  ruleSettings,
  personalization,
  feedback,
  Help,
  About
}

class DrawerListItem {
  const DrawerListItem({
    required this.index,
    required this.title,
    required this.icon,
  });

  final DrawerIndex index;
  final String title;
  final Icon icon;
}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    Key? key,
    required this.screenIndex,
    required this.iconAnimationController,
    required this.callBackIndex,
    required this.items,
  }) : super(key: key);

  final AnimationController iconAnimationController;
  final DrawerIndex screenIndex;
  final Function(DrawerIndex) callBackIndex;
  final List<DrawerListItem> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(Config.drawerBackgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _DrawerHeader(
            iconAnimationController: iconAnimationController,
          ),
          Divider(height: 1, color: AppTheme.drawerDividerColor),
          ListView.builder(
            padding: const EdgeInsets.only(top: 4.0),
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: _buildChildren,
          ),
          //drawFooter,
        ],
      ),
    );
  }

  Future<void> navigationToScreen(DrawerIndex index) async {
    callBackIndex(index);
  }

  Widget _buildChildren(BuildContext context, int index) {
    final listItem = items[index];
    final bool isSelected = screenIndex == listItem.index;

    final bool ltr =
        getBidirectionality(context) == Bidirectionality.leftToRight;
    const double radius = 28.0;
    final animatedBuilder = AnimatedBuilder(
      animation: iconAnimationController,
      builder: (BuildContext context, Widget? child) {
        return Transform(
          transform: Matrix4.translationValues(
            (MediaQuery.of(context).size.width * 0.75 - 64) *
                (1.0 - iconAnimationController.value - 1.0),
            0.0,
            0.0,
          ),
          child: child,
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75 - 64,
        height: 46,
        decoration: BoxDecoration(
          color: Color(Config.drawerHighlightItemColor),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ltr ? 0 : radius),
            topRight: Radius.circular(ltr ? radius : 0),
            bottomLeft: Radius.circular(ltr ? 0 : radius),
            bottomRight: Radius.circular(ltr ? radius : 0),
          ),
        ),
      ),
    );

    final listItemIcon = Icon(
      listItem.icon.icon,
      color: isSelected
          ? Color(Config.drawerTextColor) // TODO: drawerHighlightTextColor
          : Color(Config.drawerTextColor),
    );

    final child = Row(
      children: <Widget>[
        const SizedBox(height: 46.0, width: 6.0),
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
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: Config.fontSize,
            color: isSelected
                ? Color(
                    Config.drawerTextColor,
                  ) // TODO: drawerHighlightTextColor
                : Color(Config.drawerTextColor),
          ),
        ),
      ],
    );

    return InkWell(
      splashColor: AppTheme.drawerSplashColor,
      highlightColor: AppTheme.drawerHighlightColor,
      onTap: () => navigationToScreen(listItem.index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: isSelected
            ? Stack(
                children: <Widget>[
                  child,
                  animatedBuilder,
                ],
              )
            : child,
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    Key? key,
    required this.iconAnimationController,
  }) : super(key: key);

  final AnimationController iconAnimationController;

  @override
  Widget build(BuildContext context) {
    const String tag = "[home_drawer]";

    final List<Color> animatedTextsColors = [
      Color(Config.drawerTextColor),
      Colors.black,
      Colors.blue,
      Colors.yellow,
      Colors.red,
      Color(Config.darkBackgroundColor),
      Color(Config.boardBackgroundColor),
      Color(Config.drawerHighlightItemColor),
    ];

    final rotationTransition = RotationTransition(
      turns: AlwaysStoppedAnimation<double>(
        Tween<double>(begin: 0.0, end: 24.0)
                .animate(
                  CurvedAnimation(
                    parent: iconAnimationController,
                    curve: Curves.fastOutSlowIn,
                  ),
                )
                .value /
            360,
      ),
    );

    final scaleTransition = ScaleTransition(
      scale: AlwaysStoppedAnimation<double>(
        1.0 - (iconAnimationController.value) * 0.2,
      ),
      child: rotationTransition,
    );

    final animatedBuilder = AnimatedBuilder(
      animation: iconAnimationController,
      builder: (_, __) => scaleTransition,
    );

    final animation = GestureDetector(
      child: AnimatedTextKit(
        animatedTexts: [
          ColorizeAnimatedText(
            S.of(context).appName,
            textStyle: TextStyle(
              fontSize: Config.fontSize + 16,
              fontWeight: FontWeight.w600,
            ),
            colors: animatedTextsColors,
            speed: const Duration(seconds: 3),
          ),
        ],
        pause: const Duration(seconds: 3),
        repeatForever: true,
        stopPauseOnTap: true,
        onTap: () => debugPrint("$tag DoubleTap to enable developer mode."),
      ),
      onDoubleTap: () {
        Developer.developerModeEnabled = true;
        debugPrint("$tag Developer mode enabled.");
      },
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // TODO: can animatedBuilder be removed? does not appear in the widget tree
          animatedBuilder,
          Padding(
            padding: EdgeInsets.only(top: isLargeScreen ? 30 : 8, left: 4),
            child: ExcludeSemantics(child: animation),
          ),
        ],
      ),
    );
  }
}
