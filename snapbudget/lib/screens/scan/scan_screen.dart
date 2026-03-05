import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ─── Mode / animation ─────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  int _selectedMode = 0;

  final List<String> _modes = ['Receipt', 'SMS/UPI', 'Voice'];
  final List<IconData> _modeIcons = [
    Icons.document_scanner_rounded,
    Icons.sms_rounded,
    Icons.mic_rounded,
  ];

  // ─── Camera state ─────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionDenied = false;
  bool _isTorchOn = false;
  bool _isProcessing = false; // Gemini is working
  bool _isCapturing = false; // shutter flash in progress
  bool _showShutterFlash = false;

  // ─── Services ─────────────────────────────────────────────────────────────
  final _picker = ImagePicker();
  final _geminiService = GeminiReceiptService();

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;

    // Pulse animation (scan-line + voice orb)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);

    // Observe app lifecycle so camera pauses when app goes to background
    WidgetsBinding.instance.addObserver(this);

    // Kick off camera init on the next frame so build() can run first
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  /// Pauses preview when app is backgrounded, resumes when it returns.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      controller.resumePreview();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Camera initialisation
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    // 1. Permission check
    var status = await Permission.camera.status;
    if (status.isDenied) status = await Permission.camera.request();

    if (!status.isGranted) {
      if (mounted) setState(() => _isCameraPermissionDenied = true);
      return;
    }

    // 2. Pick the back camera
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    // 3. Create and initialize the controller
    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false, // receipts don't need audio
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      // Keep screen awake while camera is live
      await controller.setFlashMode(FlashMode.off);
    } catch (e) {
      debugPrint('❌ [CameraController] init error: $e');
      return;
    }

    if (!mounted) {
      controller.dispose();
      return;
    }

    setState(() {
      _cameraController = controller;
      _isCameraInitialized = true;
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Capture & analyse
  // ──────────────────────────────────────────────────────────────────────────

  /// Takes a photo using the embedded CameraController (no context-switching).
  Future<void> _captureFromCamera() async {
    if (!_isCameraInitialized ||
        _cameraController == null ||
        _isProcessing ||
        _isCapturing) return;

    setState(() => _isCapturing = true);

    // Shutter flash effect
    setState(() => _showShutterFlash = true);
    HapticFeedback.lightImpact();
    Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _showShutterFlash = false);
    });

    // Take the picture
    XFile? imageFile;
    try {
      imageFile = await _cameraController!.takePicture();
    } catch (e) {
      debugPrint('❌ [ScanScreen] takePicture error: $e');
      if (mounted) setState(() => _isCapturing = false);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isCapturing = false;
      _isProcessing = true;
    });

    // Send to Gemini
    final result = await _geminiService.analyseReceipt(imageFile);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final user = context.read<AuthProvider>().user;
    final userId = user?.uid ?? '';

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ReceiptConfirmSheet(
        result: result,
        userId: userId,
        onSave: (Transaction tx) {
          context.read<TransactionProvider>().addTransaction(tx);

          debugPrint(
            '✅ Receipt saved: ${tx.title} | ₹${tx.amount} | ${tx.category.label}',
          );
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

  /// Opens the gallery via image_picker (unchanged flow from before).
  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    var status = await Permission.photos.status;
    if (status.isDenied) status = await Permission.photos.request();

    if (!status.isGranted && !status.isLimited) {
      if (status.isPermanentlyDenied && mounted) {
        await _showSettingsDialog('Photo Library');
      }
      return;
    }

    final XFile? imageFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (imageFile == null || !mounted) return;

    setState(() => _isProcessing = true);
    final result = await _geminiService.analyseReceipt(imageFile);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    final user = context.read<AuthProvider>().user;
    final userId = user?.uid ?? '';

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ReceiptConfirmSheet(
        result: result,
        userId: userId,
        onSave: (Transaction tx) {
          context.read<TransactionProvider>().addTransaction(tx);

          debugPrint(
            '✅ Receipt saved: ${tx.title} | ₹${tx.amount} | ${tx.category.label}',
          );
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

  /// Toggles camera torch / flash.
  Future<void> _toggleTorch() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      await _cameraController!.setFlashMode(
        _isTorchOn ? FlashMode.off : FlashMode.torch,
      );
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  Future<void> _showSettingsDialog(String permName) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permName Permission',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
        content: Text(
          'SnapBudget needs $permName access. Please enable it in device settings.',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMedium),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.textMedium)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
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

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildModeSelector(),
                const SizedBox(height: 24),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedMode == 0
                        ? _buildReceiptView()
                        : _selectedMode == 1
                            ? _buildSMSView()
                            : _buildVoiceView(),
                  ),
                ),
              ],
            ),
          ),

          // ── Shutter flash ──────────────────────────────────────────────
          if (_showShutterFlash)
            AnimatedOpacity(
              opacity: _showShutterFlash ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 80),
              child: Container(color: Colors.white.withValues(alpha: 0.6)),
            ),

          // ── Gemini processing overlay ──────────────────────────────────
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.72),
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

  // ──────────────────────────────────────────────────────────────────────────
  // Header & mode selector
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
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
    );
  }

  Widget _buildModeSelector() {
    return Padding(
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
                onTap: () => setState(() => _selectedMode = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient:
                        _selectedMode == i ? AppTheme.primaryGradient : null,
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
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Receipt / Camera view
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildReceiptView() {
    return Column(
      key: const ValueKey('camera'),
      children: [
        // ── Viewfinder ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── Layer 1: Live camera feed or placeholder ──
                      _buildCameraLayer(),

                      // ── Layer 2: Neon corner brackets ──
                      _buildScanCorners(),

                      // ── Layer 3: Animated scan line ──
                      if (_isCameraInitialized)
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
                                      AppTheme.accentBlue
                                          .withValues(alpha: 0.9),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // ── Layer 4: "Point camera at receipt" hint (when ready) ──
                      if (_isCameraInitialized)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Point at receipt & tap capture',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Controls row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gallery
            GestureDetector(
              onTap: _isProcessing ? null : _pickFromGallery,
              child: _roundBtn(Icons.photo_library_rounded),
            ),
            const SizedBox(width: 30),

            // Capture button
            GestureDetector(
              onTap: (_isProcessing || _isCapturing || !_isCameraInitialized)
                  ? null
                  : _captureFromCamera,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: (_isProcessing || !_isCameraInitialized) ? 0.5 : 1.0,
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

            // Torch
            GestureDetector(
              onTap: _isCameraInitialized ? _toggleTorch : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isTorchOn
                      ? AppTheme.accentBlue.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: _isTorchOn
                      ? Border.all(
                          color: AppTheme.accentBlue.withValues(alpha: 0.7),
                          width: 1.5)
                      : null,
                ),
                child: Icon(
                  _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: _isTorchOn ? AppTheme.accentBlue : Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  /// The live camera layer — handles all 3 states: loading, denied, ready.
  Widget _buildCameraLayer() {
    // Permission denied
    if (_isCameraPermissionDenied) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_rounded, color: Colors.white30, size: 52),
            const SizedBox(height: 16),
            Text(
              'Camera access denied',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: openAppSettings,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
                child: Text('Open Settings',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }

    // Initialising
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: AppTheme.accentBlue,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    // Live preview — fill the entire box
    return CameraPreview(_cameraController!);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SMS view
  // ──────────────────────────────────────────────────────────────────────────

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
                  _smsItem('Paytm', 'UPI payment of ₹348 successful', '4h ago',
                      false),
                  _smsItem('SBI NetBanking', 'Credited ₹65,000 – Salary',
                      '1d ago', true),
                ],
                const SizedBox(height: 16),
                Container(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Voice view
  // ──────────────────────────────────────────────────────────────────────────

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
                Colors.transparent,
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
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
          ]),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildScanCorners() {
    Widget corner(Alignment alignment) => Align(
          alignment: alignment,
          child: Container(
            margin: const EdgeInsets.all(20),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              border: Border(
                top: (alignment == Alignment.topLeft ||
                        alignment == Alignment.topRight)
                    ? const BorderSide(color: AppTheme.accentBlue, width: 3)
                    : BorderSide.none,
                bottom: (alignment == Alignment.bottomLeft ||
                        alignment == Alignment.bottomRight)
                    ? const BorderSide(color: AppTheme.accentBlue, width: 3)
                    : BorderSide.none,
                left: (alignment == Alignment.topLeft ||
                        alignment == Alignment.bottomLeft)
                    ? const BorderSide(color: AppTheme.accentBlue, width: 3)
                    : BorderSide.none,
                right: (alignment == Alignment.topRight ||
                        alignment == Alignment.bottomRight)
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

  Widget _smsItem(String sender, String message, String time, bool isCredit) {
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
}
