// In models/trip_model.dart

class TripModel {
  String routeName;
  String busNumber;
  String departureTime;
  String status;
  bool boxIsSelected;

  TripModel({
    required this.routeName,
    required this.busNumber,
    required this.departureTime,
    required this.status,
    required this.boxIsSelected,
  });

  static List<TripModel> getUpcomingTrips() {
    List<TripModel> trips = [];
    trips.add(
      TripModel(
        routeName: 'Kottayam - Ernakulam',
        busNumber: 'KL-34 A 5566',
        departureTime: '10:30 AM',
        status: 'On Time',
        boxIsSelected: true,
      ),
    );
    trips.add(
      TripModel(
        routeName: 'Trivandrum - Thrissur',
        busNumber: 'KL-01 C 1234',
        departureTime: '11:00 AM',
        status: 'Delayed',
        boxIsSelected: false,
      ),
    );
    trips.add(
      TripModel(
        routeName: 'Calicut - Kannur',
        busNumber: 'KL-11 B 8008',
        departureTime: '12:15 PM',
        status: 'On Time',
        boxIsSelected: false,
      ),
    );
    return trips;
  }
}

// In models/quick_action_model.dart
