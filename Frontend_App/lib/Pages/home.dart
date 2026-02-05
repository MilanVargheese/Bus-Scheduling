import 'package:flutter/material.dart';
import 'manage_fleet.dart';
import 'add_data_page.dart';
import 'bus_schedule_page.dart';
import 'result_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Dark mode state
  bool _isDarkMode = false;

  // Hardcoded demo data
  final List<Map<String, dynamic>> schedules = [
    {"name": "View Schedule", "icon": Icons.search, "color": Colors.blue},
    {"name": "Manage Fleet", "icon": Icons.add, "color": Colors.purple},
    {"name": "Depot Stats", "icon": Icons.bar_chart, "color": Colors.orange},
  ];

  final List<Map<String, dynamic>> categories = [
    {
      "name": "Create Schedule",
      "color": Colors.red,
      "icon": Icons.directions_bus,
    },
    {"name": "Add Data", "color": Colors.blue, "icon": Icons.upload_file},
    {"name": "Result", "color": Colors.green, "icon": Icons.assessment},
  ];

  final List<Map<String, dynamic>> summaryItems = [
    {
      "name": "Active Buses",
      "details": "25 Running",
      "icon": Icons.directions_bus,
      "color": Colors.green,
    },
    {
      "name": "Total Routes",
      "details": "8 Active",
      "icon": Icons.alt_route,
      "color": Colors.blue,
    },
    {
      "name": "Efficiency",
      "details": "94.2%",
      "icon": Icons.trending_up,
      "color": Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _searchField(),
            const SizedBox(height: 40),
            _scheduleSection(),
            const SizedBox(height: 40),
            _categoriesSection(),
            const SizedBox(height: 40),
            _popularRoutesSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A86B).withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 20),
            Expanded(child: _buildNavigationSection()),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00A86B).withOpacity(0.1),
            const Color(0xFF00A86B).withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00A86B).withOpacity(0.15),
                border: Border.all(color: const Color(0xFF00A86B), width: 2),
              ),
              child: const Icon(
                Icons.person,
                size: 30,
                color: Color(0xFF00A86B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Admin User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00A86B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ernakulam Depot',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationSection() {
    final navigationItems = [
      {'icon': Icons.home_outlined, 'title': 'Dashboard', 'isActive': true},
      {
        'icon': Icons.directions_bus_outlined,
        'title': 'Fleet Management',
        'isActive': false,
      },
      {
        'icon': Icons.calendar_month_outlined,
        'title': 'Schedule Prediction',
        'isActive': false,
      },
      {'icon': Icons.input_outlined, 'title': 'Data Input', 'isActive': false},
      {
        'icon': Icons.analytics_outlined,
        'title': 'Reports / Analytics',
        'isActive': false,
      },
      {'icon': Icons.settings_outlined, 'title': 'Settings', 'isActive': false},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: navigationItems.map((item) {
        return _buildNavigationItem(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          isActive: item['isActive'] as bool,
          trailing: item['title'] == 'Settings'
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A86B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.tune,
                    size: 12,
                    color: const Color(0xFF00A86B),
                  ),
                )
              : item['title'] == 'Data Input'
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.upload_file, size: 12, color: Colors.blue),
                )
              : null,
          onTap: () {
            if (item['title'] == 'Fleet Management') {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageFleetPage(),
                ),
              );
            } else if (item['title'] == 'Data Input') {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDataPage()),
              );
            } else if (item['title'] == 'Settings') {
              Navigator.pop(context); // Close drawer
              _showSettingsDialog();
            } else {
              Navigator.pop(context); // Close drawer for now
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item['title']} coming soon!'),
                  backgroundColor: const Color(0xFF00A86B),
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isActive
            ? const Color(0xFF00A86B).withOpacity(0.1)
            : Colors.transparent,
        border: isActive
            ? Border.all(color: const Color(0xFF00A86B).withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFF00A86B).withOpacity(0.15)
                : Colors.grey.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? const Color(0xFF00A86B) : Colors.grey[600],
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF00A86B) : Colors.grey[700],
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Divider(color: Colors.grey[300], thickness: 1),
          const SizedBox(height: 12),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
              ),
              child: Icon(
                Icons.logout_outlined,
                size: 20,
                color: Colors.red[600],
              ),
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.red[600],
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logout functionality coming soon!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Text(
            'v1.0.0 - Smart Scheduler',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Column _scheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'Bus Schedules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(schedules.length, (index) {
              final schedule = schedules[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (schedule["name"] == "View Schedule") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BusSchedulePage(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: schedule["color"].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          schedule["icon"],
                          size: 28,
                          color: schedule["color"],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          schedule["name"],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: schedule["color"],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Column _categoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(categories.length, (index) {
              final cat = categories[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (index == 0) {
                      // First category (Manage fleet)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageFleetPage(),
                        ),
                      );
                    } else if (index == 1) {
                      // Second category (Add Data)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddDataPage(),
                        ),
                      );
                    } else if (index == 2) {
                      // Third category (Result)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResultPage(),
                        ),
                      );
                    }
                    // Add more navigation logic for other categories if needed
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: cat["color"].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat["icon"], size: 28, color: cat["color"]),
                        const SizedBox(height: 8),
                        Text(
                          cat["name"],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: cat["color"],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Column _popularRoutesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(summaryItems.length, (index) {
              final item = summaryItems[index];
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: item["color"].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item["icon"], size: 28, color: item["color"]),
                      const SizedBox(height: 6),
                      Text(
                        item["name"],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: item["color"],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        item["details"],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: item["color"],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Container _searchField() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          hintText: 'Search Buses, Routes...',
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.blue, size: 22),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune, color: Colors.blue, size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text(
        "Bus Scheduler",
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu, size: 20, color: Colors.white),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          width: 40,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            size: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.settings,
                    color: const Color(0xFF00A86B),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A86B),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A86B).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00A86B).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: _isDarkMode
                                ? Colors.yellow[300]
                                : Colors.orange[700],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isDarkMode ? 'Dark Mode' : 'Light Mode',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isDarkMode
                                    ? 'Switch to Light Mode'
                                    : 'Switch to Dark Mode',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isDarkMode,
                            onChanged: (bool value) {
                              setDialogState(() {
                                _isDarkMode = value;
                              });
                              setState(() {
                                _isDarkMode = value;
                              });
                            },
                            activeColor: const Color(0xFF00A86B),
                            activeTrackColor: const Color(
                              0xFF00A86B,
                            ).withOpacity(0.3),
                            inactiveThumbColor: Colors.grey[400],
                            inactiveTrackColor: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'More settings options coming soon!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isDarkMode
                              ? 'Dark mode enabled!'
                              : 'Light mode enabled!',
                        ),
                        backgroundColor: const Color(0xFF00A86B),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A86B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
