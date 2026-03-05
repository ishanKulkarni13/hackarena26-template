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
        // Skip if you are not involved in this expense
        if (exp.paidBy != userId &&
            !exp.splitMembers.contains(userId) &&
            !exp.splitMembers.contains('You')) {
          continue;
        }

        double getShare(String curUser) {
          return exp.memberShares[curUser] ??
              (exp.amount / exp.splitMembers.length);
        }

        if (exp.status == ExpenseStatus.settled) {
          // If the WHOLE expense is settled
          if (exp.paidBy == userId) {
            // I paid it, people paid me back
            for (var m in exp.splitMembers) {
              if (m != userId && m != 'You') {
                settled += getShare(m);
              }
            }
          } else {
            // Someone else paid it, I paid my share back
            settled += getShare(userId);
          }
          continue;
        }

        // Expense is pending, check individual settlements
        if (exp.paidBy == userId) {
          // Others owe me
          for (var m in exp.splitMembers) {
            if (m != userId && m != 'You') {
              if (exp.settledMembers.contains(m)) {
                // This person settled their share with me
                settled += getShare(m);
              } else {
                // This person still owes me
                owedToYou += getShare(m);
              }
            }
          }
        } else if (exp.splitMembers.contains(userId) ||
            exp.splitMembers.contains('You')) {
          // I owe someone else
          final myId = exp.splitMembers.contains(userId) ? userId : 'You';
          if (exp.settledMembers.contains(myId)) {
            // I settled my share
            settled += getShare(myId);
          } else {
            // I still owe
            youOwe += getShare(myId);
          }
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
                          : RefreshIndicator(
                              onRefresh: () async {
                                Provider.of<SplitProvider>(context,
                                        listen: false)
                                    .loadGroups(userId);
                              },
                              color: AppTheme.primaryPurple,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                itemCount: splitProvider.groups.length,
                                itemBuilder: (context, i) =>
                                    _groupCard(splitProvider.groups[i], i),
                              ),
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
      onTap: () => _showGroupDetails(
          group, Provider.of<AuthProvider>(context, listen: false)),
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
    final splitProvider = Provider.of<SplitProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    // Extract unique members from all groups (excluding current user)
    final allMembers = <String>{};
    for (final group in splitProvider.groups) {
      for (final member in group.members) {
        if (member != userId) {
          allMembers.add(member);
        }
      }
    }

    final friends = allMembers.toList();

    if (friends.isEmpty) {
      return _buildEmptyState(
          'No friends yet', 'Add friends to a split group to see them here');
    }

    return RefreshIndicator(
      onRefresh: () async {
        Provider.of<SplitProvider>(context, listen: false).loadGroups(userId);
      },
      color: AppTheme.primaryPurple,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: friends.length,
        itemBuilder: (context, i) {
          final friendName = friends[i];

          // Calculate balance with this friend across all groups
          double balance = 0;
          for (final group in splitProvider.groups) {
            final expenses = splitProvider.getExpenses(group.groupId);
            for (final exp in expenses) {
              if (exp.status == ExpenseStatus.settled) continue;

              if (exp.paidBy == userId &&
                  exp.splitMembers.contains(friendName)) {
                // Friend owes me their share, UNLESS they've already settled
                if (!exp.settledMembers.contains(friendName)) {
                  balance += exp.memberShares[friendName] ??
                      (exp.amount / exp.splitMembers.length);
                }
              } else if (exp.paidBy == friendName &&
                  exp.splitMembers.contains(userId)) {
                // I owe friend my share, UNLESS I've already settled with them
                if (!exp.settledMembers.contains(userId)) {
                  balance -= exp.memberShares[userId] ??
                      (exp.amount / exp.splitMembers.length);
                }
              }
            }
          }

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
                    child: Text(friendName[0].toUpperCase(),
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
                  Text(friendName,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  Text(
                    balance == 0
                        ? 'Settled'
                        : balance > 0
                            ? 'Owes you ${_fmt.format(balance)}'
                            : 'You owe ${_fmt.format(balance.abs())}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: balance == 0
                            ? AppTheme.successGreen
                            : balance > 0
                                ? AppTheme.successGreen
                                : AppTheme.errorRed,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              )),
              if (balance > 0)
                Container(
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
                )
              else if (balance == 0)
                Text('Settled ✅',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.w600)),
            ]),
          );
        },
      ),
    );
  }

  void _showAddSplitDialog() {
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddSplitBottomSheet(
        userId: userId,
        onAdd: (title, amount, members) async {
          final groupId = DateTime.now().millisecondsSinceEpoch.toString();

          // Collect group members (IDs or names)
          final groupMembers = members.map((m) => m.id).toList();

          final group = SplitGroupModel(
            groupId: groupId,
            groupName: title,
            createdBy: userId,
            members: groupMembers,
            groupType: 'friends',
          );

          try {
            await splitProvider.createGroup(group);

            // 2. Create the first expense for this split
            final expenseId = 'exp_$groupId';
            final memberShares = {for (var m in members) m.id: m.share};

            final expense = GroupExpenseModel(
              expenseId: expenseId,
              groupId: groupId,
              paidBy: userId,
              amount: amount,
              description: title,
              splitMembers: groupMembers,
              memberShares: memberShares,
              status: ExpenseStatus.pending,
              settledMembers: [], // Initialize as empty
            );

            await splitProvider.addGroupExpense(expense);
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Split "$title" created! 🤝'),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to create split. Please try again.'),
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showAddBillDialog(SplitGroupModel group) {
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddSplitBottomSheet(
        userId: userId,
        initialGroupMembers: group.members,
        onAdd: (title, amount, members) async {
          // Use only provided members as split participants
          final splitMembers = members.map((m) => m.id).toList();
          final memberShares = {for (var m in members) m.id: m.share};

          final expenseId = 'exp_${DateTime.now().millisecondsSinceEpoch}';
          final expense = GroupExpenseModel(
            expenseId: expenseId,
            groupId: group.groupId,
            paidBy: userId,
            amount: amount,
            description: title,
            splitMembers: splitMembers,
            memberShares: memberShares,
            status: ExpenseStatus.pending,
            settledMembers: [], // Initialize as empty
          );

          try {
            await splitProvider.addGroupExpense(expense);
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "$title" to ${group.groupName}'),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Re-show group details to see the new bill
            _showGroupDetails(group, authProvider);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add bill. Please try again.'),
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showGroupDetails(SplitGroupModel group, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<SplitProvider>(
        builder: (context, splitProvider, child) {
          final expenses = splitProvider.getExpenses(group.groupId);
          final totalAmount =
              expenses.fold(0.0, (sum, exp) => sum + exp.amount);

          return Container(
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
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddBillDialog(group);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text('Add Bill',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
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
                  Text('Bill Details',
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Bill: ${exp.description}',
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
                                                color: exp.status ==
                                                        ExpenseStatus.settled
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
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppTheme.divider),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Split Details',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textMedium)),
                                  // Removed group-level "Mark as Settled" button
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...() {
                                // Filter out the literal string "You" to fix previous bug, unless it's the only reference
                                final validMembers = exp.splitMembers
                                    .where((m) => m != 'You')
                                    .toList();
                                if (exp.splitMembers.contains('You') &&
                                    !validMembers
                                        .contains(authProvider.user?.uid)) {
                                  validMembers
                                      .add(authProvider.user?.uid ?? '');
                                }

                                return validMembers.map((mId) {
                                  final isMe = mId == authProvider.user?.uid;
                                  final name = isMe ? 'You' : mId;

                                  // Check map first, otherwise fallback to equal split
                                  double share = 0;
                                  if (exp.memberShares.isNotEmpty &&
                                      exp.memberShares.containsKey(mId)) {
                                    share = exp.memberShares[mId]!;
                                  } else if (exp.memberShares.isNotEmpty &&
                                      isMe &&
                                      exp.memberShares.containsKey('You')) {
                                    share = exp.memberShares['You']!;
                                  } else {
                                    share = exp.amount / validMembers.length;
                                  }

                                  final isSettled =
                                      exp.settledMembers.contains(mId);
                                  final canSettle = !isSettled &&
                                      exp.status == ExpenseStatus.pending &&
                                      exp.paidBy == authProvider.user?.uid &&
                                      !isMe;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? AppTheme.primaryPurple
                                                : AppTheme.background,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppTheme.divider),
                                          ),
                                          child: Center(
                                            child: Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : '?',
                                                style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: isMe
                                                        ? Colors.white
                                                        : AppTheme.textMedium)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(name,
                                              style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: isMe
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                  color: isSettled
                                                      ? AppTheme.textMedium
                                                      : AppTheme.textDark,
                                                  decoration: isSettled
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null)),
                                        ),
                                        if (canSettle)
                                          GestureDetector(
                                            onTap: () async {
                                              // Show confirmation dialog
                                              final confirmed =
                                                  await showDialog<bool>(
                                                        context: context,
                                                        barrierDismissible:
                                                            false,
                                                        builder:
                                                            (dialogContext) =>
                                                                AlertDialog(
                                                          title: Text(
                                                            'Confirm Settlement',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: AppTheme
                                                                  .textDark,
                                                            ),
                                                          ),
                                                          content: Text(
                                                            'Mark $name\'s payment of ${_fmt.format(share)} as settled?',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 14,
                                                              color: AppTheme
                                                                  .textMedium,
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      dialogContext,
                                                                      false),
                                                              child: Text(
                                                                'Cancel',
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  color: AppTheme
                                                                      .textMedium,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      dialogContext,
                                                                      true),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    AppTheme
                                                                        .successGreen,
                                                              ),
                                                              child: Text(
                                                                'Settle',
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ) ??
                                                      false;

                                              if (!confirmed ||
                                                  !context.mounted) return;

                                              try {
                                                final settledList =
                                                    List<String>.from(
                                                        exp.settledMembers)
                                                      ..add(mId);
                                                // If everyone but the payer has settled, mark the whole expense as settled
                                                final allOthersSettled =
                                                    validMembers
                                                        .where((m) =>
                                                            m != exp.paidBy)
                                                        .every((m) =>
                                                            settledList
                                                                .contains(m));

                                                final updatedExp =
                                                    GroupExpenseModel(
                                                  expenseId: exp.expenseId,
                                                  groupId: exp.groupId,
                                                  paidBy: exp.paidBy,
                                                  amount: exp.amount,
                                                  description: exp.description,
                                                  splitMembers:
                                                      exp.splitMembers,
                                                  memberShares:
                                                      exp.memberShares,
                                                  settledMembers: settledList,
                                                  status: allOthersSettled
                                                      ? ExpenseStatus.settled
                                                      : exp.status,
                                                  createdAt: exp.createdAt,
                                                );

                                                // Update in Firebase
                                                await Provider.of<
                                                            SplitProvider>(
                                                        context,
                                                        listen: false)
                                                    .updateGroupExpense(
                                                        updatedExp);

                                                // Wait a bit for Firestore to sync
                                                await Future.delayed(
                                                    const Duration(
                                                        milliseconds: 800));

                                                if (context.mounted) {
                                                  // Show success message
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        allOthersSettled
                                                            ? 'Bill settled! ✅'
                                                            : '$name\'s payment received ✅',
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.successGreen,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      duration: const Duration(
                                                          milliseconds: 1500),
                                                    ),
                                                  );

                                                  // Close the modal and reopen to refresh the view
                                                  Navigator.pop(context);
                                                  // Small delay to allow modal to close smoothly
                                                  await Future.delayed(
                                                      const Duration(
                                                          milliseconds: 300));
                                                  if (context.mounted) {
                                                    _showGroupDetails(
                                                        group, authProvider);
                                                  }
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Error settling payment: $e'),
                                                      backgroundColor:
                                                          AppTheme.errorRed,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              margin: const EdgeInsets.only(
                                                  right: 8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryPurple
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text('Settle',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppTheme
                                                          .primaryPurple)),
                                            ),
                                          ),
                                        if (isSettled)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Icon(
                                                Icons.check_circle_rounded,
                                                color: AppTheme.successGreen,
                                                size: 16),
                                          ),
                                        Text(_fmt.format(share),
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isSettled
                                                    ? AppTheme.textMedium
                                                    : AppTheme.textDark,
                                                decoration: isSettled
                                                    ? TextDecoration.lineThrough
                                                    : null)),
                                      ],
                                    ),
                                  );
                                });
                              }(),
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
          );
        },
      ),
    );
  }
}

class _AddSplitBottomSheet extends StatefulWidget {
  final String userId;
  final List<String>? initialGroupMembers;
  final Function(String title, double amount, List<SplitMember> members) onAdd;

  const _AddSplitBottomSheet(
      {required this.onAdd, required this.userId, this.initialGroupMembers});

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

    // Pre-populate members if provided
    if (widget.initialGroupMembers != null) {
      for (var m in widget.initialGroupMembers!) {
        if (m != widget.userId && m != 'You') {
          _members.add(SplitMember(
            id: m,
            name: m,
            share: 0,
            hasPaid: false,
          ));
        }
      }
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
        id: name, // Use Name as ID for simplicity
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

    if (assignedAmount == 0 && totalAmount > 0) {
      // Split equally among everyone (including You)
      final count = finalMembers.length + 1; // +1 for "You"
      final perPerson = totalAmount / count;

      for (int i = 0; i < finalMembers.length; i++) {
        finalMembers[i] = SplitMember(
          id: finalMembers[i].id,
          name: finalMembers[i].name,
          share: perPerson,
          hasPaid: false,
        );
      }

      finalMembers.insert(
        0,
        SplitMember(
          id: widget.userId,
          name: 'You',
          share: perPerson,
          hasPaid: true,
        ),
      );
    } else {
      // User specified some amounts, or didn't provide any at all. Remaining goes to "You".
      final remaining = totalAmount - assignedAmount;
      finalMembers.insert(
        0,
        SplitMember(
          id: widget.userId,
          name: 'You',
          share: remaining > 0 ? remaining : 0,
          hasPaid: true,
        ),
      );
    }

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
