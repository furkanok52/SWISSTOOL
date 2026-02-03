import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- SAYFA IMPORTLARI ---
import 'hardware/hardware_menu.dart';
import 'network_page.dart';
import 'doctor/system_doctor_page.dart';
import 'devtools/dev_tools_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(950, 650),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    title: 'SwissTool',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const SwissToolApp());
}

class SwissToolApp extends StatelessWidget {
  const SwissToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        primaryColor: Colors.cyanAccent,
        // Fontları modern yapalım
        textTheme:
            GoogleFonts.jetBrainsMonoTextTheme(Theme.of(context).textTheme)
                .apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // İşletim Sistemini Bul
    String osName = Platform.operatingSystem.toUpperCase();
    IconData osIcon =
        Platform.isWindows ? FontAwesomeIcons.windows : FontAwesomeIcons.linux;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.toolbox, color: Colors.cyanAccent),
            const SizedBox(width: 10),
            // Başlık Fontu Efsane Olsun
            Text("SWISSTOOL v1.0",
                style: GoogleFonts.audiowide(
                    letterSpacing: 2, color: Colors.white)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- 1. SYSTEM DETECTED KARTI (Windows Logolu Olan) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.cyan.shade900.withOpacity(0.6),
                    Colors.blue.shade900.withOpacity(0.6)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.cyan.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(osIcon, color: Colors.cyanAccent, size: 30),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SYSTEM DETECTED: $osName",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16)),
                      Text("Ready for operations...",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. ARAÇLAR GRID (Alt Taraf) ---
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  // 1. NETWORK MANAGER
                  _buildToolCard(
                    context,
                    title: "Network Manager",
                    desc: "Speedtest, IP Info, Ping",
                    icon: FontAwesomeIcons.networkWired,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NetworkPage()));
                    },
                  ),

                  // 2. SYSTEM DOCTOR
                  _buildToolCard(
                    context,
                    title: "System Doctor",
                    desc: "Clean Temp, DNS Flush",
                    icon: FontAwesomeIcons.heartPulse,
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SystemDoctorPage()));
                    },
                  ),

                  // 3. HARDWARE TEST (MENÜYÜ AÇAR)
                  _buildToolCard(
                    context,
                    title: "Hardware Test",
                    desc: "Monitor, Keyboard, CPU-Z",
                    icon: FontAwesomeIcons.microchip,
                    color: Colors.orangeAccent,
                    onTap: () {
                      showHardwareMenu(context);
                    },
                  ),

                  // 4. DEV TOOLS (ARTIK AKTİF!)
                  _buildToolCard(
                    context,
                    title: "Dev Tools",
                    desc: "JSON, Base64, URL Tools", // Açıklamayı güncelle
                    icon: FontAwesomeIcons.code,
                    color: Colors.greenAccent,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DevToolsPage()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context,
      {required String title,
      required String desc,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors
          .transparent, // Arka planı transparent yapıp container'a gradient verelim
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF252525),
                  const Color(0xFF1E1E1E),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5)),
              ]),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
