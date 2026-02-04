import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GameModePage extends StatefulWidget {
  const GameModePage({super.key});

  @override
  State<GameModePage> createState() => _GameModePageState();
}

class _GameModePageState extends State<GameModePage>
    with TickerProviderStateMixin {
  final List<String> targetProcesses = [
    'chrome',
    'msedge',
    'discord',
    'spotify',
    'teams',
    'firefox',
    'opera',
    'slack',
    'steamwebhelper'
  ];

  final List<String> targetServices = [
    'WSearch',
    'SysMain',
    'Spooler',
    'DiagTrack',
    'MapsBroker',
    'TabletInputService'
  ];

  List<String> logs = [];
  bool isBoosting = false;
  bool isBoosted = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _addLog("Phantom Engine Hazır. Emir Bekleniyor...");
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    if (mounted) {
      setState(() {
        logs.insert(0,
            "[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] $message");
      });
    }
  }

  Future<void> _phantomRegistry(bool enable) async {
    try {
      if (enable) {
        await Process.run(
            'reg',
            [
              'add',
              r"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games",
              '/v',
              'Priority',
              '/t',
              'REG_DWORD',
              '/d',
              '6',
              '/f'
            ],
            runInShell: true);
        await Process.run(
            'reg',
            [
              'add',
              r"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games",
              '/v',
              'Scheduling Category',
              '/t',
              'REG_SZ',
              '/d',
              'High',
              '/f'
            ],
            runInShell: true);
        _addLog("🔥 GPU Öncelik Modu: AKTİF");
      } else {
        await Process.run(
            'reg',
            [
              'add',
              r"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games",
              '/v',
              'Priority',
              '/t',
              'REG_DWORD',
              '/d',
              '2',
              '/f'
            ],
            runInShell: true);
        _addLog("🔄 GPU Öncelik Modu: Standart");
      }
    } catch (_) {}
  }

  Future<void> _deepClean() async {
    try {
      await Process.run(
          'powershell',
          [
            '-Command',
            "Remove-Item -Path \$env:TEMP\\* -Recurse -Force -ErrorAction SilentlyContinue"
          ],
          runInShell: true);
      _addLog("🧹 Deep Clean: Önbellek Boşaltıldı.");
    } catch (_) {}
  }

  Future<void> _startPhantomBoost() async {
    setState(() {
      isBoosting = true;
      logs.clear();
    });
    _addLog("🚀 PHANTOM ENGINE BAŞLATILIYOR...");
    await _killApps();
    await _manageServices(true);
    await _phantomRegistry(true);
    await _deepClean();
    await _flushDNS();
    setState(() {
      isBoosting = false;
      isBoosted = true;
    });
    _addLog("✅ SİSTEM OPTİMİZE EDİLDİ!");
  }

  Future<void> _killApps() async {
    for (var target in targetProcesses) {
      await Process.run('taskkill', ['/F', '/IM', '$target.exe'],
          runInShell: true);
    }
    _addLog("💀 Bloatware temizliği tamam.");
  }

  Future<void> _manageServices(bool stop) async {
    for (var s in targetServices) {
      await Process.run('net', [stop ? 'stop' : 'start', s, '/y'],
          runInShell: true);
    }
  }

  Future<void> _flushDNS() async {
    await Process.run('ipconfig', ['/flushdns'], runInShell: true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            _buildInfoPanel(),

            const SizedBox(height: 15),

            // --- BİLGİLENDİRME NOTU (Overflow Fix) ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Mini Monitörü oyunda görebilmek için görüntü modunu 'Penceresiz Tam Ekran' yapmalısınız.",
                      style: GoogleFonts.shareTechMono(
                          color: Colors.amber[200], fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // PHANTOM CORE (BUTON)
            Center(
              child: ScaleTransition(
                scale: isBoosted
                    ? _pulseAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: InkWell(
                  onTap: isBoosting
                      ? null
                      : (isBoosted ? _restoreSystem : _startPhantomBoost),
                  borderRadius: BorderRadius.circular(150),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: isBoosted
                                  ? Colors.orange.withOpacity(0.5)
                                  : Colors.cyan.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5)
                        ],
                        gradient: LinearGradient(
                          colors: isBoosted
                              ? [Colors.deepOrange, Colors.red]
                              : [Colors.cyan, Colors.blueAccent],
                          begin: Alignment.topLeft,
                        )),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isBoosted ? Icons.bolt : Icons.rocket_launch,
                            size: 50, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          isBoosting ? "..." : (isBoosted ? "STOP" : "BOOST"),
                          style: GoogleFonts.audiowide(
                              color: Colors.white, fontSize: 18),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            _buildLogTerminal(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isBoosted ? Colors.orange : Colors.cyan.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.shieldHalved,
                  size: 16, color: isBoosted ? Colors.orange : Colors.cyan),
              const SizedBox(width: 10),
              Text("PHANTOM ENGINE STATUS",
                  style: GoogleFonts.shareTechMono(
                      fontSize: 14, color: Colors.white)),
              const Spacer(),
              Text(isBoosted ? "UNLOCKED" : "LOCKED",
                  style: TextStyle(
                      color: isBoosted ? Colors.orange : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),
          _infoDetail("Priority:", "High GPU Priority Mode"),
          _infoDetail("Network:", "Lower Latency & DNS Flush"),
          _infoDetail("System:", "Telemetry & Services Paused"),
        ],
      ),
    );
  }

  Widget _infoDetail(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(width: 5),
          Text(desc,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLogTerminal() {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) => Text(logs[index],
            style: GoogleFonts.shareTechMono(
                color: Colors.greenAccent, fontSize: 11)),
      ),
    );
  }

  Future<void> _restoreSystem() async {
    setState(() => isBoosting = true);
    await _phantomRegistry(false);
    await _manageServices(false);
    _addLog("🔄 Sistem Normale Döndü.");
    setState(() {
      isBoosting = false;
      isBoosted = false;
    });
  }
}
