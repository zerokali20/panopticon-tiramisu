import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/toggle_switch.dart';

/// Settings screen — toggle rows for protection & preference settings.
/// Port of React SettingsScreen component.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sentry = true;
  bool _context = true;
  bool _honey = false;
  bool _notifications = true;
  bool _dark = true;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    final sections = [
      (
        title: 'PROTECTION',
        rows: [
          (
            icon: Icons.mic_none_rounded,
            label: 'Sentry Agent',
            desc: 'Live audio analysis',
            value: _sentry,
            set: (v) => setState(() => _sentry = v),
          ),
          (
            icon: Icons.storage_rounded,
            label: 'Context Agent',
            desc: 'Local footprint checks',
            value: _context,
            set: (v) => setState(() => _context = v),
          ),
          (
            icon: Icons.auto_awesome_rounded,
            label: 'Honey-pot mode',
            desc: 'Stall scammers with TTS',
            value: _honey,
            set: (v) => setState(() => _honey = v),
          ),
        ],
      ),
      (
        title: 'PREFERENCES',
        rows: [
          (
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            desc: 'Threat alerts only',
            value: _notifications,
            set: (v) => setState(() => _notifications = v),
          ),
          (
            icon: Icons.dark_mode_outlined,
            label: 'Dark appearance',
            desc: 'Follow system off',
            value: _dark,
            set: (v) => setState(() => _dark = v),
          ),
        ],
      ),
    ];

    final links = [
      (icon: Icons.lock_outline_rounded, label: 'Privacy & permissions', desc: 'Microphone, contacts'),
      (icon: Icons.help_outline_rounded, label: 'Help & support', desc: 'Guides and contact'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24, top + 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.40), fontSize: 12)),
              const SizedBox(height: 2),
              Text('Configure Panopticon',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            children: [
              ...sections.map((sec) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sec.title,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.40),
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SettingsGroup(
                        children: sec.rows
                            .map((r) => _ToggleRow(
                                  icon: r.icon,
                                  label: r.label,
                                  desc: r.desc,
                                  value: r.value,
                                  onChanged: r.set,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  )),

              // About section
              Text(
                'ABOUT',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.40),
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: links
                    .map((l) => _LinkRow(
                          icon: l.icon,
                          label: l.label,
                          desc: l.desc,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Panopticon v0.9.2 · Zero-egress',
                  style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.30), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          final isLast = i == children.length - 1;
          return Column(
            children: [
              children[i],
              if (!isLast)
                Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.04),
                    indent: 16,
                    endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Icon(icon, size: 16, color: Colors.white.withOpacity(0.70)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(desc,
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.40), fontSize: 11.5)),
              ],
            ),
          ),
          ToggleSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;

  const _LinkRow({required this.icon, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Icon(icon, size: 16, color: Colors.white.withOpacity(0.70)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(desc,
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.40), fontSize: 11.5)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 16, color: Colors.white.withOpacity(0.30)),
        ],
      ),
    );
  }
}
