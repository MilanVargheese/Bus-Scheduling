import 'package:flutter/material.dart';

class PlannerModel {
  String name;
  String imagePath;
  Color boxColor;

  PlannerModel({
    required this.name,
    required this.imagePath,
    required this.boxColor,
  });

  static List<PlannerModel> getPlanners() {
    List<PlannerModel> planners = [];

    planners.add(
      PlannerModel(
        name: 'View Schedule',
        imagePath: 'assets/icons/Search.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );
    planners.add(
      PlannerModel(
        name: 'Create Schedule',
        imagePath: 'assets/icons/create.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );
    planners.add(
      PlannerModel(
        name: 'Depo Stats',
        imagePath: 'assets/icons/stats.svg',
        boxColor: Color(0xff9DCEFF),
      ),
    );

    return planners;
  }
}
