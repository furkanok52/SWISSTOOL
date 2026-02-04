import 'dart:async';
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
import 'security/security_page.dart';
import 'process/process_page.dart';
import 'settings/settings_page.dart';
import 'fileops/large_file_finder.dart';
import 'fileops/bulk_renamer.dart';
import 'automation/auto_shutdown.dart';
import 'automation/game_mode.dart';
import 'floating_monitor.dart'; // Bu dosyanın hazır olduğundan emin ol!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1150, 750),
    minimumSize: Size(220, 70), // Mini mod için minimum boyutu iyice düşürdük
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'SwissTool Pro',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setSize(const Size(1150, 750));
    await windowManager.center();
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
        textTheme:
            GoogleFonts.jetBrainsMonoTextTheme(Theme.of(context).textTheme)
                .apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white,
        ),
      ),
      home: const AppBootstrapper(),
    );
  }
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => isReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.cyanAccent),
              SizedBox(height: 20),
              Text("Sistem Başlatılıyor...",
                  style: TextStyle(
                      color: Colors.grey, fontSize: 12, letterSpacing: 2)),
            ],
          ),
        ),
      );
    }
    return const MainLayout();
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with WindowListener, SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool isFloating = false; // Floating mod kontrolü

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<Widget> _pages = [
    const DashboardHome(),
    const NetworkPage(),
    const SystemDoctorPage(),
    const ProcessPage(),
    const LargeFileFinderPage(),
    const BulkRenamerPage(),
    const AutoShutdownPage(),
    const GameModePage(),
  ];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initAnimations();
  }

  void _initAnimations() {
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutExpo));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  // --- MOD DEĞİŞTİRİCİ FONKSİYON ---
  void _toggleFloating() async {
    if (!isFloating) {
      // MİNİ MODA GEÇİŞ
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setHasShadow(false);
      await windowManager.setSize(const Size(220, 70));
      await windowManager.setResizable(false);
    } else {
      // NORMAL MODA GEÇİŞ
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setSize(const Size(1150, 750));
      await windowManager.setResizable(true);
      await windowManager.setHasShadow(true);
      await windowManager.center();
    }
    setState(() => isFloating = !isFloating);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _animController.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    if (size.width <= 10 || size.height <= 10)
      return const Scaffold(backgroundColor: Color(0xFF0F0F0F));

    // Eğer mini moddaysak sadece takip kutusunu göster
    if (isFloating) {
      return FloatingMonitor(onExpand: _toggleFloating);
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5)
              ],
            ),
            margin: const EdgeInsets.all(5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  _buildTitleBar(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 240,
                          decoration: BoxDecoration(
                            color: const Color(0xFF161616),
                            border: Border(
                                right: BorderSide(
                                    color: Colors.white.withOpacity(0.05))),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              const Icon(FontAwesomeIcons.toolbox,
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
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    children: [
                                      _buildMenuItem(
                                          0,
                                          "Dashboard",
                                          FontAwesomeIcons.chartPie,
                                          Colors.purpleAccent),
                                      _buildDivider(),
                                      _buildMenuItem(
                                          1,
                                          "Network Manager",
                                          FontAwesomeIcons.networkWired,
                                          Colors.blueAccent),
                                      _buildMenuItem(
                                          2,
                                          "System Doctor",
                                          FontAwesomeIcons.heartPulse,
                                          Colors.redAccent),
                                      _buildMenuItem(
                                          3,
                                          "Process Killer",
                                          FontAwesomeIcons.skull,
                                          Colors.pinkAccent),
                                      _buildMenuItem(
                                          4,
                                          "Large File Finder",
                                          FontAwesomeIcons.magnifyingGlassChart,
                                          Colors.tealAccent),
                                      _buildMenuItem(
                                          5,
                                          "Bulk Renamer",
                                          FontAwesomeIcons.tags,
                                          Colors.indigoAccent),
                                      _buildDivider(),
                                      _buildMenuItem(
                                          6,
                                          "Auto Shutdown",
                                          FontAwesomeIcons.powerOff,
                                          Colors.redAccent),
                                      _buildMenuItem(
                                          7,
                                          "Game Booster",
                                          FontAwesomeIcons.gamepad,
                                          Colors.greenAccent),
                                      _buildDivider(),
                                      // MINI MODE BUTONU
                                      _buildSpecialButton(
                                          "Mini Mode",
                                          Icons.tab_unselected,
                                          Colors.cyanAccent,
                                          _toggleFloating),
                                      _buildSpecialButton(
                                          "Hardware Info",
                                          FontAwesomeIcons.microchip,
                                          Colors.orangeAccent,
                                          () => showHardwareMenu(context)),
                                      _buildSpecialButton(
                                          "Dev Tools",
                                          FontAwesomeIcons.code,
                                          Colors.greenAccent, () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const DevToolsPage()));
                                      }),
                                      _buildSpecialButton(
                                          "Security Center",
                                          FontAwesomeIcons.shieldHalved,
                                          Colors.amber, () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const SecurityPage()));
                                      }),
                                      _buildDivider(),
                                      _buildSpecialButton("Settings & About",
                                          Icons.settings, Colors.white, () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const SettingsPage()));
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text("v2.5.0 Phantom",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 10)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: const Color(0xFF0F0F0F),
                            child: _pages.length > _selectedIndex
                                ? _pages[_selectedIndex]
                                : const Center(
                                    child: Text("Sayfa Yapım Aşamasında")),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
              if (await windowManager.isMaximized())
                windowManager.unmaximize();
              else
                windowManager.maximize();
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
        child: Icon(icon,
            size: 16, color: isClose ? Colors.redAccent : Colors.grey));
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
        child: Divider(color: Colors.white.withOpacity(0.05), height: 1));
  }
}

// --- DÜZELTİLMİŞ DASHBOARD ---
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});
  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  String cpuText = "%0";
  String ramText = "-- / -- GB";
  String diskText = "-- / -- GB";
  String gpuName = "Analiz Ediliyor...";
  String osName = "Sistem Taranıyor...";
  String netStatus = "--";
  Color netColor = Colors.grey;

  double cpuProgress = 0.0;
  double ramProgress = 0.0;
  double diskProgress = 0.0;

  bool isLoading = true;
  Timer? _dashboardTimer;

  @override
  void initState() {
    super.initState();
    _getSystemStats();
    _dashboardTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Mini moddayken gereksiz PowerShell çalıştırmayı durdur!
      if (MediaQuery.of(context).size.width > 300) {
        _getSystemStats();
      }
    });
  }

  @override
  void dispose() {
    _dashboardTimer?.cancel();
    super.dispose();
  }

  Future<void> _getSystemStats() async {
    try {
      String cpuRaw = await _runPS(
          r"Get-WmiObject Win32_Processor | Select-Object -ExpandProperty LoadPercentage");
      String ramRaw = await _runPS(
          r"Get-CimInstance Win32_OperatingSystem | Select-Object FreePhysicalMemory, TotalVisibleMemorySize | Format-List");
      String diskRaw = await _runPS(
          r"Get-CimInstance Win32_LogicalDisk -Filter " +
              '"DeviceID=\'C:\'"' +
              r" | Select-Object Size, FreeSpace | Format-List");

      if (gpuName.contains("Analiz")) {
        String gpuRaw = await _runPS(
            r"Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name");
        if (gpuRaw.isNotEmpty) gpuName = gpuRaw.trim();
      }

      if (osName.contains("Taranıyor")) {
        String osRaw = await _runPS(
            r"Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption");
        if (osRaw.isNotEmpty) osName = osRaw.trim();
      }

      bool isOnline = false;
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty)
          isOnline = true;
      } catch (_) {
        isOnline = false;
      }

      if (mounted) {
        setState(() {
          int cpuVal = int.tryParse(cpuRaw.trim()) ?? 0;
          cpuText = "%$cpuVal";
          cpuProgress = (cpuVal / 100).clamp(0.0, 1.0);

          double totalRamKB =
              double.tryParse(_getValue(ramRaw, "TotalVisibleMemorySize")) ?? 1;
          double freeRamKB =
              double.tryParse(_getValue(ramRaw, "FreePhysicalMemory")) ?? 0;
          double usedRamGB = (totalRamKB - freeRamKB) / (1024 * 1024);
          double totalRamGB = totalRamKB / (1024 * 1024);
          ramText =
              "${usedRamGB.toStringAsFixed(1)} / ${totalRamGB.toStringAsFixed(1)} GB";
          ramProgress = (usedRamGB / totalRamGB).clamp(0.0, 1.0);

          double totalDiskB = double.tryParse(_getValue(diskRaw, "Size")) ?? 1;
          double freeDiskB =
              double.tryParse(_getValue(diskRaw, "FreeSpace")) ?? 0;
          double totalDiskGB = totalDiskB / (1024 * 1024 * 1024);
          double usedDiskGB = totalDiskGB - (freeDiskB / (1024 * 1024 * 1024));
          diskText =
              "${usedDiskGB.toStringAsFixed(0)} / ${totalDiskGB.toStringAsFixed(0)} GB";
          diskProgress = (usedDiskGB / totalDiskGB).clamp(0.0, 1.0);

          netStatus = isOnline ? "ONLINE" : "OFFLINE";
          netColor = isOnline ? Colors.greenAccent : Colors.redAccent;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Veri hatası: $e");
    }
  }

  Future<String> _runPS(String cmd) async {
    try {
      var result =
          await Process.run('powershell', ['-Command', cmd], runInShell: true);
      return result.stdout.toString();
    } catch (e) {
      return "";
    }
  }

  String _getValue(String raw, String key) {
    if (raw.isEmpty) return "0";
    final lines = raw.split('\n');
    for (var line in lines) {
      var parts = line.split(':');
      if (line.trim().startsWith(key) && parts.length > 1)
        return parts[1].trim();
    }
    return "0";
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 100 || constraints.maxHeight < 100)
        return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent));
      if (isLoading)
        return const Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: Colors.cyanAccent),
          SizedBox(height: 20),
          Text("Sistem Taranıyor...", style: TextStyle(color: Colors.grey))
        ]));
      return Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SYSTEM DASHBOARD",
                        style: GoogleFonts.audiowide(
                            fontSize: 28, color: Colors.white)),
                    Row(children: [
                      const Icon(Icons.circle,
                          color: Colors.greenAccent, size: 8),
                      const SizedBox(width: 5),
                      Text("Monitoring Active • $osName",
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12))
                    ]),
                  ],
                ),
                Icon(Icons.monitor_heart,
                    color: Colors.cyanAccent.withOpacity(0.5), size: 40),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildStatCard("CPU LOAD", cpuText, "İşlemci Yükü",
                      Colors.blueAccent, FontAwesomeIcons.microchip,
                      progress: cpuProgress),
                  _buildStatCard("MEMORY (RAM)", ramText, "Kullanılan / Toplam",
                      Colors.purpleAccent, FontAwesomeIcons.memory,
                      progress: ramProgress),
                  _buildStatCard("DISK (C:)", diskText, "Yerel Disk Doluluk",
                      Colors.orangeAccent, FontAwesomeIcons.hardDrive,
                      progress: diskProgress),
                  _buildInfoCard("HARDWARE & NET", gpuName, netStatus, netColor,
                      FontAwesomeIcons.gamepad),
                ],
              ),
            )
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
      String title, String value, String sub, Color color, IconData icon,
      {double progress = 0.0}) {
    if (progress.isNaN || progress.isInfinite) progress = 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title,
                style: GoogleFonts.shareTechMono(
                    color: Colors.grey, fontSize: 14)),
            Icon(icon, color: color.withOpacity(0.6), size: 20)
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 5),
            Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 11))
          ]),
          ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.1),
                  color: color,
                  minHeight: 6))
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String gpu, String net, Color netCol, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title,
                style: GoogleFonts.shareTechMono(
                    color: Colors.grey, fontSize: 14)),
            Icon(icon, color: Colors.cyanAccent.withOpacity(0.6), size: 20)
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("GPU MODEL:",
                style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            Text(gpu,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Text("NETWORK STATUS:",
                style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            Row(children: [
              Icon(Icons.wifi, color: netCol, size: 16),
              const SizedBox(width: 5),
              Text(net,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: netCol))
            ])
          ]),
          Container(
              height: 2, width: 50, color: Colors.cyanAccent.withOpacity(0.5))
        ],
      ),
    );
  }
}
