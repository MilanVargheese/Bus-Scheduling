import 'package:flutter/material.dart';

class QuickActionModel {
  String name;
  String imagePath;
  Color boxColor;

  QuickActionModel({
    required this.name,
    required this.imagePath,
    required this.boxColor,
  });

  static List<QuickActionModel> getQuickActions() {
    List<QuickActionModel> actions = [];
    actions.add(
      QuickActionModel(
        name: 'Book Ticket',
        imagePath: 'assets/icons/ticket.svg', // Change to your icon
        boxColor: Color(0xff92A3FD),
      ),
    );
    actions.add(
      QuickActionModel(
        name: 'Track Bus',
        imagePath: 'assets/icons/bus_location.svg', // Change to your icon
        boxColor: Color(0xffC58BF2),
      ),
    );
    actions.add(
      QuickActionModel(
        name: 'All Routes',
        imagePath: 'assets/icons/routes.svg', // Change to your icon
        boxColor: Color(0xff92A3FD),
      ),
    );
    return actions;
  }
}

// In models/bus_type_model.dart
