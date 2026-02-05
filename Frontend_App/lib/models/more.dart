import 'package:flutter/material.dart';

class MoreModel {
  String name;
  String iconPath;
  Color boxColor;

  MoreModel({
    required this.name,
    required this.iconPath,
    required this.boxColor,
  });

  static List<MoreModel> getMoreOptions() {
    List<MoreModel> moreOptions = [];

    moreOptions.add(
      MoreModel(
        name: 'Bus Search',
        iconPath: 'assets/icons/plate.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    moreOptions.add(
      MoreModel(
        name: 'Bus Search',
        iconPath: 'assets/icons/pancakes.svg',
        boxColor: Color(0xffEEA4CE),
      ),
    );

    moreOptions.add(
      MoreModel(
        name: 'Bus Search',

        iconPath: 'assets/icons/pie.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    moreOptions.add(
      MoreModel(
        name: 'Bus Search',
        iconPath: 'assets/icons/orange-snacks.svg',
        boxColor: Color(0xffEEA4CE),
      ),
    );

    return moreOptions;
  }
}
