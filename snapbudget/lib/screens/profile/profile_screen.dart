import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../welcome/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Profile',
                              style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ]),
                    const SizedBox(height: 24),
                    // Avatar
                    Stack(children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5), width: 3),
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 50, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                              color: AppTheme.successGreen,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text('Rahul Sharma',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('+91 98765 43210',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 16),
                    // Stats row
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _headerStat('₹1.24L', 'Balance'),
                      _vDivider(),
                      _headerStat('89', 'Transactions'),
                      _vDivider(),
                      _headerStat('4', 'Splits'),
                    ]),
                  ]),
                ),
              ),
            ),

            // Offset card
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _quickProfileBtn(Icons.document_scanner_rounded, 'Scan',
                            AppTheme.primaryPurple),
                        _quickProfileBtn(Icons.people_rounded, 'SplitSync',
                            AppTheme.accentBlue),
                        _quickProfileBtn(Icons.download_rounded, 'Export',
                            AppTheme.successGreen),
                        _quickProfileBtn(Icons.share_rounded, 'Share',
                            AppTheme.warningOrange),
                      ]),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(children: [
                _sectionHeader('Account'),
                _settingTile(Icons.account_circle_rounded, 'Personal Info',
                    'Update your details', AppTheme.primaryPurple),
                _settingTile(Icons.account_balance_rounded, 'Linked Accounts',
                    '2 accounts linked', AppTheme.accentBlue),
                _settingTile(Icons.security_rounded, 'Security & Privacy',
                    'PIN, Biometrics', AppTheme.successGreen),

                const SizedBox(height: 8),
                _sectionHeader('Budget & Alerts'),
                _settingTile(Icons.savings_rounded, 'Monthly Budget',
                    '₹15,000 set', AppTheme.warningOrange),
                _settingTile(Icons.notifications_rounded, 'Notifications',
                    'Smart alerts on', AppTheme.errorRed),
                _settingTile(Icons.cloud_sync_rounded, 'Cloud Backup',
                    'Auto sync enabled', AppTheme.accentBlue),

                const SizedBox(height: 8),
                _sectionHeader('App'),
                _settingTile(Icons.color_lens_rounded, 'Appearance',
                    'Light mode', AppTheme.primaryPurple),
                _settingTile(Icons.info_rounded, 'About SnapBudget',
                    'Version 1.0.0', AppTheme.textLight),
                _settingTile(Icons.help_rounded, 'Help & Support',
                    'FAQ, Contact us', AppTheme.accentBlue),

                const SizedBox(height: 20),

                // Logout
                GestureDetector(
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const WelcomeScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) =>
                              FadeTransition(opacity: animation, child: child),
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                    (route) => false,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border:
                          Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: AppTheme.errorRed, size: 20),
                          const SizedBox(width: 8),
                          Text('Log Out',
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.errorRed)),
                        ]),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
      ]),
    );
  }

  Widget _vDivider() {
    return Container(
        width: 1, height: 30, color: Colors.white.withOpacity(0.2));
  }

  Widget _quickProfileBtn(IconData icon, String label, Color color) {
    return Column(children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMedium)),
    ]);
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textLight,
                letterSpacing: 0.5)),
      ),
    );
  }

  Widget _settingTile(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
          Text(subtitle,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
        ])),
        const Icon(Icons.chevron_right_rounded,
            color: AppTheme.textLight, size: 20),
      ]),
    );
  }
}
