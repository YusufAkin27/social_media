import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';

class NoStoryScreen extends StatelessWidget {
  final String message;
  final String? subMessage;
  final bool isError;
  final VoidCallback onRetry;
  final VoidCallback onReturn;

  const NoStoryScreen({
    Key? key,
    this.message = 'Hikaye Bulunamadı',
    this.subMessage,
    this.isError = false,
    required this.onRetry,
    required this.onReturn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Tema provider'dan tema bilgilerini al
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Tema bazlı renkler
    final backgroundColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final secondaryColor = isDarkMode ? Colors.blue[300] : Colors.blue[500];
    final errorColor = isDarkMode ? Colors.redAccent : Colors.red[400];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kapatma butonu (X)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: Icon(Icons.close, color: textColor, size: 28),
                  onPressed: onReturn,
                ),
              ),
            ),

            // Boş alan
            const Spacer(),

            // Ana içerik
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // İkon
                  Icon(
                    isError
                        ? LineIcons.exclamationTriangle
                        : LineIcons.photoVideo,
                    size: 80,
                    color: isError ? errorColor : secondaryColor,
                  )
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.easeOutBack)
                      .shimmer(delay: 400.ms, duration: 1800.ms),

                  const SizedBox(height: 32),

                  // Ana mesaj
                  Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms, delay: 300.ms).moveY(
                      begin: 20,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOutQuad),

                  const SizedBox(height: 16),

                  // Alt mesaj (varsa)
                  if (subMessage != null)
                    Text(
                      subMessage!,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 600.ms, delay: 600.ms),

                  const SizedBox(height: 48),

                  // Butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Yeniden dene butonu
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: Icon(LineIcons.alternateRedo, size: 20),
                        label: Text('Yeniden Dene'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: accentColor,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 800.ms)
                          .moveY(begin: 20, end: 0, duration: 500.ms),

                      const SizedBox(width: 16),

                      // Ana sayfaya dön butonu
                      ElevatedButton.icon(
                        onPressed: onReturn,
                        icon: Icon(LineIcons.home, size: 20),
                        label: Text('Ana Sayfaya Dön'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              isDarkMode ? Colors.grey[800] : Colors.grey[600],
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 1000.ms)
                          .moveY(begin: 20, end: 0, duration: 500.ms),
                    ],
                  ),
                ],
              ),
            ),

            // Boş alan
            const Spacer(),

            // Alt bilgi
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Daha sonra tekrar kontrol edin',
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 1200.ms),
          ],
        ),
      ),
    );
  }
}
