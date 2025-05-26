import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  _ThemeSelectionScreenState createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedThemeIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Mevcut tema tipini al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final currentThemeType = themeProvider.themeType;
      final allThemes = themeProvider.getAllThemes();

      // Mevcut temanın indexini bul
      for (int i = 0; i < allThemes.length; i++) {
        if (allThemes[i]['type'] == currentThemeType) {
          setState(() {
            _selectedThemeIndex = i;
          });
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final allThemes = themeProvider.getAllThemes();

    // Tema bazlı renkler
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final textSecondaryColor = Theme.of(context).textTheme.bodySmall?.color;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final surfaceColor =
        isDarkMode ? AppColors.surfaceColor : AppColors.lightSurfaceColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'Tema Seçimi',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bölümü
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarzınızı Seçin',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uygulamanın görünümünü dilediğiniz gibi özelleştirin',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tema önizleme
            Container(
              height: 160,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _getThemePreviewColor(
                    allThemes[_selectedThemeIndex]['type']),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Tema desenini ekle
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _buildThemePatternPreview(
                        allThemes[_selectedThemeIndex]['type']),
                  ),

                  // Tema ismi ve ikonu
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          allThemes[_selectedThemeIndex]['icon'],
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allThemes[_selectedThemeIndex]['name'],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tema listesi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Mevcut Temalar',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allThemes.length,
                itemBuilder: (context, index) {
                  final theme = allThemes[index];
                  final ThemeType themeType = theme['type'];
                  final String themeName = theme['name'];
                  final IconData themeIcon = theme['icon'];
                  final bool isSelected = index == _selectedThemeIndex;

                  // Her tema için rengini ayarla
                  Color themeColor = _getThemeColor(themeType);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? themeColor.withOpacity(0.2) : cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? themeColor : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: themeColor.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedThemeIndex = index;
                        });

                        // Tema değiştir
                        themeProvider.setThemeType(themeType);

                        // Animasyon
                        _animationController.reset();
                        _animationController.forward();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Tema önizleme renk örneği
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getThemePreviewColor(themeType),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  themeIcon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Tema adı
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    themeName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    _getThemeDescription(themeType),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: textSecondaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Seçili ise tik işareti
                            if (isSelected)
                              ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: _animationController,
                                  curve: Curves.elasticOut,
                                ),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tema türüne göre renk döndüren yardımcı metod
  Color _getThemeColor(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.dark:
        return AppColors.accent;
      case ThemeType.light:
        return AppColors.lightAccent;
      case ThemeType.vaporwave:
        return AppColors.vaporwaveAccent;
      case ThemeType.midnight:
        return AppColors.midnightAccent;
      case ThemeType.nature:
        return AppColors.natureAccent;
      case ThemeType.cream:
        return AppColors.creamAccent;
      default:
        return AppColors.accent;
    }
  }

  // Tema önizleme rengi için yardımcı metod
  Color _getThemePreviewColor(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.dark:
        return AppColors.background;
      case ThemeType.light:
        return AppColors.lightAccent;
      case ThemeType.vaporwave:
        return AppColors.vaporwaveBackground;
      case ThemeType.midnight:
        return AppColors.midnightBackground;
      case ThemeType.nature:
        return AppColors.natureBackground;
      case ThemeType.cream:
        return AppColors.creamBackground;
      default:
        return AppColors.background;
    }
  }

  // Tema açıklaması için yardımcı metod
  String _getThemeDescription(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.dark:
        return 'Modern ve şık karanlık tema';
      case ThemeType.light:
        return 'Ferah ve aydınlık tema';
      case ThemeType.vaporwave:
        return 'Retro 80\'ler stili neon tema';
      case ThemeType.midnight:
        return 'Derin gece mavisi tonları';
      case ThemeType.nature:
        return 'Doğal yeşil tonları ve organik hisler';
      case ThemeType.cream:
        return 'Sıcak ve rahatlatıcı pastel tonlar';
      default:
        return '';
    }
  }

  // Tema desenini oluşturan yardımcı metod
  Widget _buildThemePatternPreview(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.dark:
        return Container(
          color: AppColors.background,
          child: Opacity(
            opacity: 0.1,
            child: CustomPaint(
              painter: GridPainter(),
              size: Size.infinite,
            ),
          ),
        );
      case ThemeType.light:
        return Container(
          color: AppColors.lightAccent,
          child: Opacity(
            opacity: 0.1,
            child: CustomPaint(
              painter: CirclePainter(),
              size: Size.infinite,
            ),
          ),
        );
      case ThemeType.vaporwave:
        return Container(
          color: AppColors.vaporwaveBackground,
          child: Opacity(
            opacity: 0.2,
            child: CustomPaint(
              painter: VaporwavePainter(),
              size: Size.infinite,
            ),
          ),
        );
      case ThemeType.midnight:
        return Container(
          color: AppColors.midnightBackground,
          child: Opacity(
            opacity: 0.15,
            child: CustomPaint(
              painter: StarsPainter(),
              size: Size.infinite,
            ),
          ),
        );
      case ThemeType.nature:
        return Container(
          color: AppColors.natureBackground,
          child: Opacity(
            opacity: 0.15,
            child: CustomPaint(
              painter: LeafPainter(),
              size: Size.infinite,
            ),
          ),
        );
      case ThemeType.cream:
        return Container(
          color: AppColors.creamBackground,
          child: Opacity(
            opacity: 0.15,
            child: CustomPaint(
              painter: WavePainter(),
              size: Size.infinite,
            ),
          ),
        );
      default:
        return Container(color: AppColors.background);
    }
  }
}

// Çeşitli tema desenleri için Custom Painterlar
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const double space = 20;

    // Yatay çizgiler
    for (double i = 0; i < size.height; i += space) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Dikey çizgiler
    for (double i = 0; i < size.width; i += space) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Çeşitli büyüklüklerde daireler çiz
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 15, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), 25, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 10, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9), 15, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VaporwavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Izgaralı bir yüzey ve ufuk çizgisi
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint..color = Colors.cyanAccent.withOpacity(0.5),
      );
    }

    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint..color = Colors.pinkAccent.withOpacity(0.5),
      );
    }

    // Güneş
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      50,
      Paint()..color = Colors.pinkAccent.withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Yıldızları çiz
    final random = DateTime.now().microsecondsSinceEpoch.toDouble();
    for (int i = 0; i < 50; i++) {
      final x = (random * (i + 1)) % size.width;
      final y = (random * (i + 2)) % size.height;
      final radius = (random * (i + 3)) % 3 + 1;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Bir kaç yaprak şekli çiz
    final path = Path();

    // Orta yaprak
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.4,
        size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.4,
        size.width * 0.5, size.height * 0.2);

    canvas.drawPath(path, paint);

    // Sağ alt yaprak
    final path2 = Path();
    path2.moveTo(size.width * 0.7, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.9, size.height * 0.6,
        size.width * 0.8, size.height * 0.8);
    path2.quadraticBezierTo(size.width * 0.6, size.height * 0.7,
        size.width * 0.7, size.height * 0.5);

    canvas.drawPath(path2, paint);

    // Sol alt yaprak
    final path3 = Path();
    path3.moveTo(size.width * 0.3, size.height * 0.5);
    path3.quadraticBezierTo(size.width * 0.1, size.height * 0.6,
        size.width * 0.2, size.height * 0.8);
    path3.quadraticBezierTo(size.width * 0.4, size.height * 0.7,
        size.width * 0.3, size.height * 0.5);

    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Dalga çizgileri
    for (double i = 0; i < size.height; i += 40) {
      final path = Path();
      path.moveTo(0, i);

      // Dalga şekli
      for (double x = 0; x < size.width; x += 40) {
        path.quadraticBezierTo(
          x + 20,
          i + 20,
          x + 40,
          i,
        );
      }

      canvas.drawPath(
          path,
          paint
            ..color = Colors.orangeAccent.withOpacity((i / size.height) * 0.5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
