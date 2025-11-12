import 'package:flutter/material.dart';
import 'flutter_perf_monitor.dart';
import 'models/fps_data.dart';
import 'models/memory_data.dart';
import 'models/performance_metrics.dart';

/// A widget that displays real-time performance metrics (FPS, memory, CPU).
///
/// Can be displayed as compact chips or expanded detailed view.
class PerfMonitorWidget extends StatefulWidget {
  /// Widget alignment on screen.
  final Alignment alignment;

  /// Show FPS metric.
  final bool showFPS;

  /// Show memory metric.
  final bool showMemory;

  /// Show CPU metric.
  final bool showCPU;

  /// Background color of the monitor.
  final Color backgroundColor;

  /// Text color for metrics.
  final Color textColor;

  /// Border radius of the monitor.
  final double borderRadius;

  /// Padding inside the monitor.
  final EdgeInsets padding;

  /// Expanded by default or compact.
  final bool isExpanded;

  /// Optional title shown in expanded view.
  final String? title;

  /// Localization strings for metrics.
  final String current;
  final String average;
  final String min;
  final String max;
  final String peak;
  final String usage;
  final String memory;
  final String fps;
  final String mem;
  final String cpu;
  final String frameTime;
  final String available;

  /// Creates a new PerfMonitorWidget.
  const PerfMonitorWidget({
    super.key,
    this.current = "Current",
    this.average = "Average",
    this.min = "Min",
    this.max = "Max",
    this.peak = "Peak",
    this.usage = "Usage",
    this.memory = "Memory",
    this.available = "Available",
    this.fps = "FPS",
    this.mem = "MEM",
    this.cpu = "CPU",
    this.frameTime = "Frame Time",
    this.alignment = Alignment.topRight,
    this.title,
    this.showFPS = true,
    this.isExpanded = false,
    this.showMemory = true,
    this.showCPU = true,
    this.backgroundColor = const Color(0x80000000),
    this.textColor = Colors.white,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<PerfMonitorWidget> createState() => _PerfMonitorWidgetState();
}

class _PerfMonitorWidgetState extends State<PerfMonitorWidget> {
  PerformanceMetrics? _currentMetrics;
  FPSData? _currentFPS;
  MemoryData? _currentMemory;

  /// Controls expanded/collapsed state.
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _startListening();
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  /// Subscribe to FlutterPerfMonitor streams.
  void _startListening() {
    FlutterPerfMonitor.instance.metricsStream.listen((metrics) {
      if (mounted) setState(() => _currentMetrics = metrics);
    });

    FlutterPerfMonitor.instance.fpsStream.listen((fps) {
      if (mounted) setState(() => _currentFPS = fps);
    });

    FlutterPerfMonitor.instance.memoryStream.listen((memory) {
      if (mounted) setState(() => _currentMemory = memory);
    });
  }

  /// Streams are managed by FlutterPerfMonitor; nothing to dispose.
  void _stopListening() {}

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Container(
          margin: const EdgeInsets.all(16.0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.textColor.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: _isExpanded ? _buildExpandedView() : _buildCompactView(),
        ),
      ),
    );
  }

  /// Compact view shows only chips for enabled metrics.
  Widget _buildCompactView() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showFPS && _currentFPS != null)
          _buildMetricChip(widget.fps, _currentFPS!.currentFPS.toStringAsFixed(1)),
        if (widget.showMemory && _currentMemory != null)
          _buildMetricChip(widget.mem, '${_currentMemory!.currentUsageMB.toStringAsFixed(1)}MB'),
        if (widget.showCPU && _currentMetrics != null)
          _buildMetricChip(widget.cpu, '${_currentMetrics!.cpuUsage.toStringAsFixed(1)}%'),
      ],
    );
  }

  /// Expanded view shows detailed metrics.
  Widget _buildExpandedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        if (widget.showFPS && _currentFPS != null) _buildFPSDetails(),
        if (widget.showMemory && _currentMemory != null) _buildMemoryDetails(),
        if (widget.showCPU && _currentMetrics != null) _buildCPUDetails(),
      ],
    );
  }

  /// Header with optional title and expand/collapse icon.
  Widget _buildHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.speed, color: widget.textColor, size: 16.0),
        const SizedBox(width: 4.0),
        Text(
          widget.title ?? 'Performance Monitor',
          style: TextStyle(
            color: widget.textColor,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Icon(_isExpanded ? Icons.expand_less : Icons.expand_more,
            color: widget.textColor, size: 16.0),
      ],
    );
  }

  /// Chip for compact view metrics.
  Widget _buildMetricChip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: widget.textColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: widget.textColor,
          fontSize: 10.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Detailed FPS section.
  Widget _buildFPSDetails() {
    return _buildDetailSection(widget.fps, [
      _buildDetailRow(widget.current, _currentFPS!.currentFPS.toStringAsFixed(1)),
      _buildDetailRow(widget.average, _currentFPS!.averageFPS.toStringAsFixed(1)),
      _buildDetailRow(widget.min, _currentFPS!.minFPS.toStringAsFixed(1)),
      _buildDetailRow(widget.max, _currentFPS!.maxFPS.toStringAsFixed(1)),
    ]);
  }

  /// Detailed Memory section.
  Widget _buildMemoryDetails() {
    final rows = <Widget>[
      _buildDetailRow(widget.current, '${_currentMemory!.currentUsageMB.toStringAsFixed(1)}MB'),
      _buildDetailRow(widget.peak, '${_currentMemory!.peakUsageMB.toStringAsFixed(1)}MB'),
    ];

    if (_currentMemory!.totalMemory > 0) {
      rows.add(_buildDetailRow(widget.available, '${_currentMemory!.availableMemoryMB.toStringAsFixed(1)}MB'));
      rows.add(_buildDetailRow(widget.usage, '${_currentMemory!.usagePercentage.toStringAsFixed(1)}%'));
    }

    return _buildDetailSection(widget.memory, rows);
  }

  /// Detailed CPU section.
  Widget _buildCPUDetails() {
    return _buildDetailSection(widget.cpu, [
      _buildDetailRow(widget.usage, '${_currentMetrics!.cpuUsage.toStringAsFixed(1)}%'),
      _buildDetailRow(widget.frameTime, '${_currentMetrics!.frameTime.toStringAsFixed(2)}ms'),
    ]);
  }

  /// Section with title and list of metric rows.
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: widget.textColor, fontSize: 11.0, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4.0),
          ...children,
        ],
      ),
    );
  }

  /// Single row with label and value.
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 50.0,
            child: Text(
              label,
              style: TextStyle(color: widget.textColor.withOpacity(0.8), fontSize: 10.0),
            ),
          ),
          Text(value,
              style: TextStyle(color: widget.textColor, fontSize: 10.0, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
