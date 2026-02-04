import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class ScreenTestPage extends StatefulWidget {
  const ScreenTestPage({super.key});

  @override
  State<ScreenTestPage> createState() => _ScreenTestPageState();
}

class _ScreenTestPageState extends State<ScreenTestPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _ghostController;

  bool showInfo = true;
  int _currentTestIndex = 0;

  // --- ÖLÜ PİKSEL İÇİN DEĞİŞKENLER (Buraya taşıdık) ---
  int _deadPixelIndex = 0;
  final List<Color> _deadPixelColors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.cyan,
    Colors.purple,
    Colors.yellow,
  ];
  // ----------------------------------------------------

  @override
  void initState() {
    super.initState();
    _enterFullScreen();
    _ghostController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _exitFullScreen();
    _ghostController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _enterFullScreen() async {
    await windowManager.setFullScreen(true);
  }

  Future<void> _exitFullScreen() async {
    await windowManager.setFullScreen(false);
  }

  void _handleExit() {
    _exitFullScreen();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              _handleExit();
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease);
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease);
            }
          }
        },
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentTestIndex = index;
                  showInfo = true;
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => showInfo = false);
                  });
                });
              },
              children: [
                _buildDeadPixelTest(), // Artık düzgün çalışacak
                _buildGradientTest(),
                _buildGhostingTest(),
                _buildGridTest(),
              ],
            ),
            if (showInfo)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24)),
                    child: Text(_getTestName(_currentTestIndex),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            if (showInfo)
              const Positioned(
                top: 20,
                right: 20,
                child: Text("Çıkış: ESC | Değiştir: ◀ ▶",
                    style: TextStyle(color: Colors.white54)),
              ),
          ],
        ),
      ),
    );
  }

  String _getTestName(int index) {
    switch (index) {
      case 0:
        return "1. ÖLÜ PİKSEL TESTİ\n(Tıkla: Renk Değiştir)";
      case 1:
        return "2. GRADIENT (Banding) TESTİ";
      case 2:
        return "3. GHOSTING TESTİ";
      case 3:
        return "4. GRID & GEOMETRİ TESTİ";
      default:
        return "";
    }
  }

  // --- 1. ÖLÜ PİKSEL TESTİ (DÜZELTİLDİ) ---
  Widget _buildDeadPixelTest() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _deadPixelIndex = (_deadPixelIndex + 1) % _deadPixelColors.length;
        });
      },
      child: Container(
        color: _deadPixelColors[_deadPixelIndex],
        child: Center(
          child: Text(
            _deadPixelIndex == 0 ? "Renk değiştirmek için ekrana tıkla" : "",
            style: const TextStyle(color: Colors.white24),
          ),
        ),
      ),
    );
  }

  // --- 2. GRADIENT TESTİ ---
  Widget _buildGradientTest() {
    return Column(
      children: [
        Expanded(
            child: Container(
                decoration: const BoxDecoration(
                    gradient:
                        LinearGradient(colors: [Colors.black, Colors.white])))),
        Expanded(
            child: Container(
                decoration: const BoxDecoration(
                    gradient:
                        LinearGradient(colors: [Colors.black, Colors.red])))),
        Expanded(
            child: Container(
                decoration: const BoxDecoration(
                    gradient:
                        LinearGradient(colors: [Colors.black, Colors.green])))),
        Expanded(
            child: Container(
                decoration: const BoxDecoration(
                    gradient:
                        LinearGradient(colors: [Colors.black, Colors.blue])))),
      ],
    );
  }

  // --- 3. GHOSTING TESTİ ---
  Widget _buildGhostingTest() {
    return Container(
      color: Colors.grey[800],
      child: AnimatedBuilder(
        animation: _ghostController,
        builder: (context, child) {
          final width = MediaQuery.of(context).size.width;
          final xPos = _ghostController.value * (width + 100) - 50;
          return Stack(
            children: [
              Positioned(
                  left: xPos,
                  top: 200,
                  child: _buildGhostObject(Colors.cyanAccent, "960 Px/s")),
              Positioned(
                  left: (xPos * 0.7) % width,
                  top: 400,
                  child: _buildGhostObject(Colors.greenAccent, "640 Px/s")),
              Positioned(
                  left: (xPos * 0.5) % width,
                  top: 600,
                  child: _buildGhostObject(Colors.orangeAccent, "480 Px/s")),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGhostObject(Color color, String text) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
          color: color, border: Border.all(color: Colors.white, width: 2)),
      child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.rocket_launch, color: Colors.black),
        Text(text,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10))
      ])),
    );
  }

  // --- 4. GRID TESTİ ---
  Widget _buildGridTest() {
    return CustomPaint(painter: GridPainter(), child: Container());
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 50)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 50)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        100,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
