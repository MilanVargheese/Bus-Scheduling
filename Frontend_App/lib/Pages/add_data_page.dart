import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../Pages/schedule_result_page.dart';
import '../services/prediction_schedule_service.dart';
import '../services/schedule_storage_service.dart';

class AddDataPage extends StatefulWidget {
  const AddDataPage({Key? key}) : super(key: key);

  @override
  State<AddDataPage> createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  // Green color palette matching the app theme
  static const Color primaryGreen = Color(0xFF00A86B);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color backgroundGreen = Color(0xFFF1F8E9);

  String? _selectedFileName;
  String? _filePath;
  bool _isUploading = false;
  List<Map<String, String>> _uploadHistory = [];
  int _capacity = 50;
  Map<String, dynamic>? _currentSchedule;
  List<int> _currentBuses = [];
  bool _refinementReady = false;
  final ScheduleStorageService _scheduleStorage = ScheduleStorageService();

  @override
  void initState() {
    super.initState();
    _loadCurrentSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Data',
          style: TextStyle(
            color: Color(0xFF00A86B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF00A86B)),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9FBE7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 30),
            _buildUploadSection(),
            const SizedBox(height: 30),
            if (_uploadHistory.isNotEmpty) _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.upload_file,
                  color: primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CSV Data Upload',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Upload your transport data files',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Supported formats: CSV files with bus schedules, route data, or fleet information',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Upload Area
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: backgroundGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryGreen.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFileName != null
                        ? Icons.check_circle_outline
                        : Icons.cloud_upload_outlined,
                    size: 48,
                    color: _selectedFileName != null
                        ? lightGreen
                        : primaryGreen.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFileName != null
                        ? 'File Selected:'
                        : 'Tap to Select CSV File',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedFileName != null
                          ? lightGreen
                          : primaryGreen,
                    ),
                  ),
                  if (_selectedFileName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: lightGreen.withOpacity(0.3)),
                      ),
                      child: Text(
                        _selectedFileName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Drag & drop or tap to browse files',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (_currentSchedule != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _refinementReady
                    ? Colors.orange.withOpacity(0.08)
                    : Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _refinementReady
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _refinementReady ? Icons.schedule : Icons.warning_amber,
                    color: _refinementReady ? Colors.orange : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _refinementReady
                          ? 'Refinement mode enabled: '
                                '${_currentSchedule!['fileName'] ?? 'Current schedule'}'
                          : 'Refinement disabled: add a bus count column in the schedule CSV.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _refinementReady ? Colors.orange : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_currentSchedule != null) const SizedBox(height: 20),

          // Upload Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedFileName != null && !_isUploading
                  ? _uploadFile
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _selectedFileName != null ? 2 : 0,
              ),
              child: _isUploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Uploading...'),
                      ],
                    )
                  : Text(
                      _selectedFileName != null
                          ? 'Upload File'
                          : 'Select a file first',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
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
            'Upload History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _uploadHistory.length,
            itemBuilder: (context, index) {
              final item = _uploadHistory[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: primaryGreen, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['filename']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Uploaded: ${item['date']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Success',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFileName = result.files.first.name;
          _filePath = result.files.first.path;
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting file: $e', isError: true);
    }
  }

  Future<void> _uploadFile() async {
    if (_filePath == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(_filePath!);
      final result = await PredictionScheduleService.uploadAndPredict(
        filePath: _filePath!,
        capacity: _capacity,
        currentBuses: _refinementReady ? _currentBuses : const [],
        scheduleFilePath: _currentSchedule?['filePath']?.toString(),
      );

      setState(() {
        _uploadHistory.insert(0, {
          'filename': _selectedFileName!,
          'date': DateTime.now().toString().split(' ')[0],
        });
        _selectedFileName = null;
        _filePath = null;
        _isUploading = false;
      });

      _showSnackBar('Schedule generated successfully!');

      if (!mounted) return;
      final schedulePayload = result['schedule'] as Map<String, dynamic>? ?? {};
      final schedule = (schedulePayload['schedule'] as List?) ?? [];
      final summary =
          (schedulePayload['summary'] as Map<String, dynamic>?) ?? {};

      debugPrint('Schedule length: ${schedule.length}');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ScheduleResultPage(schedule: schedule, summary: summary),
        ),
      );
    } on PredictionScheduleException catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showSnackBar('Upload failed: $e', isError: true);
    }
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

  Future<void> _loadCurrentSchedule() async {
    final stored = await _scheduleStorage.loadLastScheduleUpload();
    if (!mounted) return;
    setState(() {
      _currentSchedule = stored;
      _currentBuses = _scheduleStorage.extractCurrentBuses(stored);
      _refinementReady = _currentBuses.isNotEmpty;
    });
  }
}
