import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';

class FloatingMonitor extends StatefulWidget {
  final VoidCallback onExpand; // Ana uygulamaya dönmek için
  const FloatingMonitor({super.key, required this.onExpand});

  @override
  State<FloatingMonitor> createState() => _FloatingMonitorState();
}

class _FloatingMonitorState extends State<FloatingMonitor> {
  // Rastgele değerler yerine Dashboard'daki gibi gerçek veri akışı buraya da bağlanabilir
  // Şimdilik hızlı bir görsel akış yapalım
  double cpu = 0;
  double ram = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          // Burada ileride gerçek sistem servisinden veri çekilebilir
          cpu = (cpu + 5) % 100;
          ram = 45.5;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) =>
          windowManager.startDragging(), // Tutup sürüklenebilir
      onDoubleTap: widget.onExpand, // Çift tıkla ana ekrana dön
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
          border:
              Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat("CPU", "$cpu%", Colors.orangeAccent),
            Container(width: 1, height: 30, color: Colors.white10),
            _buildStat("RAM", "$ram%", Colors.purpleAccent),
            IconButton(
              icon: const Icon(Icons.open_in_full,
                  size: 16, color: Colors.white54),
              onPressed: widget.onExpand,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: GoogleFonts.shareTechMono(color: Colors.grey, fontSize: 10)),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
