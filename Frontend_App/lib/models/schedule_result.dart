class ScheduleRow {
  final int tripIndex;
  final String? timestamp;
  final double p90Demand;
  final int busesAssigned;
  final int extraBuses;
  final double loadFactor;
  final int? currentBuses;
  final int? deltaBuses;
  final double? currentLoadFactor;
  final double baseHeadwayMinutes;
  final double headwayMinutes;
  final double headwayMultiplier;
  final bool standingAllowed;

  const ScheduleRow({
    required this.tripIndex,
    required this.timestamp,
    required this.p90Demand,
    required this.busesAssigned,
    required this.extraBuses,
    required this.loadFactor,
    required this.currentBuses,
    required this.deltaBuses,
    required this.currentLoadFactor,
    required this.baseHeadwayMinutes,
    required this.headwayMinutes,
    required this.headwayMultiplier,
    required this.standingAllowed,
  });

  factory ScheduleRow.fromJson(Map<String, dynamic> json) {
    final tripIndex = (json['trip_index'] as num?)?.toInt() ?? 0;
    final timestamp = json['timestamp'] as String?;
    final p90Demand = (json['p90_demand'] as num?)?.toDouble() ?? 0.0;
    final busesAssigned = (json['buses_assigned'] as num?)?.toInt() ?? 0;
    final extraBuses = (json['extra_buses'] as num?)?.toInt() ?? 0;
    final loadFactor = (json['load_factor'] as num?)?.toDouble() ?? 0.0;
    final currentBuses = (json['current_buses'] as num?)?.toInt();
    final deltaBuses = (json['delta_buses'] as num?)?.toInt();
    final currentLoadFactor = (json['current_load_factor'] as num?)?.toDouble();
    final baseHeadwayMinutes =
        (json['base_headway_minutes'] as num?)?.toDouble() ?? 0.0;
    final headwayMinutes =
        (json['adjusted_headway_minutes'] as num?)?.toDouble() ?? 0.0;
    final headwayMultiplier =
        (json['headway_multiplier'] as num?)?.toDouble() ?? 1.0;
    final standingAllowed = (json['standing_allowed'] as bool?) ?? false;

    return ScheduleRow(
      tripIndex: tripIndex,
      timestamp: timestamp,
      p90Demand: p90Demand,
      busesAssigned: busesAssigned,
      extraBuses: extraBuses,
      loadFactor: loadFactor,
      currentBuses: currentBuses,
      deltaBuses: deltaBuses,
      currentLoadFactor: currentLoadFactor,
      baseHeadwayMinutes: baseHeadwayMinutes,
      headwayMinutes: headwayMinutes,
      headwayMultiplier: headwayMultiplier,
      standingAllowed: standingAllowed,
    );
  }
}

class ScheduleResult {
  final List<ScheduleRow> schedule;
  final int capacity;
  final Map<String, dynamic> summary;

  const ScheduleResult({
    required this.schedule,
    required this.capacity,
    required this.summary,
  });

  factory ScheduleResult.fromJson(Map<String, dynamic> json) {
    final scheduleJson = (json['schedule'] as List?) ?? [];
    final schedule = scheduleJson
        .whereType<Map<String, dynamic>>()
        .map(ScheduleRow.fromJson)
        .toList();
    final parameters = json['parameters'] as Map<String, dynamic>? ?? {};
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final capacity = (parameters['capacity'] as num?)?.toInt() ?? 0;

    return ScheduleResult(
      schedule: schedule,
      capacity: capacity,
      summary: summary,
    );
  }
}
