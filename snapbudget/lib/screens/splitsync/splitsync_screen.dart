import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/split_bill_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/split_provider.dart';
import '../../models/split_group_model.dart';
import '../../models/group_expense_model.dart';
import 'package:provider/provider.dart';

class SplitSyncScreen extends StatefulWidget {
  const SplitSyncScreen({super.key});

  @override
  State<SplitSyncScreen> createState() => _SplitSyncScreenState();
}

class _SplitSyncScreenState extends State<SplitSyncScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<SplitProvider>(context, listen: false)
            .loadGroups(authProvider.user!.uid);
      }
    });
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
    final splitProvider = Provider.of<SplitProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    // Calculate dynamic stats
    double youOwe = 0;
    double owedToYou = 0;
    double settled = 0;

    for (final group in splitProvider.groups) {
      final expenses = splitProvider.getExpenses(group.groupId);
      for (final exp in expenses) {
        if (exp.status == ExpenseStatus.settled) {
          if (exp.paidBy == userId || exp.splitMembers.contains(userId)) {
            settled += exp.amount;
          }
          continue;
        }

        final perPerson = exp.amount / exp.splitMembers.length;
        if (exp.paidBy == userId) {
          // Others owe you
          owedToYou += perPerson * (exp.splitMembers.length - 1);
        } else if (exp.splitMembers.contains(userId)) {
          // You owe payer
          youOwe += perPerson;
        }
      }
    }

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
                      child: _statCard(
                          'You Owe', _fmt.format(youOwe), AppTheme.errorRed)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _statCard('Owed to You', _fmt.format(owedToYou),
                          AppTheme.successGreen)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _statCard('Settled', _fmt.format(settled),
                          AppTheme.primaryPurple)),
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
                  splitProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : splitProvider.groups.isEmpty
                          ? _buildEmptyState('No groups yet',
                              'Create a group to start splitting bills')
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: splitProvider.groups.length,
                              itemBuilder: (context, i) =>
                                  _groupCard(splitProvider.groups[i], i),
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

  Widget _groupCard(SplitGroupModel group, int index) {
    final expenses = Provider.of<SplitProvider>(context, listen: false)
        .getExpenses(group.groupId);
    final totalAmount = expenses.fold(0.0, (sum, exp) => sum + exp.amount);
    final settledCount =
        expenses.where((exp) => exp.status == ExpenseStatus.settled).length;
    final totalCount = expenses.length;
    final progress = totalCount == 0 ? 0.0 : settledCount / totalCount;

    return GestureDetector(
      onTap: () => _showGroupDetails(group),
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
              child: Text(group.groupName,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('${group.members.length} members',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPurple)),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total Expenses: ${_fmt.format(totalAmount)}',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            Text('$settledCount/$totalCount settled',
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
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_rounded,
              size: 64, color: AppTheme.textLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMedium)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight)),
          ),
        ],
      ),
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
      builder: (context) => _AddSplitBottomSheet(
        onAdd: (title, amount, members) {
          // TODO: Implement group creation via SplitProvider
        },
      ),
    );
  }

  void _showGroupDetails(SplitGroupModel group) {
    final expenses = Provider.of<SplitProvider>(context, listen: false)
        .getExpenses(group.groupId);
    final totalAmount = expenses.fold(0.0, (sum, exp) => sum + exp.amount);

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
              // Header with title and members count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.groupName,
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark)),
                        const SizedBox(height: 4),
                        Text('${group.members.length} members',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppTheme.textMedium)),
                      ],
                    ),
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
                  Text('Total Group Spending',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppTheme.textMedium)),
                  Text(_fmt.format(totalAmount),
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                ],
              ),
              const SizedBox(height: 16),

              // Expenses Section
              Text('Expenses',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 12),
              if (expenses.isEmpty)
                Text('No expenses in this group yet',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.textLight))
              else
                ...expenses.map((exp) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exp.description,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark)),
                                const SizedBox(height: 2),
                                Text(
                                    exp.status == ExpenseStatus.settled
                                        ? 'Settled'
                                        : 'Pending',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color:
                                            exp.status == ExpenseStatus.settled
                                                ? AppTheme.successGreen
                                                : AppTheme.errorRed,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_fmt.format(exp.amount),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark)),
                            ],
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 24),

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
}

class _AddSplitBottomSheet extends StatefulWidget {
  final Function(String title, double amount, List<SplitMember> members) onAdd;

  const _AddSplitBottomSheet({required this.onAdd});

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
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _members = [];
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
