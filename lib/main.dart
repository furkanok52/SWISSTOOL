import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- SAYFA IMPORTLARI ---
import 'network_page.dart';
import 'doctor/system_doctor_page.dart';
import 'hardware/hardware_menu.dart';
import 'devtools/dev_tools_page.dart';
// import 'security/security_page.dart'; // Güvenlik sayfasını oluşturunca açarsın

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 750),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'SwissTool Pro',
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
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        cardColor: const Color(0xFF1E1E1E),
        primaryColor: Colors.cyanAccent,
        // DÜZELTME BURADA: jetBrainsMonoTextTheme (B harfi büyük)
        textTheme:
            GoogleFonts.jetBrainsMonoTextTheme(Theme.of(context).textTheme)
                .apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white,
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // SAYFA LİSTESİ
  final List<Widget> _pages = [
    const DashboardHome(), // 0: Ana Özet
    const NetworkPage(), // 1: Network
    const SystemDoctorPage(), // 2: Doctor
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 1. PENCERE ÇUBUĞU
          _buildTitleBar(),

          // 2. ANA GÖVDE
          Expanded(
            child: Row(
              children: [
                // --- SOL MENÜ (SIDEBAR) ---
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    border: Border(
                        right:
                            BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Icon(FontAwesomeIcons.toolbox,
                          size: 40, color: Colors.cyanAccent),
                      const SizedBox(height: 10),
                      Text("SWISSTOOL",
                          style: GoogleFonts.audiowide(
                              fontSize: 20, color: Colors.white)),
                      Text("ULTIMATE EDITION",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.cyanAccent,
                              letterSpacing: 2)),
                      const SizedBox(height: 30),

                      // MENÜLER
                      _buildMenuItem(0, "Dashboard", FontAwesomeIcons.chartPie,
                          Colors.purpleAccent),
                      _buildDivider(),
                      _buildMenuItem(1, "Network Manager",
                          FontAwesomeIcons.networkWired, Colors.blueAccent),
                      _buildMenuItem(2, "System Doctor",
                          FontAwesomeIcons.heartPulse, Colors.redAccent),

                      // Hardware (Özel)
                      _buildSpecialButton("Hardware Info",
                          FontAwesomeIcons.microchip, Colors.orangeAccent, () {
                        showHardwareMenu(context);
                      }),

                      _buildDivider(),

                      // Dev Tools (Özel)
                      _buildSpecialButton("Dev Tools", FontAwesomeIcons.code,
                          Colors.greenAccent, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DevToolsPage()));
                      }),

                      // Security (Hazırlık)
                      _buildSpecialButton("Security Center",
                          FontAwesomeIcons.shieldHalved, Colors.amber, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Güvenlik Modülü Yükleniyor...")));
                      }),

                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("v2.0.1 Stable",
                            style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ),
                    ],
                  ),
                ),

                // --- SAĞ İÇERİK ---
                Expanded(
                  child: Container(
                    color: const Color(0xFF0F0F0F),
                    child: _pages.length > _selectedIndex
                        ? _pages[_selectedIndex]
                        : const Center(child: Text("Sayfa Yapım Aşamasında")),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onPanStart: (details) => windowManager.startDragging(),
      child: Container(
        height: 35,
        color: const Color(0xFF161616),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Text("SwissTool // System Operations",
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const Spacer(),
            _windowIcon(Icons.remove, () => windowManager.minimize()),
            const SizedBox(width: 10),
            _windowIcon(Icons.crop_square, () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            }),
            const SizedBox(width: 10),
            _windowIcon(Icons.close, () => windowManager.close(),
                isClose: true),
          ],
        ),
      ),
    );
  }

  Widget _windowIcon(IconData icon, VoidCallback onTap,
      {bool isClose = false}) {
    return InkWell(
      onTap: onTap,
      child:
          Icon(icon, size: 16, color: isClose ? Colors.redAccent : Colors.grey),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon, Color color) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
      title: Text(title,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14)),
      selected: isSelected,
      tileColor: isSelected ? color.withOpacity(0.1) : null,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildSpecialButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey, size: 20),
      title:
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 10, color: color.withOpacity(0.5)),
      hoverColor: color.withOpacity(0.05),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
    );
  }
}

// --- DASHBOARD ---
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("HOŞ GELDİN, KAPTAN.",
              style: GoogleFonts.audiowide(fontSize: 32, color: Colors.white)),
          Text("Tüm sistemler aktif ve hazır.",
              style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _statCard("CPU Kullanımı", "%12", Colors.blueAccent),
                _statCard("RAM Durumu", "8.4 GB", Colors.purpleAccent),
                _statCard("Network", "Online", Colors.greenAccent),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
