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

  /// Filters transactions based on selected period
  List<Transaction> _getFilteredTransactions(
      List<Transaction> allTransactions, int periodIndex) {
    final now = DateTime.now();
    DateTime startDate;

    switch (periodIndex) {
      case 0: // Week
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 1: // Month
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 2: // Year
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return allTransactions.where((tx) => tx.date.isAfter(startDate)).toList();
  }

  /// Generates daily spending data for the bar chart
  Map<int, double> _generateDailySpendingData(
      List<Transaction> transactions, int periodIndex) {
    final data = <int, double>{};
    final now = DateTime.now();

    if (periodIndex == 0) {
      // Week: 7 days
      for (int i = 0; i < 7; i++) {
        data[i] = 0;
      }
      for (var tx in transactions) {
        if (tx.type == TransactionType.expense) {
          final dayOfWeek = tx.date.weekday - 1; // 0 = Monday
          if (dayOfWeek >= 0 && dayOfWeek < 7) {
            data[dayOfWeek] = (data[dayOfWeek] ?? 0) + tx.amount;
          }
        }
      }
    } else if (periodIndex == 1) {
      // Month: days in current month
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        data[i - 1] = 0;
      }
      for (var tx in transactions) {
        if (tx.type == TransactionType.expense) {
          final day = tx.date.day - 1;
          if (day >= 0 && day < daysInMonth) {
            data[day] = (data[day] ?? 0) + tx.amount;
          }
        }
      }
    } else {
      // Year: 12 months
      for (int i = 0; i < 12; i++) {
        data[i] = 0;
      }
      for (var tx in transactions) {
        if (tx.type == TransactionType.expense) {
          final month = tx.date.month - 1;
          if (month >= 0 && month < 12) {
            data[month] = (data[month] ?? 0) + tx.amount;
          }
        }
      }
    }

    return data;
  }

  List<_CategoryStat> _calculateCategoryStats(
      List<Transaction> filteredTransactions) {
    if (filteredTransactions.isEmpty) return [];

    final Map<TransactionCategory, double> totals = {};
    double grandTotal = 0;

    for (var tx in filteredTransactions) {
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
        return const Color(0xFFEC4899);
      case TransactionCategory.education:
        return AppTheme.accentBlue;
      case TransactionCategory.housing:
        return const Color(0xFF8B5CF6);
      case TransactionCategory.travel:
        return const Color(0xFF06B6D4);
      case TransactionCategory.salary:
        return const Color(0xFF10B981);
      case TransactionCategory.freelance:
        return const Color(0xFF6366F1);
      case TransactionCategory.investment:
        return const Color(0xFFF59E0B);
      case TransactionCategory.other:
        return AppTheme.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    // Filter transactions based on selected period
    final filteredTransactions =
        _getFilteredTransactions(txProvider.transactions, _selectedPeriod);

    final categories = _calculateCategoryStats(filteredTransactions);

    // Calculate total spent from filtered transactions
    final totalSpent = filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Generate daily spending data
    final dailyData = _generateDailySpendingData(filteredTransactions, _selectedPeriod);

    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Get max value for chart scaling
    final maxValue = dailyData.values.isNotEmpty
        ? dailyData.values.reduce((a, b) => a > b ? a : b)
        : 10000;

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
                          if (filteredTransactions.isNotEmpty)
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
                                      'Analysis based on ${filteredTransactions.length} transactions',
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
                        child: dailyData.isEmpty
                            ? Center(
                                child: Text('No data available',
                                    style: GoogleFonts.inter(
                                        color: AppTheme.textLight)))
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: maxValue > 0 ? maxValue * 1.2 : 10000,
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: const FlTitlesData(
                                    show: false,
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(
                                    dailyData.length,
                                    (i) => _bar(
                                      i,
                                      dailyData[i] ?? 0,
                                      i == dailyData.length - 1,
                                    ),
                                  ),
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
