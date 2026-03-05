# Code Reference Guide

## Key Code Changes

### 1. Enhanced Split Bill Model
**File:** `lib/models/split_bill_model.dart`

```dart
class SplitBill {
  final String id;
  final String title;
  final double totalAmount;
  final List<SplitMember> members;
  final DateTime date;
  final String? description;
  final SplitStatus status;
  final Map<String, double>? expenseBreakdown; // NEW!

  SplitBill({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.members,
    required this.date,
    this.description,
    required this.status,
    this.expenseBreakdown, // NEW!
  });
  
  // ... rest of the class
}
```

---

### 2. Sample Data with Expense Breakdown
**File:** `lib/screens/splitsync/splitsync_screen.dart`

```dart
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
```

---

### 3. Helper Functions for Styling
**File:** `lib/screens/splitsync/splitsync_screen.dart`

```dart
// Get color based on status
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

// Get label for status
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

// Get color for expense category
Color _getExpenseCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'hotel':
      return const Color(0xFF5B8DEF); // Blue
    case 'food':
      return const Color(0xFFFFA500); // Orange
    case 'activities':
      return const Color(0xFFE91E63); // Pink
    case 'transport':
      return const Color(0xFF4CAF50); // Green
    case 'entertainment':
      return const Color(0xFF9C27B0); // Purple
    default:
      return AppTheme.primaryPurple;
  }
}
```

---

### 4. Enhanced Bill Details Popup Structure
**File:** `lib/screens/splitsync/splitsync_screen.dart`

```dart
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
            // 1. Header with title and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.title,
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark)),
                      if (bill.description != null)
                        Text(bill.description!,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textMedium)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            
            // 2. Total Amount
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
            
            // 3. Expense Breakdown (if available)
            if (bill.expenseBreakdown != null && 
                bill.expenseBreakdown!.isNotEmpty) ...[
              Text('Expense Breakdown',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 12),
              ...bill.expenseBreakdown!.entries.map((entry) => 
                Container(
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
                )
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.divider),
              const SizedBox(height: 16),
            ],
            
            // 4. Members & Payments
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
            
            // 5. Action Buttons
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
                          content: const Text(
                              'This action cannot be undone.'),
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
                        border: Border.all(
                            color: AppTheme.errorRed, width: 2),
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
```

---

## Key Features Breakdown

### Expense Breakdown Section
Automatically displays if `expenseBreakdown` is provided:
- Shows category name with colored dot
- Displays amount in rupees
- Calculates and shows percentage
- Color-coded by category type

### Member Status Display
For each member:
- Avatar with initial (Green if paid, Gray if pending)
- Full name
- Share amount
- Status text (Payment Complete / Awaiting Payment)
- Status badge (✓ Paid / Pending)

### Action Buttons
- Edit: Opens edit dialog preserving all data
- Delete: Shows confirmation dialog
- Close: Closes the popup

---

## Integration Notes

These changes are fully backward compatible:
- If `expenseBreakdown` is null, the section is skipped
- All other features work as before
- No breaking changes to existing code
- Can be applied to other splits gradually


