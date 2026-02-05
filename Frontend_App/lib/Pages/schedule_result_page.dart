import 'package:flutter/material.dart';

import '../models/schedule_result.dart';

class ScheduleResultPage extends StatelessWidget {
  final List<dynamic> schedule;
  final Map<String, dynamic> summary;

  const ScheduleResultPage({
    super.key,
    required this.schedule,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleRows = _parseSchedule(schedule);
    final peakTrips = _getPeakTrips(scheduleRows);
    final hasRefinement = summary["current_total_buses"] != null;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Schedule Results',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00A86B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: scheduleRows.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: scheduleRows.length + (hasRefinement ? 2 : 1),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildPeakHoursCard(peakTrips);
                }
                if (hasRefinement && index == 1) {
                  return _buildImpactSummary(summary);
                }
                final scheduleIndex = index - (hasRefinement ? 2 : 1);
                final item = scheduleRows[scheduleIndex];
                return _buildScheduleCard(item);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_outlined, size: 80, color: Color(0xFF00A86B)),
          SizedBox(height: 16),
          Text(
            'No schedule available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Try another CSV or adjust the capacity.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleRow item) {
    final timeLabel = _formatTimeLabel(item.timestamp);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeLabel ?? 'Trip ${item.tripIndex + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00A86B),
            ),
          ),
          const SizedBox(height: 12),
          if (item.currentBuses != null)
            _buildRow(
              'current buses → optimized',
              '${item.currentBuses} → ${item.busesAssigned} '
                  '(${_formatDelta(item.deltaBuses)})',
            ),
          if (item.currentLoadFactor != null)
            _buildRow(
              'load factor change',
              '${item.currentLoadFactor!.toStringAsFixed(2)} → '
                  '${item.loadFactor.toStringAsFixed(2)}',
            ),
          _buildRow('p90 demand', item.p90Demand.toStringAsFixed(2)),
          _buildRow('buses assigned', item.busesAssigned.toString()),
          _buildRow('extra buses', item.extraBuses.toString()),
          _buildRow('load factor', item.loadFactor.toStringAsFixed(2)),
          _buildRow(
            'headway change',
            '${item.baseHeadwayMinutes.toStringAsFixed(1)} → '
                '${item.headwayMinutes.toStringAsFixed(1)} min '
                '(x${item.headwayMultiplier.toStringAsFixed(2)})',
          ),
          _buildRow('standing allowed', item.standingAllowed ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildPeakHoursCard(List<ScheduleRow> peakTrips) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00A86B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Peak hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00A86B),
            ),
          ),
          const SizedBox(height: 8),
          if (peakTrips.isEmpty) const Text('No peak data available.'),
          if (peakTrips.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: peakTrips
                  .map(
                    (trip) => Chip(
                      label: Text(
                        'Trip ${trip.tripIndex + 1} • LF ${trip.loadFactor.toStringAsFixed(2)}',
                      ),
                      backgroundColor: Colors.white,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  List<ScheduleRow> _getPeakTrips(List<ScheduleRow> schedule) {
    final sorted = [...schedule]
      ..sort((a, b) => b.loadFactor.compareTo(a.loadFactor));
    return sorted.take(3).toList();
  }

  List<ScheduleRow> _parseSchedule(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ScheduleRow.fromJson)
        .toList();
  }

  Widget _buildImpactSummary(Map<String, dynamic> summary) {
    final currentTotal = summary['current_total_buses'];
    final deltaTotal = summary['delta_total_buses'];
    final currentOverload = summary['current_overload_trips'];
    final optimizedOverload = summary['optimized_overload_trips'];
    final currentAvg = summary['current_avg_load_factor'];
    final optimizedAvg = summary['avg_load_factor'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Impact summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00A86B),
            ),
          ),
          const SizedBox(height: 12),
          if (currentTotal != null && deltaTotal != null)
            _buildRow(
              'extra buses needed today',
              '${_formatDelta(deltaTotal)} (current $currentTotal)',
            ),
          if (currentOverload != null && optimizedOverload != null)
            _buildRow(
              'peak overload trips',
              '$currentOverload → $optimizedOverload',
            ),
          if (currentAvg != null && optimizedAvg != null)
            _buildRow(
              'avg load factor',
              '${_formatNumber(currentAvg)} → ${_formatNumber(optimizedAvg)}',
            ),
        ],
      ),
    );
  }

  String? _formatTimeLabel(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return null;
    try {
      final parsed = DateTime.parse(timestamp).toLocal();
      final end = parsed.add(const Duration(hours: 1));
      return '${_formatHour(parsed)}–${_formatHour(end)}';
    } catch (_) {
      return null;
    }
  }

  String _formatHour(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDelta(int? value) {
    if (value == null) return '0';
    if (value > 0) return '+$value';
    return value.toString();
  }

  String _formatNumber(dynamic value) {
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return parsed.toStringAsFixed(2);
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
