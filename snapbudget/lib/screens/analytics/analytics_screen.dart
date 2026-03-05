import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 1; // 0=Week, 1=Month, 2=Year
  final List<String> _periods = ['Week', 'Month', 'Year'];

  final List<_CategoryStat> _categories = [
    _CategoryStat('Food & Dining', 3800, AppTheme.errorRed, '🍔', 0.35),
    _CategoryStat('Transport', 2200, AppTheme.accentBlue, '🚗', 0.20),
    _CategoryStat('Shopping', 2800, AppTheme.primaryPurple, '🛍️', 0.26),
    _CategoryStat('Entertainment', 1200, AppTheme.warningOrange, '🎮', 0.11),
    _CategoryStat('Utilities', 800, AppTheme.successGreen, '⚡', 0.08),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Analytics',
                            style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.ios_share_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Period selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: List.generate(
                            _periods.length,
                            (i) => Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedPeriod = i),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: _selectedPeriod == i
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Center(
                                          child: Text(_periods[i],
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedPeriod == i
                                                    ? AppTheme.primaryPurple
                                                    : Colors.white,
                                              ))),
                                    ),
                                  ),
                                )),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Total spend
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Spent',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text('₹10,800',
                              style: GoogleFonts.inter(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color:
                                      AppTheme.successGreen.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                const Icon(Icons.trending_down_rounded,
                                    color: Colors.greenAccent, size: 14),
                                const SizedBox(width: 4),
                                Text('12% less than last month',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ]),
                        ]),
                  ),

                  const SizedBox(height: 24),
                ]),
              ),
            ),

            // Bar chart
            Container(
              color: AppTheme.background,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spending Trend',
                        style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          boxShadow: AppTheme.cardShadow),
                      child: SizedBox(
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 15000,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const months = [
                                      'Sep',
                                      'Oct',
                                      'Nov',
                                      'Dec',
                                      'Jan',
                                      'Feb',
                                      'Mar'
                                    ];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(months[value.toInt()],
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppTheme.textLight)),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              _bar(0, 9800, false),
                              _bar(1, 11200, false),
                              _bar(2, 8900, false),
                              _bar(3, 14200, false),
                              _bar(4, 7600, false),
                              _bar(5, 12100, false),
                              _bar(6, 10800, true),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),

            // Donut chart section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spending by Category',
                        style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          boxShadow: AppTheme.cardShadow),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 130,
                              height: 130,
                              child: PieChart(PieChartData(
                                sections: _categories
                                    .map((c) => PieChartSectionData(
                                          color: c.color,
                                          value: c.percentage,
                                          radius: 45,
                                          showTitle: false,
                                        ))
                                    .toList(),
                                centerSpaceRadius: 30,
                                sectionsSpace: 2,
                              )),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                  children: _categories
                                      .map((c) => _legendItem(c))
                                      .toList()),
                            ),
                          ]),
                    ),
                  ]),
            ),

            // Smart alerts
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Alerts',
                        style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 12),
                    _alertCard(
                        '⚠️',
                        'Food spending 23% above budget',
                        'You\'ve spent ₹3,800 on food this month',
                        AppTheme.warningOrange),
                    _alertCard(
                        '💰',
                        'Great saving this week!',
                        'You saved ₹2,400 compared to last week',
                        AppTheme.successGreen),
                    _alertCard('🔄', 'Recurring payment detected',
                        'Netflix ₹649 due on March 15', AppTheme.accentBlue),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, bool isSelected) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        width: 18,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        gradient: isSelected
            ? AppTheme.primaryGradient
            : LinearGradient(
                colors: [
                  AppTheme.primaryPurple.withOpacity(0.2),
                  AppTheme.primaryPurple.withOpacity(0.1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
    ]);
  }

  Widget _legendItem(_CategoryStat c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(c.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(c.name,
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppTheme.textMedium),
                overflow: TextOverflow.ellipsis)),
        Text('₹${c.amount.toInt()}',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark)),
      ]),
    );
  }

  Widget _alertCard(String emoji, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
          Text(subtitle,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppTheme.textMedium)),
        ])),
        Icon(Icons.chevron_right_rounded, color: color, size: 18),
      ]),
    );
  }
}

class _CategoryStat {
  final String name;
  final double amount;
  final Color color;
  final String emoji;
  final double percentage;
  const _CategoryStat(
      this.name, this.amount, this.color, this.emoji, this.percentage);
}
