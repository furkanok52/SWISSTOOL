import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Linkleri açmak için (pubspec.yaml'a eklemen gerekebilir veya direkt string gösteririz)

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isAlwaysOnTop = false;

  @override
  void initState() {
    super.initState();
    _checkWindowStatus();
  }

  Future<void> _checkWindowStatus() async {
    bool onTop = await windowManager.isAlwaysOnTop();
    if (mounted) setState(() => _isAlwaysOnTop = onTop);
  }

  Future<void> _toggleAlwaysOnTop(bool value) async {
    await windowManager.setAlwaysOnTop(value);
    setState(() => _isAlwaysOnTop = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text("SETTINGS & ABOUT",
            style: GoogleFonts.shareTechMono(
                color: Colors.white, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. UYGULAMA AYARLARI
            const Text("PENCERE AYARLARI",
                style: TextStyle(
                    color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.cyanAccent),
            SwitchListTile(
              title: const Text("Pencereyi Her Zaman Üstte Tut",
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text("Diğer pencerelerin önüne geçer.",
                  style: TextStyle(color: Colors.grey)),
              value: _isAlwaysOnTop,
              activeColor: Colors.cyanAccent,
              contentPadding: EdgeInsets.zero,
              onChanged: _toggleAlwaysOnTop,
            ),

            const SizedBox(height: 40),

            // 2. GELİŞTİRİCİ KARTI (BRANDING)
            const Text("GELİŞTİRİCİ",
                style: TextStyle(
                    color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.purpleAccent),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.purpleAccent,
                    child: Icon(FontAwesomeIcons.userAstronaut,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Furkan OK",
                          style: GoogleFonts.audiowide(
                              fontSize: 22, color: Colors.white)),
                      const Text("Full Stack Developer & Engineer",
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(FontAwesomeIcons.github,
                              size: 14, color: Colors.white70),
                          SizedBox(width: 8),
                          Text("github.com/furkanok52",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),

            const Spacer(),

            // 3. VERSİYON BİLGİSİ
            Center(
              child: Column(
                children: [
                  Icon(FontAwesomeIcons.toolbox,
                      color: Colors.white10, size: 50),
                  const SizedBox(height: 10),
                  Text("SwissTool Ultimate",
                      style: GoogleFonts.audiowide(
                          color: Colors.white24, fontSize: 16)),
                  const Text("Build: 2024.10.25_RC1",
                      style: TextStyle(color: Colors.white12, fontSize: 10)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
