import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../models/split_bill_model.dart';
import '../../services/notification_service.dart';

class SplitSyncScreen extends StatefulWidget {
  const SplitSyncScreen({super.key});

  @override
  State<SplitSyncScreen> createState() => _SplitSyncScreenState();
}

class _SplitSyncScreenState extends State<SplitSyncScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<SplitBill> _bills = [
    SplitBill(
      id: '1',
      title: 'Goa Trip 🏖️',
      totalAmount: 12500,
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Hotel + Food + Activities',
      status: SplitStatus.partial,
      expenseBreakdown: {
        'Hotel': 6000,
        'Food': 4000,
        'Activities': 2500,
      },
      members: [
        SplitMember(id: 'a', name: 'You', share: 3125, hasPaid: true),
        SplitMember(id: 'b', name: 'Priya', share: 3125, hasPaid: true),
        SplitMember(id: 'c', name: 'Karan', share: 3125, hasPaid: false),
        SplitMember(id: 'd', name: 'Riya', share: 3125, hasPaid: false),
      ],
    ),
    SplitBill(
      id: '2',
      title: 'Dinner at Punjab Grill 🍽️',
      totalAmount: 3200,
      date: DateTime.now().subtract(const Duration(days: 7)),
      description: 'Team dinner',
      status: SplitStatus.settled,
      members: [
        SplitMember(id: 'a', name: 'You', share: 1067, hasPaid: true),
        SplitMember(id: 'b', name: 'Amit', share: 1067, hasPaid: true),
        SplitMember(id: 'c', name: 'Sneha', share: 1066, hasPaid: true),
      ],
    ),
    SplitBill(
      id: '3',
      title: 'Netflix Family Plan 📺',
      totalAmount: 649,
      date: DateTime.now().subtract(const Duration(days: 2)),
      description: 'Monthly subscription split',
      status: SplitStatus.pending,
      members: [
        SplitMember(id: 'a', name: 'You', share: 163, hasPaid: true),
        SplitMember(id: 'b', name: 'Raj', share: 162, hasPaid: false),
        SplitMember(id: 'c', name: 'Meera', share: 162, hasPaid: false),
        SplitMember(id: 'd', name: 'Arjun', share: 162, hasPaid: false),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  NumberFormat get _fmt =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SplitSync',
                            style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark)),
                        Text('Split bills, settle smart',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppTheme.textMedium)),
                      ]),
                  GestureDetector(
                    onTap: _showAddSplitDialog,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.buttonShadow),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                      child: _statCard('You Owe', '₹6,250', AppTheme.errorRed)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _statCard(
                          'Owed to You', '₹3,200', AppTheme.successGreen)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _statCard(
                          'Settled', '₹3,200', AppTheme.primaryPurple)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  padding: const EdgeInsets.all(4),
                  splashBorderRadius: BorderRadius.circular(10),
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textMedium,
                  labelStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [Tab(text: 'Groups'), Tab(text: 'Friends')],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _bills.length,
                    itemBuilder: (context, i) => _billCard(_bills[i], i),
                  ),
                  _buildFriendsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(amount,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _billCard(SplitBill bill, int index) {
    final settled = bill.members.where((m) => m.hasPaid).length;
    final total = bill.members.length;
    final progress = settled / total;

    Color statusColor;
    String statusLabel;
    switch (bill.status) {
      case SplitStatus.settled:
        statusColor = AppTheme.successGreen;
        statusLabel = 'Settled';
        break;
      case SplitStatus.partial:
        statusColor = AppTheme.warningOrange;
        statusLabel = 'Partial';
        break;
      case SplitStatus.pending:
        statusColor = AppTheme.errorRed;
        statusLabel = 'Pending';
        break;
    }

    return GestureDetector(
      onTap: () => _showBillDetails(bill),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Text(bill.title,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showEditSplitDialog(bill, index),
                  child: const Icon(Icons.edit_rounded,
                      size: 18, color: AppTheme.textMedium),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _bills.removeAt(index);
                    });
                  },
                  child: const Icon(Icons.delete_rounded,
                      size: 18, color: AppTheme.errorRed),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                ),
              ],
            ),
          ]),
          if (bill.description != null) ...[
            const SizedBox(height: 4),
            Text(bill.description!,
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight)),
          ],
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total: ${_fmt.format(bill.totalAmount)}',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            Text('Per person: ${_fmt.format(bill.amountPerPerson)}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textMedium)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$settled/$total paid',
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
            Row(
                children: bill.members
                    .take(4)
                    .map((m) => Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: m.hasPaid
                                ? AppTheme.successGreen
                                : AppTheme.divider,
                            border: Border.all(
                                color: AppTheme.background, width: 1.5),
                          ),
                          child: Center(
                              child: Text(m.name[0],
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: m.hasPaid
                                          ? Colors.white
                                          : AppTheme.textLight))),
                        ))
                    .toList()),
          ]),
        ]),
      ),
    );
  }

  Widget _buildFriendsList() {
    // owesYou: true = they owe you, false = you owe them
    final friends = [
      {
        'name': 'Priya S.',
        'amount': '₹3,125',
        'billTitle': 'Goa Trip',
        'owesYou': true
      },
      {
        'name': 'Karan M.',
        'amount': '₹3,125',
        'billTitle': 'Goa Trip',
        'owesYou': true
      },
      {
        'name': 'Amit K.',
        'amount': '₹0',
        'billTitle': 'Dinner at Punjab Grill',
        'owesYou': false
      },
      {
        'name': 'Sneha R.',
        'amount': '₹0',
        'billTitle': 'Dinner at Punjab Grill',
        'owesYou': false
      },
      {
        'name': 'Raj P.',
        'amount': '₹162',
        'billTitle': 'Netflix Family Plan',
        'owesYou': true
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: friends.length,
      itemBuilder: (context, i) {
        final f = friends[i];
        final owesYou = f['owesYou'] as bool;
        final name = f['name'] as String;
        final amount = f['amount'] as String;
        final billTitle = f['billTitle'] as String;
        final isSettled = amount == '₹0';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.cardShadow),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  gradient: owesYou
                      ? AppTheme.primaryGradient
                      : const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
                  shape: BoxShape.circle),
              child: Center(
                  child: Text(name[0],
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  if (!isSettled)
                    Text(
                      owesYou ? 'Owes you $amount' : 'You owe $amount',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: owesYou
                              ? AppTheme.successGreen
                              : AppTheme.errorRed,
                          fontWeight: FontWeight.w500),
                    )
                  else
                    Text('All settled',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSettled)
              Text('Settled ✅',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w600))
            else
              GestureDetector(
                onTap: () => _showRemindDrawer(
                  name: name,
                  amount: amount,
                  billTitle: billTitle,
                  initialIndex: owesYou ? 1 : 0,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      gradient: owesYou ? AppTheme.primaryGradient : null,
                      color:
                          owesYou ? null : AppTheme.errorRed.withOpacity(0.1),
                      border:
                          owesYou ? null : Border.all(color: AppTheme.errorRed),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Remind',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: owesYou ? Colors.white : AppTheme.errorRed)),
                ),
              ),
          ]),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // Sheets & notification helpers
  // ------------------------------------------------------------------

  void _showRemindDrawer({
    required String name,
    required String amount,
    required String billTitle,
    required int initialIndex,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RemindDrawerSheet(
        name: name,
        amount: amount,
        billTitle: billTitle,
        initialIndex: initialIndex,
      ),
    );
  }

  void _showAddSplitDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddSplitBottomSheet(
        onAdd: (title, amount, members) {
          setState(() {
            _bills.insert(
              0,
              SplitBill(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                totalAmount: amount,
                members: members,
                date: DateTime.now(),
                status: members.every((m) => m.hasPaid)
                    ? SplitStatus.settled
                    : SplitStatus.pending,
              ),
            );
          });
        },
      ),
    );
  }

  void _showEditSplitDialog(SplitBill bill, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddSplitBottomSheet(
        initialBill: bill,
        onAdd: (title, amount, members) {
          setState(() {
            _bills[index] = SplitBill(
              id: bill.id,
              title: title,
              totalAmount: amount,
              members: members,
              date: bill.date,
              description: bill.description,
              expenseBreakdown: bill.expenseBreakdown,
              status: members.every((m) => m.hasPaid)
                  ? SplitStatus.settled
                  : SplitStatus.pending,
            );
          });
        },
      ),
    );
  }

  void _showBillDetails(SplitBill bill) {
    final billIndex = _bills.indexWhere((b) => b.id == bill.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bill.title,
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark)),
                        const SizedBox(height: 4),
                        if (bill.description != null)
                          Text(bill.description!,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppTheme.textMedium)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(bill.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _getStatusColor(bill.status).withOpacity(0.3)),
                    ),
                    child: Text(_getStatusLabel(bill.status),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(bill.status))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.divider),
              const SizedBox(height: 16),

              // Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppTheme.textMedium)),
                  Text(_fmt.format(bill.totalAmount),
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                ],
              ),
              const SizedBox(height: 16),

              // Expense Breakdown (if available)
              if (bill.expenseBreakdown != null &&
                  bill.expenseBreakdown!.isNotEmpty) ...[
                Text('Expense Breakdown',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                const SizedBox(height: 12),
                ...bill.expenseBreakdown!.entries.map((entry) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getExpenseCategoryColor(entry.key),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(entry.key,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_fmt.format(entry.value),
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark)),
                              Text(
                                  '${((entry.value / bill.totalAmount) * 100).toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.textMedium)),
                            ],
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.divider),
                const SizedBox(height: 16),
              ],

              // Members Section
              Text('Members & Payments',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 12),
              ...bill.members.map((m) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: m.hasPaid
                                ? AppTheme.successGreen
                                : AppTheme.divider,
                          ),
                          child: Center(
                            child: Text(m.name[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: m.hasPaid
                                        ? Colors.white
                                        : AppTheme.textLight)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark)),
                              const SizedBox(height: 2),
                              Text(
                                  m.hasPaid
                                      ? 'Payment Complete'
                                      : 'Awaiting Payment',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: m.hasPaid
                                          ? AppTheme.successGreen
                                          : AppTheme.errorRed,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${m.share.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: m.hasPaid
                                    ? AppTheme.successGreen.withOpacity(0.1)
                                    : AppTheme.errorRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(m.hasPaid ? '✓ Paid' : 'Pending',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: m.hasPaid
                                          ? AppTheme.successGreen
                                          : AppTheme.errorRed)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showEditSplitDialog(bill, billIndex);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.primaryPurple, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit_rounded,
                                color: AppTheme.primaryPurple, size: 18),
                            const SizedBox(width: 6),
                            Text('Edit',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryPurple)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Split Bill?'),
                            content:
                                const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _bills.removeAt(billIndex);
                                  });
                                },
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.1),
                          border:
                              Border.all(color: AppTheme.errorRed, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_rounded,
                                color: AppTheme.errorRed, size: 18),
                            const SizedBox(width: 6),
                            Text('Delete',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.errorRed)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Close',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SplitStatus status) {
    switch (status) {
      case SplitStatus.settled:
        return AppTheme.successGreen;
      case SplitStatus.partial:
        return AppTheme.warningOrange;
      case SplitStatus.pending:
        return AppTheme.errorRed;
    }
  }

  String _getStatusLabel(SplitStatus status) {
    switch (status) {
      case SplitStatus.settled:
        return 'Settled';
      case SplitStatus.partial:
        return 'Partial';
      case SplitStatus.pending:
        return 'Pending';
    }
  }

  Color _getExpenseCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hotel':
        return const Color(0xFF5B8DEF);
      case 'food':
        return const Color(0xFFFFA500);
      case 'activities':
        return const Color(0xFFE91E63);
      case 'transport':
        return const Color(0xFF4CAF50);
      case 'entertainment':
        return const Color(0xFF9C27B0);
      default:
        return AppTheme.primaryPurple;
    }
  }
}

class _AddSplitBottomSheet extends StatefulWidget {
  final Function(String title, double amount, List<SplitMember> members) onAdd;
  final SplitBill? initialBill;

  const _AddSplitBottomSheet({required this.onAdd, this.initialBill});

  @override
  State<_AddSplitBottomSheet> createState() => _AddSplitBottomSheetState();
}

class _AddSplitBottomSheetState extends State<_AddSplitBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  final _friendNameController = TextEditingController();
  final _friendAmountController = TextEditingController();

  late final List<SplitMember> _members;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialBill?.title ?? '');
    _amountController = TextEditingController(
        text: widget.initialBill != null
            ? widget.initialBill!.totalAmount.toStringAsFixed(0)
            : '');

    // If we're editing, populate members excluding 'You' since 'You' is automatically calculated
    if (widget.initialBill != null) {
      _members = widget.initialBill!.members
          .where((m) => m.name != 'You')
          .map((m) => SplitMember(
                id: m.id,
                name: m.name,
                share: m.share,
                hasPaid: m.hasPaid,
                avatarUrl: m.avatarUrl,
                upiId: m.upiId,
              ))
          .toList();
    } else {
      _members = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _friendNameController.dispose();
    _friendAmountController.dispose();
    super.dispose();
  }

  void _addFriend() {
    final name = _friendNameController.text.trim();
    if (name.isEmpty) return;

    final amountText = _friendAmountController.text.trim();
    double amount = 0;
    if (amountText.isNotEmpty) {
      amount = double.tryParse(amountText) ?? 0;
    }

    setState(() {
      _members.add(SplitMember(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        share: amount,
        hasPaid: false,
      ));
      _friendNameController.clear();
      _friendAmountController.clear();
    });
  }

  void _removeFriend(int index) {
    setState(() {
      _members.removeAt(index);
    });
  }

  void _createSplit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final totalAmount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (totalAmount <= 0) return;

    final finalMembers = List<SplitMember>.from(_members);

    final assignedAmount = finalMembers.fold(0.0, (sum, m) => sum + m.share);

    // Automatically split unassigned remainder among all members who have 0 share
    // or just assign it entirely to 'You'. Let's assign remainder to 'You' for simplicity in this demo.
    final remaining = totalAmount - assignedAmount;

    finalMembers.insert(
      0,
      SplitMember(
        id: 'me',
        name: 'You',
        share: remaining > 0 ? remaining : 0,
        hasPaid: true,
      ),
    );

    widget.onAdd(title, totalAmount, finalMembers);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Split Bill',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 20),
              _buildInputField(
                  controller: _titleController,
                  hint: 'Bill Title (e.g. Lunch)',
                  icon: Icons.label_rounded),
              const SizedBox(height: 12),
              _buildInputField(
                  controller: _amountController,
                  hint: 'Total Amount',
                  icon: Icons.currency_rupee_rounded,
                  isNumber: true),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.divider),
              const SizedBox(height: 16),
              Text('Add Friends & Assign Amount',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildInputField(
                      controller: _friendNameController,
                      hint: 'Friend Name',
                      icon: Icons.person_add_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: _buildInputField(
                      controller: _friendAmountController,
                      hint: 'Amount',
                      icon: Icons.currency_rupee_rounded,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addFriend,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                    ),
                  )
                ],
              ),
              if (_members.isNotEmpty) const SizedBox(height: 16),
              if (_members.isNotEmpty)
                Column(
                  children: _members.asMap().entries.map((entry) {
                    final index = entry.key;
                    final member = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle),
                            child: Center(
                                child: Text(member.name[0].toUpperCase(),
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              member.name,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark),
                            ),
                          ),
                          Text(
                            member.share > 0
                                ? '₹${member.share.toStringAsFixed(0)}'
                                : '₹0',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMedium),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _removeFriend(index),
                            child: const Icon(Icons.close_rounded,
                                color: AppTheme.errorRed, size: 20),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _createSplit,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
                  child: Center(
                      child: Text('Create Split',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.background, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.primaryPurple, size: 20),
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reminder Drawer with Tabs
// ---------------------------------------------------------------------------
class _RemindDrawerSheet extends StatefulWidget {
  final String name;
  final String amount;
  final String billTitle;
  final int initialIndex;

  const _RemindDrawerSheet({
    required this.name,
    required this.amount,
    required this.billTitle,
    this.initialIndex = 0,
  });

  @override
  State<_RemindDrawerSheet> createState() => _RemindDrawerSheetState();
}

class _RemindDrawerSheetState extends State<_RemindDrawerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _scheduleReminder(int days) async {
    final scheduledDate = DateTime.now().add(Duration(days: days));
    await NotificationService().scheduleReminderSelf(
      friendName: widget.name,
      amount: widget.amount,
      billTitle: widget.billTitle,
      scheduledDate: scheduledDate,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 Scheduled payment reminder for $days day(s).',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          backgroundColor: AppTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showCustomDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null && mounted) {
        final DateTime scheduledDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (scheduledDateTime.isAfter(DateTime.now())) {
          await NotificationService().scheduleReminderSelf(
            friendName: widget.name,
            amount: widget.amount,
            billTitle: widget.billTitle,
            scheduledDate: scheduledDateTime,
          );

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🔔 Custom payment reminder scheduled.',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                backgroundColor: AppTheme.warningOrange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      }
    }
  }

  void _sharePaymentRequest() {
    final text =
        "Hey ${widget.name}, just a friendly reminder about the ${widget.amount} for \"${widget.billTitle}\". Let me know when you can settle up! Thanks.";
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryPurple,
            unselectedLabelColor: AppTheme.textMedium,
            indicatorColor: AppTheme.primaryPurple,
            labelStyle:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "Remind Myself"),
              Tab(text: "Remind My Friend"),
            ],
          ),
          SizedBox(
            height: 380, // Enough height for the content
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRemindMyselfTab(),
                _buildRemindFriendTab(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRemindMyselfTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Schedule a notification reminder so you don't forget to pay ${widget.amount} to ${widget.name}.",
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 24),
          _reminderOption(
            title: "Remind in 1 day",
            icon: Icons.timer_rounded,
            onTap: () => _scheduleReminder(1),
          ),
          const SizedBox(height: 12),
          _reminderOption(
            title: "Remind in 2 days",
            icon: Icons.access_time_filled_rounded,
            onTap: () => _scheduleReminder(2),
          ),
          const SizedBox(height: 12),
          _reminderOption(
            title: "Custom Time...",
            icon: Icons.calendar_month_rounded,
            onTap: _showCustomDatePicker,
          ),
        ],
      ),
    );
  }

  Widget _buildRemindFriendTab() {
    final String msg =
        "Hey ${widget.name}, just a friendly reminder about the ${widget.amount} for \"${widget.billTitle}\". Let me know when you can settle up! Thanks.";
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Send a message to ${widget.name} to remind them to pay.",
            style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Text(
              msg,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textMedium,
                  fontStyle: FontStyle.italic),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _sharePaymentRequest,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Center(
                child: Text(
                  "Share Message via...",
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _reminderOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 20),
            const SizedBox(width: 12),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}
