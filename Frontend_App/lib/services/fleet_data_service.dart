import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FleetDataService {
  static const String _fleetsKey = 'fleet_data';
  static const String _serviceHistoryKey = 'service_history_data';

  // Singleton pattern
  static final FleetDataService _instance = FleetDataService._internal();
  factory FleetDataService() => _instance;
  FleetDataService._internal();

  // Save fleet data to SharedPreferences
  Future<bool> saveFleets(List<Map<String, dynamic>> fleets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fleetsJson = jsonEncode(fleets);
      return await prefs.setString(_fleetsKey, fleetsJson);
    } catch (e) {
      print('Error saving fleets: $e');
      return false;
    }
  }

  // Load fleet data from SharedPreferences
  Future<List<Map<String, dynamic>>> loadFleets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fleetsJson = prefs.getString(_fleetsKey);

      if (fleetsJson != null) {
        final List<dynamic> fleetsList = jsonDecode(fleetsJson);
        return fleetsList.cast<Map<String, dynamic>>();
      }

      // Return sample data if no saved data exists
      return _getSampleFleetData();
    } catch (e) {
      print('Error loading fleets: $e');
      return _getSampleFleetData();
    }
  }

  // Add a new fleet
  Future<bool> addFleet(Map<String, dynamic> fleet) async {
    try {
      final fleets = await loadFleets();

      // Add unique ID if not present
      if (!fleet.containsKey('id')) {
        fleet['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // Add creation timestamp
      fleet['createdAt'] = DateTime.now().toIso8601String();

      fleets.add(fleet);
      return await saveFleets(fleets);
    } catch (e) {
      print('Error adding fleet: $e');
      return false;
    }
  }

  // Update an existing fleet
  Future<bool> updateFleet(
    String fleetId,
    Map<String, dynamic> updatedFleet,
  ) async {
    try {
      final fleets = await loadFleets();
      final index = fleets.indexWhere((fleet) => fleet['id'] == fleetId);

      if (index != -1) {
        updatedFleet['id'] = fleetId; // Preserve ID
        updatedFleet['updatedAt'] = DateTime.now().toIso8601String();
        fleets[index] = updatedFleet;
        return await saveFleets(fleets);
      }

      return false;
    } catch (e) {
      print('Error updating fleet: $e');
      return false;
    }
  }

  // Delete a fleet
  Future<bool> deleteFleet(String fleetId) async {
    try {
      final fleets = await loadFleets();
      fleets.removeWhere((fleet) => fleet['id'] == fleetId);
      return await saveFleets(fleets);
    } catch (e) {
      print('Error deleting fleet: $e');
      return false;
    }
  }

  // Save service history for a specific fleet
  Future<bool> saveServiceHistory(
    String fleetId,
    Map<String, dynamic> serviceData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serviceKey = '${_serviceHistoryKey}_$fleetId';

      // Load existing service history
      final existingJson = prefs.getString(serviceKey);
      List<Map<String, dynamic>> serviceHistory = [];

      if (existingJson != null) {
        final List<dynamic> existingList = jsonDecode(existingJson);
        serviceHistory = existingList.cast<Map<String, dynamic>>();
      }

      // Add timestamp to service data
      serviceData['timestamp'] = DateTime.now().toIso8601String();
      serviceHistory.add(serviceData);

      // Save updated service history
      final serviceJson = jsonEncode(serviceHistory);
      return await prefs.setString(serviceKey, serviceJson);
    } catch (e) {
      print('Error saving service history: $e');
      return false;
    }
  }

  // Load service history for a specific fleet
  Future<List<Map<String, dynamic>>> loadServiceHistory(String fleetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serviceKey = '${_serviceHistoryKey}_$fleetId';
      final serviceJson = prefs.getString(serviceKey);

      if (serviceJson != null) {
        final List<dynamic> serviceList = jsonDecode(serviceJson);
        return serviceList.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      print('Error loading service history: $e');
      return [];
    }
  }

  // Clear all data (useful for testing or reset)
  Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fleetsKey);

      // Remove all service history keys
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith(_serviceHistoryKey)) {
          await prefs.remove(key);
        }
      }

      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  // Get fleet statistics
  Future<Map<String, dynamic>> getFleetStatistics() async {
    try {
      final fleets = await loadFleets();

      final stats = {
        'totalFleets': fleets.length,
        'activeBuses': fleets.where((f) => f['status'] != 'maintenance').length,
        'maintenanceBuses': fleets
            .where((f) => f['status'] == 'maintenance')
            .length,
        'totalRoutes': fleets.map((f) => f['currentRoute']).toSet().length,
        'averageKm': _calculateAverageKm(fleets),
        'lastServiceDates': _getLastServiceDates(fleets),
      };

      return stats;
    } catch (e) {
      print('Error getting fleet statistics: $e');
      return {
        'totalFleets': 0,
        'activeBuses': 0,
        'maintenanceBuses': 0,
        'totalRoutes': 0,
        'averageKm': 0.0,
        'lastServiceDates': [],
      };
    }
  }

  // Private helper methods
  double _calculateAverageKm(List<Map<String, dynamic>> fleets) {
    if (fleets.isEmpty) return 0.0;

    double totalKm = 0.0;
    int validFleets = 0;

    for (var fleet in fleets) {
      final kmString = fleet['kilometerReading']?.toString() ?? '0';
      final km = double.tryParse(kmString);
      if (km != null) {
        totalKm += km;
        validFleets++;
      }
    }

    return validFleets > 0 ? totalKm / validFleets : 0.0;
  }

  List<String> _getLastServiceDates(List<Map<String, dynamic>> fleets) {
    return fleets
        .map((f) => f['lastService']?.toString())
        .where((date) => date != null && date != "No Service Yet")
        .cast<String>()
        .toList();
  }

  // Sample data for new installations
  List<Map<String, dynamic>> _getSampleFleetData() {
    return [
      {
        'id': 'sample_1',
        'busNumber': 'BUS-001',
        'busType': 'City',
        'currentRoute': 'Downtown Loop',
        'kilometerReading': '45230',
        'notes': 'Regular city service',
        'lastService': '15/10/2025',
        'status': 'active',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
        'serviceHistory': {'weekly': [], 'monthly': [], 'yearly': []},
      },
      {
        'id': 'sample_2',
        'busNumber': 'BUS-002',
        'busType': 'Intercity',
        'currentRoute': 'Airport Express',
        'kilometerReading': '67890',
        'notes': 'Express route service',
        'lastService': '12/10/2025',
        'status': 'active',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 20))
            .toIso8601String(),
        'serviceHistory': {'weekly': [], 'monthly': [], 'yearly': []},
      },
    ];
  }
}
