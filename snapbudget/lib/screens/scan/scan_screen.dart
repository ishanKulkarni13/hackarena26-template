import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  int _selectedMode = 0; // 0=Receipt 1=SMS 2=Voice

  final List<String> _modes = ['Receipt', 'SMS/UPI', 'Voice'];
  final List<IconData> _modeIcons = [
    Icons.document_scanner_rounded,
    Icons.sms_rounded,
    Icons.mic_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Scan & Detect',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline_rounded,
                        color: Colors.white70, size: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Mode selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: List.generate(
                      _modes.length,
                      (i) => Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedMode = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: _selectedMode == i
                                      ? AppTheme.primaryGradient
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_modeIcons[i],
                                        size: 14,
                                        color: _selectedMode == i
                                            ? Colors.white
                                            : Colors.white54),
                                    const SizedBox(width: 4),
                                    Text(_modes[i],
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedMode == i
                                              ? Colors.white
                                              : Colors.white54,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          )),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Scan area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedMode == 0
                    ? _buildCameraView()
                    : _selectedMode == 1
                        ? _buildSMSView()
                        : _buildVoiceView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      key: const ValueKey('camera'),
      children: [
        // Camera viewfinder
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppTheme.primaryPurple.withOpacity(0.5),
                        width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Simulated camera bg
                        Container(color: const Color(0xFF0D0D0D)),

                        // Scan frame corners
                        _buildScanCorners(),

                        // Scan line animation
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Positioned(
                              top:
                                  (_pulseController.value * 300).clamp(10, 300),
                              left: 40,
                              right: 40,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.accentBlue.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        Center(
                          child: Text(
                            'Point camera at receipt',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Capture button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roundBtn(Icons.photo_library_rounded),
            const SizedBox(width: 30),
            GestureDetector(
              onTap: _showReceiptResult,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(width: 30),
            _roundBtn(Icons.flash_on_rounded),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSMSView() {
    return SingleChildScrollView(
      key: const ValueKey('sms'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.sms_rounded,
                          color: AppTheme.accentBlue, size: 20)),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SMS Auto-Detection',
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text('3 new transactions found',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white54)),
                      ]),
                ]),
                const SizedBox(height: 16),
                ...[
                  _smsItem('HDFC Bank UPI', 'Debited ₹520 to Uber India',
                      '2h ago', false),
                  _smsItem('Paytm', 'UPI payment of ₹348 successful', '4h ago',
                      false),
                  _smsItem('SBI NetBanking', 'Credited ₹65,000 – Salary',
                      '1d ago', true),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
                    child: Center(
                        child: Text('Import All Transactions',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceView() {
    return Column(
      key: const ValueKey('voice'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.primaryPurple.withOpacity(0.4),
                Colors.transparent
              ]),
            ),
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
              child:
                  const Icon(Icons.mic_rounded, color: Colors.white, size: 50),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text('Tap to speak',
            style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text('Say something like:\n"I spent ₹500 on food at Swiggy"',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14, color: Colors.white54, height: 1.6)),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                color: AppTheme.accentBlue, size: 18),
            const SizedBox(width: 10),
            Text('AI will auto-categorize your expense',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
          ]),
        ),
      ],
    );
  }

  Widget _buildScanCorners() {
    final corner = (Alignment alignment) => Align(
          alignment: alignment,
          child: Container(
            margin: const EdgeInsets.all(20),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              border: Border(
                top: alignment == Alignment.topLeft ||
                        alignment == Alignment.topRight
                    ? const BorderSide(color: AppTheme.accentBlue, width: 3)
                    : BorderSide.none,
                bottom: alignment == Alignment.bottomLeft ||
                        alignment == Alignment.bottomRight
                    ? const BorderSide(color: AppTheme.accentBlue, width: 3)
                    : BorderSide.none,
                left: alignment == Alignment.topLeft ||
                        alignment == Alignment.bottomLeft
                    ? const BorderSide(color: AppTheme.accentBlue, width: 3)
                    : BorderSide.none,
                right: alignment == Alignment.topRight ||
                        alignment == Alignment.bottomRight
                    ? const BorderSide(color: AppTheme.accentBlue, width: 3)
                    : BorderSide.none,
              ),
            ),
          ),
        );
    return Stack(children: [
      corner(Alignment.topLeft),
      corner(Alignment.topRight),
      corner(Alignment.bottomLeft),
      corner(Alignment.bottomRight),
    ]);
  }

  Widget _roundBtn(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _smsItem(String sender, String message, String time, bool isCredit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: isCredit
                    ? AppTheme.successGreen.withOpacity(0.15)
                    : AppTheme.errorRed.withOpacity(0.15),
                shape: BoxShape.circle),
            child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isCredit ? AppTheme.successGreen : AppTheme.errorRed,
                size: 16)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sender,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          Text(message,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ])),
        Text(time,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
      ]),
    );
  }

  void _showReceiptResult() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Receipt Detected ✅',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: AppTheme.textLight)),
            ]),
            const SizedBox(height: 20),
            _receiptRow('Merchant', 'Zomato'),
            _receiptRow('Amount', '₹420'),
            _receiptRow('Date', 'Mar 5, 2026'),
            _receiptRow('Category', '🍔 Food & Dining'),
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
                    child: Text('Add Transaction',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark)),
      ]),
    );
  }
}
