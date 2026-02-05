import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/schedule_storage_service.dart';

class ManageFleetPage extends StatefulWidget {
  const ManageFleetPage({Key? key}) : super(key: key);

  @override
  State<ManageFleetPage> createState() => _ManageFleetPageState();
}

class _ManageFleetPageState extends State<ManageFleetPage> {
  // Green color palette for the minimalist design
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color mediumGreen = Color(0xFF388E3C);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color backgroundGreen = Color(0xFFF1F8E9);
  static const Color lightBackgroundGreen = Color(0xFFF9FBE7);

  List<Map<String, dynamic>> fleets = [
    // Empty initially to show empty state
    // Uncomment below for testing with data
    /*
    {
      'busNumber': 'KL-34-A-5566',
      'busType': 'City',
      'currentRoute': 'Kottayam - Ernakulam',
      'lastService': '2024-10-15',
      'kmReading': 15420,
      'notes': 'Regular maintenance completed',
    },
    {
      'busNumber': 'KL-01-C-1234', 
      'busType': 'Intercity',
      'currentRoute': 'Trivandrum - Thrissur',
      'lastService': null,
      'kmReading': 8950,
      'notes': 'New bus, first service pending',
    },
    */
  ];

  Map<String, dynamic>? _lastScheduleUpload;
  final ScheduleStorageService _scheduleStorage = ScheduleStorageService();

  @override
  void initState() {
    super.initState();
    _loadLastSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fleet Management',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Upload current schedule',
            onPressed: _pickScheduleFile,
            icon: const Icon(Icons.upload_file),
          ),
          if (fleets.isNotEmpty)
            TextButton(
              onPressed: () => _showAddFleetDialog(),
              child: const Text(
                '+ Add Fleet',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF9FBE7),
      body: fleets.isEmpty ? _buildEmptyState() : _buildFleetList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 80,
            color: primaryGreen.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No fleets added yet.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _showAddFleetDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              '+ Add Fleet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _pickScheduleFile,
            icon: const Icon(Icons.upload_file, color: primaryGreen),
            label: const Text(
              'Upload current schedule',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fleets.length + (_lastScheduleUpload != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (_lastScheduleUpload != null && index == 0) {
          return _buildScheduleUploadCard(_lastScheduleUpload!);
        }
        final fleet = fleets[index - (_lastScheduleUpload != null ? 1 : 0)];
        return _buildFleetCard(fleet);
      },
    );
  }

  Widget _buildScheduleUploadCard(Map<String, dynamic> scheduleInfo) {
    final fileName = scheduleInfo['fileName'] as String? ?? 'Schedule.csv';
    final uploadedAt = scheduleInfo['uploadedAt'] as String? ?? '';
    final rows = (scheduleInfo['rows'] as List?) ?? [];
    final formattedDate = uploadedAt.isNotEmpty
        ? DateTime.tryParse(uploadedAt)?.toString().split(' ')[0] ?? uploadedAt
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current schedule upload',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.insert_drive_file, 'File', fileName),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.calendar_today, 'Uploaded', formattedDate),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text(
              'No schedule rows available yet.',
              style: TextStyle(color: Colors.black54),
            ),
          if (rows.isNotEmpty) _buildScheduleTable(rows),
        ],
      ),
    );
  }

  Widget _buildScheduleTable(List rows) {
    final headers = _extractHeaders(rows);
    final previewRows = rows.take(8).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers
            .map((header) => DataColumn(label: Text(header)))
            .toList(),
        rows: previewRows.map<DataRow>((row) {
          final data = row is Map<String, dynamic> ? row : <String, dynamic>{};
          return DataRow(
            cells: headers
                .map((header) => DataCell(Text(data[header]?.toString() ?? '')))
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  List<String> _extractHeaders(List rows) {
    if (rows.isEmpty) return ['trip_index', 'current_buses'];
    final first = rows.first;
    if (first is Map<String, dynamic>) {
      return first.keys.map((key) => key.toString()).toList();
    }
    return ['trip_index', 'current_buses'];
  }

  Future<void> _loadLastSchedule() async {
    final info = await _scheduleStorage.loadLastScheduleUpload();
    if (!mounted) return;
    setState(() {
      _lastScheduleUpload = info;
    });
  }

  Future<void> _pickScheduleFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final path = file.path ?? '';
        final rows = await _parseScheduleCsv(path);
        await _scheduleStorage.saveScheduleUpload(
          fileName: file.name,
          filePath: path,
          rows: rows,
        );
        await _loadLastSchedule();
        _showSnackBar('Schedule uploaded successfully!');
      }
    } catch (e) {
      _showSnackBar('Failed to upload schedule: $e', isError: true);
    }
  }

  Future<List<Map<String, dynamic>>> _parseScheduleCsv(String path) async {
    if (path.isEmpty) return [];
    final file = File(path);
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    final lines = content
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return [];

    final headers = _splitCsvLine(lines.first);
    final List<Map<String, dynamic>> rows = [];
    for (final line in lines.skip(1)) {
      final values = _splitCsvLine(line);
      final Map<String, dynamic> row = {};
      for (int i = 0; i < headers.length; i++) {
        row[headers[i]] = i < values.length ? values[i] : '';
      }
      rows.add(row);
    }
    return rows;
  }

  List<String> _splitCsvLine(String line) {
    return line
        .split(',')
        .map((value) => value.trim().replaceAll('"', ''))
        .toList();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFleetCard(Map<String, dynamic> fleet) {
    final lastService = fleet['lastService'];
    final formattedDate = lastService != null
        ? DateTime.parse(lastService).toString().split(' ')[0]
        : 'No Service Yet';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fleet['busNumber'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: lightGreen.withOpacity(0.3)),
                ),
                child: Text(
                  fleet['busType'],
                  style: TextStyle(
                    color: mediumGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.route, 'Current Route', fleet['currentRoute']),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.build_outlined, 'Last Service', formattedDate),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showServiceHistoryModal(fleet),
              style: TextButton.styleFrom(
                foregroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Edit Service History',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddFleetDialog() {
    final formKey = GlobalKey<FormState>();
    String busNumber = '';
    String busType = 'City';
    String currentRoute = '';
    String kmReading = '';
    String notes = '';

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
                    'Add New Fleet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bus Number
                  TextFormField(
                    decoration: _inputDecoration('Bus Number'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => busNumber = value ?? '',
                  ),
                  const SizedBox(height: 16),

                  // Bus Type Dropdown
                  DropdownButtonFormField<String>(
                    value: busType,
                    decoration: _inputDecoration('Bus Type'),
                    items: ['City', 'Intercity', 'Express'].map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? value) => busType = value ?? 'City',
                  ),
                  const SizedBox(height: 16),

                  // Current Route
                  TextFormField(
                    decoration: _inputDecoration('Current Route'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => currentRoute = value ?? '',
                  ),
                  const SizedBox(height: 16),

                  // Current Kilometer Reading
                  TextFormField(
                    decoration: _inputDecoration('Current Kilometer Reading'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => kmReading = value ?? '',
                  ),
                  const SizedBox(height: 16),

                  // Optional Notes
                  TextFormField(
                    decoration: _inputDecoration('Optional Notes'),
                    maxLines: 3,
                    onSaved: (value) => notes = value ?? '',
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
                              fleets.add({
                                'busNumber': busNumber,
                                'busType': busType,
                                'currentRoute': currentRoute,
                                'lastService': null,
                                'kmReading': int.parse(kmReading),
                                'notes': notes,
                              });
                            });
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add Fleet'),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  void _showServiceHistoryModal(Map<String, dynamic> fleet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service History - ${fleet['busNumber']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(child: ServiceHistoryContent(fleet: fleet)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ServiceHistoryContent extends StatefulWidget {
  final Map<String, dynamic> fleet;

  const ServiceHistoryContent({Key? key, required this.fleet})
    : super(key: key);

  @override
  State<ServiceHistoryContent> createState() => _ServiceHistoryContentState();
}

class _ServiceHistoryContentState extends State<ServiceHistoryContent> {
  bool weeklyExpanded = false;
  bool monthlyExpanded = false;
  bool yearlyExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildServiceSection(
            'Weekly Service',
            const Color(0xFFE8F5E8),
            const Color(0xFF4CAF50),
            weeklyExpanded,
            () => setState(() => weeklyExpanded = !weeklyExpanded),
            _buildWeeklyServiceForm(),
          ),
          const SizedBox(height: 16),
          _buildServiceSection(
            'Monthly Service',
            const Color(0xFFE0F2E0),
            const Color(0xFF388E3C),
            monthlyExpanded,
            () => setState(() => monthlyExpanded = !monthlyExpanded),
            _buildMonthlyServiceForm(),
          ),
          const SizedBox(height: 16),
          _buildServiceSection(
            'Yearly Service',
            const Color(0xFFD8E8D8),
            const Color(0xFF1B5E20),
            yearlyExpanded,
            () => setState(() => yearlyExpanded = !yearlyExpanded),
            _buildYearlyServiceForm(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Save service record logic
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service record saved successfully!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Service Record',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildServiceSection(
    String title,
    Color backgroundColor,
    Color accentColor,
    bool isExpanded,
    VoidCallback onTap,
    Widget content,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }

  Widget _buildWeeklyServiceForm() {
    return Column(
      children: [
        _buildDatePicker('Service Date'),
        const SizedBox(height: 12),
        _buildTextField('Kilometer Reading', TextInputType.number),
        const SizedBox(height: 12),
        _buildChecklistItem('Oil Level Check'),
        _buildChecklistItem('Tire Pressure Check'),
        _buildChecklistItem('Basic Visual Inspection'),
        const SizedBox(height: 12),
        _buildTextField('Notes', TextInputType.text, maxLines: 3),
      ],
    );
  }

  Widget _buildMonthlyServiceForm() {
    return Column(
      children: [
        _buildDatePicker('Service Date'),
        const SizedBox(height: 12),
        _buildTextField('Kilometer Reading', TextInputType.number),
        const SizedBox(height: 12),
        _buildChecklistItem('Engine Oil Change'),
        _buildChecklistItem('Brake System Check'),
        _buildChecklistItem('Battery Check'),
        _buildChecklistItem('Air Filter Inspection'),
        _buildChecklistItem('Coolant Level Check'),
        const SizedBox(height: 12),
        _buildTextField('Notes', TextInputType.text, maxLines: 3),
      ],
    );
  }

  Widget _buildYearlyServiceForm() {
    return Column(
      children: [
        _buildDatePicker('Service Date'),
        const SizedBox(height: 12),
        _buildTextField('Kilometer Reading', TextInputType.number),
        const SizedBox(height: 12),
        _buildChecklistItem('Complete Engine Overhaul'),
        _buildChecklistItem('Transmission Service'),
        _buildChecklistItem('Suspension System Check'),
        _buildChecklistItem('Electrical System Inspection'),
        _buildChecklistItem('Body and Paint Inspection'),
        _buildChecklistItem('Safety Equipment Check'),
        const SizedBox(height: 12),
        _buildTextField('Notes', TextInputType.text, maxLines: 3),
      ],
    );
  }

  Widget _buildDatePicker(String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        title: Text(label),
        subtitle: Text(DateTime.now().toString().split(' ')[0]),
        trailing: const Icon(Icons.calendar_today),
        onTap: () {
          // Date picker implementation
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextInputType keyboardType, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckboxListTile(
        title: Text(label),
        value: false,
        onChanged: (bool? value) {
          // Checkbox logic
        },
        activeColor: const Color(0xFF4CAF50),
      ),
    );
  }
}
