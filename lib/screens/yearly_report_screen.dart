// lib/screens/yearly_report_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

final _fmt = NumberFormat('#,###', 'fr_FR');

const _monthsShort = [
  'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
  'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
];

const _monthsLong = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
];

/// Palette pour le pie chart (cyclique).
const _pieColors = [
  Color(0xFF6C63FF),
  Color(0xFFFF6584),
  Color(0xFF00C896),
  Color(0xFFFFB300),
  Color(0xFF00B8D4),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF4CAF50),
  Color(0xFFFF7043),
  Color(0xFF3F51B5),
  Color(0xFF795548),
  Color(0xFF607D8B),
];

class YearlyReportScreen extends StatefulWidget {
  const YearlyReportScreen({super.key});

  @override
  State<YearlyReportScreen> createState() => _YearlyReportScreenState();
}

class _YearlyReportScreenState extends State<YearlyReportScreen> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final years = provider.availableYears;

    // Année par défaut : la plus récente disponible.
    final year = _selectedYear ??
        (years.isNotEmpty ? years.last : DateTime.now().year);

    final report = provider.buildYearlyReport(year);

    return Scaffold(
      backgroundColor: kScaffold,
      appBar: AppBar(
        title: Text('Rapport annuel',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: kDark,
        foregroundColor: Colors.white,
        actions: [
          if (years.length > 1)
            PopupMenuButton<int>(
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              tooltip: 'Changer d\'année',
              onSelected: (y) => setState(() => _selectedYear = y),
              itemBuilder: (_) => years
                  .map((y) => PopupMenuItem(
                        value: y,
                        child: Text('$y',
                            style: GoogleFonts.poppins(
                                fontWeight: y == year
                                    ? FontWeight.w700
                                    : FontWeight.w400)),
                      ))
                  .toList(),
            ),
        ],
      ),
      body: report == null
          ? _EmptyState(year: year)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _YearHeader(year: year, report: report),
                  const SizedBox(height: 16),
                  _SummaryCards(report: report),
                  const SizedBox(height: 24),
                  _SectionTitle('Dépenses mensuelles'),
                  const SizedBox(height: 12),
                  _MonthlyBarChart(report: report),
                  const SizedBox(height: 24),
                  if (report.sortedCategories.isNotEmpty) ...[
                    _SectionTitle('Répartition par catégorie'),
                    const SizedBox(height: 12),
                    _CategoryPieSection(report: report),
                    const SizedBox(height: 24),
                  ],
                  _SectionTitle('Statistiques'),
                  const SizedBox(height: 12),
                  _StatsGrid(report: report),
                ],
              ),
            ),
    );
  }
}

// ─── États vides ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int year;
  const _EmptyState({required this.year});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: kPrimaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.bar_chart,
                  size: 48, color: kPrimary),
            ),
            const SizedBox(height: 20),
            Text('Aucune donnée pour $year',
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Crée au moins un budget mensuel pour voir ton rapport annuel.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _YearHeader extends StatelessWidget {
  final int year;
  final YearlyReport report;
  const _YearHeader({required this.year, required this.report});

  @override
  Widget build(BuildContext context) {
    final monthsCount = report.monthlySpent.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: kHeaderGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Année $year',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$monthsCount mois suivis',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          Text('Solde annuel',
              style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 11,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            '${report.isPositive ? '+' : ''}${_fmt.format(report.balance)} FCFA',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }
}

// ─── Cartes résumé ─────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final YearlyReport report;
  const _SummaryCards({required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Card('Prévu', _fmt.format(report.totalBudget), kPrimary,
            kPrimaryLight, Icons.account_balance_wallet_outlined),
        const SizedBox(width: 10),
        _Card('Dépensé', _fmt.format(report.totalSpent), kDanger,
            kDangerLight, Icons.trending_down),
        const SizedBox(width: 10),
        _Card(
          report.isPositive ? 'Bénéfice' : 'Déficit',
          '${report.isPositive ? '+' : ''}${_fmt.format(report.balance)}',
          report.isPositive ? kSuccess : kDanger,
          report.isPositive ? kSuccessLight : kDangerLight,
          report.isPositive ? Icons.trending_up : Icons.trending_down,
        ),
      ],
    );
  }

  Widget _Card(
      String label, String value, Color fg, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: fg, size: 14),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    color: fg, fontSize: 10, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: GoogleFonts.poppins(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Titre de section ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600));
  }
}

// ─── Graphique à barres mensuel ────────────────────────────────────────────

class _MonthlyBarChart extends StatelessWidget {
  final YearlyReport report;
  const _MonthlyBarChart({required this.report});

  @override
  Widget build(BuildContext context) {
    // On affiche 12 barres (même les mois sans données, pour la régularité).
    final maxValue = _maxValue();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue * 1.2,
            minY: 0,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxValue / 4,
              getDrawingHorizontalLine: (v) => FlLine(
                color: Colors.black.withValues(alpha: 0.05),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: maxValue / 4,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        _shortNumber(value),
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.black45),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= 12) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _monthsShort[i],
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.black54),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor:  kDark,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final m = group.x;
                  final spent = report.monthlySpent[m] ?? 0;
                  final budget = report.monthlyBudget[m] ?? 0;
                  return BarTooltipItem(
                    '${_monthsLong[m - 1]}\n',
                    GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text:
                            'Dépensé : ${_fmt.format(spent)} F\nPrévu : ${_fmt.format(budget)} F',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  );
                },
              ),
            ),
            barGroups: List.generate(12, (i) {
              final month = i + 1;
              final spent = report.monthlySpent[month] ?? 0;
              final budget = report.monthlyBudget[month] ?? 0;
              final over = budget > 0 && spent > budget;
              return BarChartGroupData(
                x: month,
                barRods: [
                  BarChartRodData(
                    toY: spent,
                    width: 12,
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: over
                          ? [kDanger.withValues(alpha: 0.6), kDanger]
                          : [kPrimary.withValues(alpha: 0.6), kPrimary],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  double _maxValue() {
    double max = 1;
    for (final v in report.monthlySpent.values) {
      if (v > max) max = v;
    }
    for (final v in report.monthlyBudget.values) {
      if (v > max) max = v;
    }
    return max;
  }

  String _shortNumber(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

// ─── Section Pie : catégories ──────────────────────────────────────────────

class _CategoryPieSection extends StatelessWidget {
  final YearlyReport report;
  const _CategoryPieSection({required this.report});

  @override
  Widget build(BuildContext context) {
    final cats = report.sortedCategories;
    final total = cats.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: List.generate(cats.length, (i) {
                  final entry = cats[i];
                  final pct = (entry.value / total) * 100;
                  final color = _pieColors[i % _pieColors.length];
                  return PieChartSectionData(
                    value: entry.value,
                    color: color,
                    radius: 60,
                    title: pct >= 6 ? '${pct.toStringAsFixed(0)}%' : '',
                    titleStyle: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Légende
          Column(
            children: List.generate(cats.length, (i) {
              final entry = cats[i];
              final color = _pieColors[i % _pieColors.length];
              final pct = (entry.value / total) * 100;
              final icon = report.categoryIcons[entry.key] ?? '💰';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 10),
                    Text(icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(entry.key,
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.black45)),
                    const SizedBox(width: 10),
                    Text('${_fmt.format(entry.value)} F',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kDanger)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Statistiques ──────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final YearlyReport report;
  const _StatsGrid({required this.report});

  @override
  Widget build(BuildContext context) {
    final best = report.bestMonth;
    final worst = report.worstMonth;

    return Column(
      children: [
        Row(
          children: [
            _StatTile(
              icon: Icons.arrow_downward,
              iconColor: kSuccess,
              label: 'Mois le plus économe',
              value: best != null
                  ? '${_monthsLong[best - 1]}\n${_fmt.format(report.monthlySpent[best] ?? 0)} F'
                  : '—',
            ),
            const SizedBox(width: 10),
            _StatTile(
              icon: Icons.arrow_upward,
              iconColor: kDanger,
              label: 'Mois le plus dépensier',
              value: worst != null
                  ? '${_monthsLong[worst - 1]}\n${_fmt.format(report.monthlySpent[worst] ?? 0)} F'
                  : '—',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatTile(
              icon: Icons.calendar_month,
              iconColor: kPrimary,
              label: 'Moyenne mensuelle',
              value: '${_fmt.format(report.averageMonthly)} F',
            ),
            const SizedBox(width: 10),
            _StatTile(
              icon: Icons.list_alt,
              iconColor: kPrimary,
              label: 'Catégories suivies',
              value: '${report.byCategory.length}',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}