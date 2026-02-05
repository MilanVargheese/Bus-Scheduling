import 'package:flutter/material.dart';

class BusTypeModel {
  String name;
  String iconPath;
  Color boxColor;

  BusTypeModel({
    required this.name,
    required this.iconPath,
    required this.boxColor,
  });

  static List<BusTypeModel> getBusTypes() {
    List<BusTypeModel> busTypes = [];
    busTypes.add(
      BusTypeModel(
        name: 'Express',
        iconPath: 'assets/icons/express_bus.svg', // Change to your icon
        boxColor: Color(0xff92A3FD),
      ),
    );
    busTypes.add(
      BusTypeModel(
        name: 'Sleeper',
        iconPath: 'assets/icons/sleeper_bus.svg', // Change to your icon
        boxColor: Color(0xffC58BF2),
      ),
    );
    busTypes.add(
      BusTypeModel(
        name: 'AC Seater',
        iconPath: 'assets/icons/ac_bus.svg', // Change to your icon
        boxColor: Color(0xff92A3FD),
      ),
    );
    busTypes.add(
      BusTypeModel(
        name: 'City Bus',
        iconPath: 'assets/icons/city_bus.svg', // Change to your icon
        boxColor: Color(0xffC58BF2),
      ),
    );
    return busTypes;
  }
}
