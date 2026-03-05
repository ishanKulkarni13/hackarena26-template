import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/split_bill_model.dart';

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
                    itemBuilder: (context, i) => _billCard(_bills[i]),
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

  Widget _billCard(SplitBill bill) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(bill.title,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor)),
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
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppTheme.textMedium)),
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
    );
  }

  Widget _buildFriendsList() {
    final friends = [
      {'name': 'Priya S.', 'amount': '₹3,125', 'owes': true},
      {'name': 'Karan M.', 'amount': '₹3,125', 'owes': true},
      {'name': 'Amit K.', 'amount': '₹0', 'owes': false},
      {'name': 'Sneha R.', 'amount': '₹0', 'owes': false},
      {'name': 'Raj P.', 'amount': '₹162', 'owes': true},
    ];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: friends.length,
      itemBuilder: (context, i) {
        final f = friends[i];
        final owes = f['owes'] as bool;
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
                  gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
              child: Center(
                  child: Text((f['name'] as String)[0],
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(f['name'] as String,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark))),
            if (owes)
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Remind',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              )
            else
              Text('Settled ✅',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w600)),
          ]),
        );
      },
    );
  }

  void _showAddSplitDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                _inputField('Bill Title', Icons.label_rounded),
                const SizedBox(height: 12),
                _inputField('Total Amount', Icons.currency_rupee_rounded,
                    isNumber: true),
                const SizedBox(height: 12),
                _inputField('Add Friends', Icons.person_add_rounded),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
              ]),
        ),
      ),
    );
  }

  Widget _inputField(String hint, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.background, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.primaryPurple, size: 20),
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
