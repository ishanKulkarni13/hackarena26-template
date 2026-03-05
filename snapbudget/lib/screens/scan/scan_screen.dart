import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/transaction_model.dart';
import '../../services/gemini_receipt_service.dart';
import '../../theme/app_theme.dart';
import 'receipt_confirm_sheet.dart';

class ScanScreen extends StatefulWidget {
  final int initialMode;
  const ScanScreen({super.key, this.initialMode = 0});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  int _selectedMode = 0; // 0=Receipt 1=SMS 2=Voice
  bool _isProcessing = false; // true while calling Gemini

  final List<String> _modes = ['Receipt', 'SMS/UPI', 'Voice'];
  final List<IconData> _modeIcons = [
    Icons.document_scanner_rounded,
    Icons.sms_rounded,
    Icons.mic_rounded,
  ];

  final _picker = ImagePicker();
  final _geminiService = GeminiReceiptService();

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
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

  // ─── Camera / Gallery capture ────────────────────────────────────────────

  Future<void> _captureAndAnalyse(ImageSource source) async {
    // 1. Check & request permission
    final permissionGranted = await _ensurePermission(source);
    if (!permissionGranted) return;

    // 2. Open camera / gallery
    final XFile? imageFile = await _picker.pickImage(
      source: source,
      imageQuality: 85, // slightly compressed to speed up API call
      maxWidth: 2048,
    );
    if (imageFile == null) return; // user cancelled

    // 3. Show loading overlay while Gemini processes
    if (!mounted) return;
    setState(() => _isProcessing = true);

    // 4. Send to Gemini
    final result = await _geminiService.analyseReceipt(imageFile);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // 5. Show confirmation sheet
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // lets sheet resize with keyboard
      builder: (ctx) => ReceiptConfirmSheet(
        result: result,
        onSave: (Transaction tx) {
          // ─── Firebase / Provider integration point ───
          // TODO: Replace this print with provider.addTransaction(tx)
          //       once the Firebase friend wires up state management.
          debugPrint(
            '✅ Receipt saved: ${tx.title} | ₹${tx.amount} | ${tx.category.label}',
          );

          // Show a success snackbar so the user gets feedback now
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${tx.title} — ₹${tx.amount.toStringAsFixed(0)} added!',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  /// Requests the appropriate permission for camera or gallery.
  /// Returns true if granted. Shows a dialog if permanently denied.
  Future<bool> _ensurePermission(ImageSource source) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;

    var status = await permission.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted) return true;
    }

    if (status.isPermanentlyDenied && mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            source == ImageSource.camera
                ? 'Camera Permission Required'
                : 'Photo Library Permission Required',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark),
          ),
          content: Text(
            source == ImageSource.camera
                ? 'SnapBudget needs camera access to scan receipts. Please enable it in your device settings.'
                : 'SnapBudget needs photo library access to import receipts. Please enable it in your device settings.',
            style:
                GoogleFonts.inter(fontSize: 14, color: AppTheme.textMedium),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppTheme.textMedium)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                openAppSettings(); // opens device Settings for this app
              },
              child: Text('Open Settings',
                  style: GoogleFonts.inter(
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
    return false;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          SafeArea(
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
                          color: Colors.white.withValues(alpha: 0.1),
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
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: List.generate(
                          _modes.length,
                          (i) => Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedMode = i),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: _selectedMode == i
                                          ? AppTheme.primaryGradient
                                          : null,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

          // Processing overlay — shows while Gemini is working
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: AppTheme.accentBlue,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Analysing receipt…',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AI is reading your receipt',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Camera View ──────────────────────────────────────────────────────────

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
                        color: AppTheme.primaryPurple.withValues(alpha: 0.5),
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
                              top: (_pulseController.value * 300)
                                  .clamp(10, 300),
                              left: 40,
                              right: 40,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.accentBlue
                                          .withValues(alpha: 0.8),
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

        // Capture controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gallery button — now wired to image picker
            GestureDetector(
              onTap: _isProcessing
                  ? null
                  : () => _captureAndAnalyse(ImageSource.gallery),
              child: _roundBtn(Icons.photo_library_rounded),
            ),
            const SizedBox(width: 30),

            // Main capture button — opens native camera
            GestureDetector(
              onTap: _isProcessing
                  ? null
                  : () => _captureAndAnalyse(ImageSource.camera),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isProcessing ? 0.5 : 1.0,
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
            ),
            const SizedBox(width: 30),
            _roundBtn(Icons.flash_on_rounded),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── SMS View ─────────────────────────────────────────────────────────────

  Widget _buildSMSView() {
    return SingleChildScrollView(
      key: const ValueKey('sms'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.2),
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
                  _smsItem('Paytm', 'UPI payment of ₹348 successful',
                      '4h ago', false),
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
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXL)),
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

  // ─── Voice View ───────────────────────────────────────────────────────────

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
                AppTheme.primaryPurple.withValues(alpha: 0.4),
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
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                color: AppTheme.accentBlue, size: 18),
            const SizedBox(width: 10),
            Text('AI will auto-categorize your expense',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white70)),
          ]),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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
          color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _smsItem(
      String sender, String message, String time, bool isCredit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: isCredit
                    ? AppTheme.successGreen.withValues(alpha: 0.15)
                    : AppTheme.errorRed.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isCredit ? AppTheme.successGreen : AppTheme.errorRed,
                size: 16)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(sender,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              Text(message,
                  style:
                      GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ])),
        Text(time,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
      ]),
    );
  }
}
