import 'package:flutter/material.dart';

class BusSchedulePage extends StatefulWidget {
  const BusSchedulePage({super.key});

  @override
  State<BusSchedulePage> createState() => _BusSchedulePageState();
}

class _BusSchedulePageState extends State<BusSchedulePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Empty list to start with - users will add their own schedules
  List<Map<String, dynamic>> busSchedules = [];

  List<Map<String, dynamic>> get filteredSchedules {
    if (_searchQuery.isEmpty) {
      return busSchedules;
    }
    return busSchedules.where((schedule) {
      return schedule['route'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          schedule['busNumber'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Bus Schedules',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00A86B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: busSchedules.isEmpty
            ? null
            : [
                TextButton(
                  onPressed: () => _showAddScheduleDialog(),
                  child: const Text(
                    '+ Add Schedule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
      ),
      body: busSchedules.isEmpty ? _buildEmptyState() : _buildScheduleList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 80,
            color: const Color(0xFF00A86B).withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No schedules added yet.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first bus schedule to get started!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _showAddScheduleDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A86B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Add First Schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return Column(
      children: [
        // Search Section
        Container(
          color: const Color(0xFF00A86B),
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search routes or bus numbers...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF00A86B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),

        // Schedule Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF00A86B)),
              const SizedBox(width: 8),
              Text(
                'Today\'s Schedule - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // Schedule Table
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A86B),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Route',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Bus #',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Departure Time',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Table Data
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = filteredSchedules[index];
                      final isEven = index % 2 == 0;

                      return Container(
                        color: isEven ? Colors.grey[50] : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              // Route
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      schedule['route'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      schedule['duration'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bus Number
                              Expanded(
                                flex: 3,
                                child: Text(
                                  schedule['busNumber'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              // Departure Time
                              Expanded(
                                flex: 3,
                                child: Text(
                                  schedule['departure'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Info Section
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoCard(
                icon: Icons.directions_bus,
                label: 'Total Routes',
                value: '${busSchedules.length}',
              ),
              _buildInfoCard(
                icon: Icons.schedule,
                label: 'Scheduled',
                value: '${busSchedules.length}',
              ),
              _buildInfoCard(
                icon: Icons.route,
                label: 'Active',
                value: '${busSchedules.length}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddScheduleDialog() {
    final formKey = GlobalKey<FormState>();
    String route = '';
    String busNumber = '';
    String departure = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Bus Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A86B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Route
                  TextFormField(
                    decoration: _inputDecoration(
                      'Route (e.g., City Center - Airport)',
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => route = value ?? '',
                  ),
                  const SizedBox(height: 16),

                  // Bus Number
                  TextFormField(
                    decoration: _inputDecoration('Bus Number (e.g., BUS-001)'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => busNumber = value ?? '',
                  ),
                  const SizedBox(height: 16),

                  // Departure Time
                  TextFormField(
                    decoration: _inputDecoration(
                      'Departure Time (e.g., 08:30)',
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => departure = value ?? '',
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            formKey.currentState?.save();

                            setState(() {
                              busSchedules.add({
                                'route': route,
                                'busNumber': busNumber,
                                'departure': departure,
                                'duration': 'N/A', // No longer calculated
                              });
                            });
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A86B),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Schedule'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF00A86B)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00A86B)),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00A86B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF00A86B), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF00A86B),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
