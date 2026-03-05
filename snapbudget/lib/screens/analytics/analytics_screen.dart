import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/notification_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 1; // 0=Week, 1=Month, 2=Year
  final List<String> _periods = ['Week', 'Month', 'Year'];

  List<_CategoryStat> _calculateCategoryStats(TransactionProvider provider) {
    if (provider.transactions.isEmpty) return [];

    final Map<TransactionCategory, double> totals = {};
    double grandTotal = 0;

    for (var tx in provider.transactions) {
      if (tx.type == TransactionType.expense) {
        totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
        grandTotal += tx.amount;
      }
    }

    if (grandTotal == 0) return [];

    return totals.entries.map((e) {
      final color = _getCategoryColor(e.key);
      return _CategoryStat(
          e.key.label, e.value, color, e.key.emoji, e.value / grandTotal);
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  Color _getCategoryColor(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:
        return AppTheme.errorRed;
      case TransactionCategory.transport:
        return AppTheme.accentBlue;
      case TransactionCategory.shopping:
        return AppTheme.primaryPurple;
      case TransactionCategory.entertainment:
        return AppTheme.warningOrange;
      case TransactionCategory.utilities:
        return AppTheme.successGreen;
      case TransactionCategory.health:
        return AppTheme.errorRed;
      case TransactionCategory.education:
        return AppTheme.accentBlue;
      case TransactionCategory.other:
        return AppTheme.textLight;
      default:
        return AppTheme.textMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final categories = _calculateCategoryStats(txProvider);
    final totalSpent = txProvider.totalExpense;
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
                          Text(currencyFormat.format(totalSpent),
                              style: GoogleFonts.inter(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1)),
                          const SizedBox(height: 6),
                          if (totalSpent > 0)
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
                                  Text(
                                      'Analysis based on ${txProvider.transactions.length} transactions',
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
                            maxY: totalSpent > 0 ? totalSpent * 1.2 : 10000,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: const FlTitlesData(
                              show: false,
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              _bar(0, totalSpent * 0.4, false),
                              _bar(1, totalSpent * 0.6, false),
                              _bar(2, totalSpent * 0.3, false),
                              _bar(3, totalSpent * 0.8, false),
                              _bar(4, totalSpent * 0.5, false),
                              _bar(5, totalSpent * 0.7, false),
                              _bar(6, totalSpent, true),
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
                      child: categories.isEmpty
                          ? Center(
                              child: Text('No data available',
                                  style: GoogleFonts.inter(
                                      color: AppTheme.textLight)))
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                  SizedBox(
                                    width: 130,
                                    height: 130,
                                    child: PieChart(PieChartData(
                                      sections: categories
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
                                        children: categories
                                            .map((c) => _legendItem(c))
                                            .toList()),
                                  ),
                                ]),
                    ),
                  ]),
            ),

            // Smart alerts
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                final alerts = provider.alerts.take(3).toList();
                return Padding(
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
                        if (alerts.isEmpty)
                          Text('No active alerts',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppTheme.textLight))
                        else
                          ...alerts.map((a) => _alertCard(
                              _getAlertEmoji(a.type),
                              a.message,
                              _timeAgo(a.createdAt),
                              _getAlertColor(a.type))),
                      ]),
                );
              },
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

  String _getAlertEmoji(String type) {
    if (type.contains('budget')) return '⚠️';
    if (type.contains('spending')) return '✨';
    if (type.contains('split')) return '💰';
    if (type.contains('payment')) return '🔄';
    return '🔔';
  }

  Color _getAlertColor(String type) {
    if (type.contains('budget')) return AppTheme.warningOrange;
    if (type.contains('spending')) return const Color(0xFF7C3AED);
    if (type.contains('split')) return AppTheme.successGreen;
    if (type.contains('payment')) return AppTheme.accentBlue;
    return AppTheme.primaryPurple;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
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
