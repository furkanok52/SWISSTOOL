import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AutoShutdownPage extends StatefulWidget {
  const AutoShutdownPage({super.key});

  @override
  State<AutoShutdownPage> createState() => _AutoShutdownPageState();
}

class _AutoShutdownPageState extends State<AutoShutdownPage> {
  final TextEditingController _minutesController = TextEditingController();
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isScheduled = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _minutesController.dispose();
    super.dispose();
  }

  // Windows Komutu: Kapatmayı Başlat
  Future<void> _scheduleShutdown() async {
    if (_minutesController.text.isEmpty) return;
    int? minutes = int.tryParse(_minutesController.text);
    if (minutes == null || minutes <= 0) return;

    int seconds = minutes * 60;

    try {
      // shutdown /s (kapat) /t (süre) <saniye>
      // Windows'a emri veriyoruz:
      await Process.run('shutdown', ['/s', '/t', '$seconds'], runInShell: true);

      setState(() {
        _isScheduled = true;
        _remainingSeconds = seconds;
      });

      // UI Geri Sayımı (Sadece görsel için, işlem arkada Windows'ta işliyor)
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
          // Süre bitti, Windows kapanacak.
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Bilgisayar $minutes dakika sonra kapanacak."),
              backgroundColor: Colors.orangeAccent),
        );
      }
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  // Windows Komutu: İptal Et
  Future<void> _cancelShutdown() async {
    try {
      // shutdown /a (abort - iptal)
      await Process.run('shutdown', ['/a'], runInShell: true);

      _countdownTimer?.cancel();
      setState(() {
        _isScheduled = false;
        _remainingSeconds = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Otomatik kapatma iptal edildi."),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  // Süreyi HH:MM:SS formatına çevir
  String _formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("AUTO SHUTDOWN",
              style: GoogleFonts.audiowide(fontSize: 24, color: Colors.white)),
          const Text("Zamanlayıcıyı kur, gerisini sisteme bırak.",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 30),

          // ANA KUTU
          Center(
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _isScheduled
                          ? Colors.orangeAccent.withOpacity(0.5)
                          : Colors.white10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5)
                  ]),
              child: Column(
                children: [
                  Icon(
                      _isScheduled
                          ? FontAwesomeIcons.hourglassHalf
                          : FontAwesomeIcons.powerOff,
                      size: 60,
                      color: _isScheduled ? Colors.orangeAccent : Colors.grey),
                  const SizedBox(height: 20),
                  if (_isScheduled) ...[
                    // --- MOD: GERİ SAYIM ---
                    const Text("KAPANMAYA KALAN SÜRE",
                        style: TextStyle(color: Colors.grey, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    Text(
                      _formatDuration(_remainingSeconds),
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _cancelShutdown,
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text("İPTAL ET",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                    )
                  ] else ...[
                    // --- MOD: AYARLAMA ---
                    const Text("KAÇ DAKİKA SONRA KAPANSIN?",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "60",
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.1)),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Hızlı Seçim Butonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _quickButton(15),
                        const SizedBox(width: 10),
                        _quickButton(30),
                        const SizedBox(width: 10),
                        _quickButton(60),
                        const SizedBox(width: 10),
                        _quickButton(120),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _scheduleShutdown,
                        icon: const Icon(Icons.timer, color: Colors.black),
                        label: const Text("SAYACI BAŞLAT",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _quickButton(int min) {
    return InkWell(
      onTap: () => _minutesController.text = min.toString(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(8)),
        child: Text("$min dk",
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ),
    );
  }
}
