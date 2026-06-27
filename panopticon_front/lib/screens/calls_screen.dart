import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/risk_dot.dart';
import '../data/mock_data.dart';
import 'package:call_log/call_log.dart';

/// Calls screen — threat log with filter chips.
/// Port of React CallsScreen component.
class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  String _filter = 'all'; // 'all' | 'high' | 'med' | 'safe'
  List<CallRecord> _realCalls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCalls();
  }

  Future<void> _loadCalls() async {
    try {
      final entries = await CallLog.get();
      final List<CallRecord> loaded = [];
      for (var entry in entries.take(30)) {
        final risk = (entry.duration != null && entry.duration! > 0) ? 'safe' : 'med';
        final dt = DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0);
        final dateStr = '${dt.month}/${dt.day}';
        final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        
        loaded.add(CallRecord(
          name: (entry.name != null && entry.name!.isNotEmpty) ? entry.name! : 'Unknown',
          number: entry.number ?? 'Private',
          date: dateStr,
          time: timeStr,
          duration: '${entry.duration}s',
          risk: risk,
          confidence: risk == 'safe' ? 95 : 60,
        ));
      }
      setState(() {
        _realCalls = loaded;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  static const _filters = [
    ('all', 'All'),
    ('high', 'High risk'),
    ('med', 'Medium'),
    ('safe', 'Safe'),
  ];

  List<CallRecord> get _filtered {
    final src = _realCalls.isNotEmpty ? _realCalls : allCalls;
    return _filter == 'all' ? src : src.where((c) => c.risk == _filter).toList();
  }

  Color _riskColor(String risk) => switch (risk) {
        'high' => AppColors.riskHigh,
        'med' => AppColors.riskMed,
        _ => AppColors.riskSafe,
      };

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.fromLTRB(24, top + 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Threat Log',
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.40), fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                '${_filtered.length} calls intercepted',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5),
              ),
            ],
          ),
        ),

        // Filter chips
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final f = _filters[i];
              final isActive = _filter == f.$1;
              return GestureDetector(
                onTap: () => setState(() => _filter = f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(100),
                    border: isActive
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Text(
                    f.$2,
                    style: GoogleFonts.inter(
                      color: isActive
                          ? AppColors.background
                          : Colors.white.withValues(alpha: 0.60),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // List
        Expanded(
          child: _loading 
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No calls match this filter.',
                        style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontSize: 12),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.04),
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, i) {
                        final c = _filtered[i];
                        return Container(
                          decoration: i == 0
                          ? BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05)),
                            )
                          : i == _filtered.length - 1
                              ? BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.02),
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(16)),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.05)),
                                )
                              : BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.02),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.05)),
                                ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          RiskDot(risk: c.risk),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${c.confidence}%',
                                      style: GoogleFonts.inter(
                                        color: _riskColor(c.risk),
                                        fontSize: 11,
                                        fontFeatures: [
                                          const FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.number,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.40),
                                    fontSize: 11.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${c.date} · ${c.time}',
                                      style: GoogleFonts.inter(
                                        color:
                                            Colors.white.withValues(alpha: 0.30),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      width: 2,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Colors.white.withValues(alpha: 0.30),
                                      ),
                                    ),
                                    Text(
                                      c.duration,
                                      style: GoogleFonts.inter(
                                        color:
                                            Colors.white.withValues(alpha: 0.30),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
