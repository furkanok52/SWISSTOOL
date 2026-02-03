import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  bool isDesktop = false;
  bool isLoading = true;

  // Veriler
  String healthPercent = "-";
  double healthValue = 0.0;

  String designCap = "-";
  String fullCap = "-";
  String cycleCount = "-";
  String chargeLevel = "-";
  String status = "-";
  String chemistry = "-";
  String voltage = "-";
  String deviceId = "-";
  String timeRemaining = "-";

  Color healthColor = Colors.greenAccent;

  @override
  void initState() {
    super.initState();
    _getBatteryInfo();
  }

  Future<void> _getBatteryInfo() async {
    // 1. ADIM: Standart PowerShell (WMI) ile dene
    String psCmd =
        r"Get-CimInstance -ClassName Win32_Battery | ForEach-Object { 'DesignCapacity=' + $_.DesignCapacity; 'FullChargeCapacity=' + $_.FullChargeCapacity; 'CycleCount=' + $_.CycleCount; 'EstimatedChargeRemaining=' + $_.EstimatedChargeRemaining; 'BatteryStatus=' + $_.BatteryStatus; 'Chemistry=' + $_.Chemistry; 'DesignVoltage=' + $_.DesignVoltage; 'DeviceID=' + $_.DeviceID; 'EstimatedRunTime=' + $_.EstimatedRunTime }";
    String raw = await _runCommand('powershell', ['-Command', psCmd]);

    // Değerleri parse etmeye çalış
    double design = double.tryParse(_getValue(raw, "DesignCapacity")) ?? 0;
    double currentFull =
        double.tryParse(_getValue(raw, "FullChargeCapacity")) ?? 0;

    // --- KRİTİK MÜDAHALE ---
    // Eğer standart yöntem "0" döndürdüyse B PLANINA GEÇ!
    if (design == 0 || currentFull == 0) {
      await _fetchFromHiddenReport(
          raw); // Gizli raporu okuyup verileri güncelleyecek
    } else {
      _updateUI(raw, design, currentFull); // Her şey yolundaysa normal devam et
    }
  }

  // --- B PLANI: GİZLİ XML RAPORUNU OKU ---
  Future<void> _fetchFromHiddenReport(String wmiRaw) async {
    try {
      // 1. Raporu XML formatında geçici klasöre oluştur
      String tempDir = (await getTemporaryDirectory()).path;
      String reportPath = "$tempDir\\battery_report.xml";

      // powercfg komutu XML çıktısı verebilir
      await Process.run(
          'powercfg', ['/batteryreport', '/xml', '/output', reportPath],
          runInShell: true);

      // 2. Dosyayı oku
      File file = File(reportPath);
      if (await file.exists()) {
        String content = await file.readAsString();

        // 3. Regex ile verileri cımbızla çek (XML Parsing)
        double design = _extractXmlValue(content, "DesignCapacity");
        double full = _extractXmlValue(content, "FullChargeCapacity");
        String cycles = _extractXmlString(content, "CycleCount");

        // WMI'dan gelen diğer verileri koru, sadece kapasite ve döngüyü güncelle
        _updateUI(wmiRaw, design, full, overrideCycles: cycles);
      } else {
        _updateUI(wmiRaw, 0, 0); // Dosya oluşmadıysa yapacak bir şey yok
      }
    } catch (e) {
      _updateUI(wmiRaw, 0, 0);
    }
  }

  // XML'den Sayı Çeken Yardımcı
  double _extractXmlValue(String content, String tag) {
    RegExp regExp = RegExp(r'<' + tag + r'>(\d+)</' + tag + r'>');
    var match = regExp.firstMatch(content);
    if (match != null) {
      return double.tryParse(match.group(1) ?? "0") ?? 0;
    }
    return 0;
  }

  // XML'den Yazı Çeken Yardımcı
  String _extractXmlString(String content, String tag) {
    RegExp regExp = RegExp(r'<' + tag + r'>(\d+)</' + tag + r'>');
    var match = regExp.firstMatch(content);
    return match?.group(1) ?? "";
  }

  // --- UI GÜNCELLEME ---
  void _updateUI(String raw, double design, double currentFull,
      {String? overrideCycles}) {
    if (mounted) {
      setState(() {
        // Kapasiteler
        designCap = "${design.toStringAsFixed(0)} mWh";
        fullCap = "${currentFull.toStringAsFixed(0)} mWh";

        // Sağlık Hesabı
        if (design > 0) {
          double healthRatio = currentFull / design;
          if (healthRatio > 1.0) healthRatio = 1.0;

          healthValue = healthRatio;
          healthPercent = "%${(healthRatio * 100).toStringAsFixed(1)}";

          if (healthRatio < 0.60)
            healthColor = Colors.redAccent;
          else if (healthRatio < 0.85)
            healthColor = Colors.orangeAccent;
          else
            healthColor = Colors.greenAccent;
        } else {
          healthValue = 0.0;
          healthPercent = "Bilinmiyor";
          healthColor = Colors.grey;
        }

        // --- DÖNGÜ SAYISI GÜNCELLEMESİ (FIX) ---
        if (overrideCycles != null &&
            overrideCycles.isNotEmpty &&
            overrideCycles != "0") {
          cycleCount = overrideCycles; // XML'den gelen gerçek veri!
        } else {
          String cycleRaw = _getValue(raw, "CycleCount");
          // Eğer 0 geliyorsa veya boşsa "Desteklenmiyor" yaz
          cycleCount = (cycleRaw.isEmpty || cycleRaw == "0")
              ? "Desteklenmiyor"
              : cycleRaw;
        }

        // Diğerleri
        chargeLevel = "%${_getValue(raw, "EstimatedChargeRemaining")}";
        if (chargeLevel == "%") chargeLevel = "-"; // Boş gelirse

        chemistry = _getValue(raw, "Chemistry");
        if (chemistry.isEmpty) chemistry = "Li-ion";

        String voltRaw = _getValue(raw, "DesignVoltage");
        voltage = voltRaw.isNotEmpty ? "$voltRaw mV" : "-";

        deviceId = _getValue(raw, "DeviceID");

        // Durum
        String statCode = _getValue(raw, "BatteryStatus");
        status = (statCode == "2" ||
                statCode == "6" ||
                statCode == "7" ||
                statCode == "8" ||
                statCode == "9")
            ? "⚡ ŞARJDA"
            : "🔋 PİLDE";

        isLoading = false;

        // Eğer veriler hala 0 ise masaüstü uyarısı ver
        if (design == 0 && currentFull == 0 && chargeLevel == "-") {
          isDesktop = true;
        } else {
          isDesktop = false;
        }
      });
    }
  }

  Future<void> _generateDeepReport() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Rapor Hazırlanıyor..."),
        duration: Duration(seconds: 2)));
    String reportPath = "${Platform.environment['TEMP']}\\battery_report.html";
    await Process.run('powercfg', ['/batteryreport', '/output', reportPath],
        runInShell: true);
    await Process.run('cmd', ['/c', 'start', reportPath], runInShell: true);
  }

  Future<String> _runCommand(String exe, List<String> args) async {
    try {
      var result = await Process.run(exe, args, runInShell: true);
      return result.stdout.toString();
    } catch (e) {
      return "";
    }
  }

  String _getValue(String raw, String key) {
    final lines = raw.split('\n');
    for (var line in lines) {
      String cleanLine = line.trim();
      if (cleanLine.startsWith(key)) {
        if (cleanLine.contains('=')) return cleanLine.split('=')[1].trim();
      }
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text("POWER_MANAGER_PRO",
            style: GoogleFonts.shareTechMono(
                color: Colors.white, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            onPressed: () {
              setState(() => isLoading = true);
              _getBatteryInfo();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : isDesktop
              ? _buildDesktopView()
              : _buildProfessionalView(),
    );
  }

  Widget _buildProfessionalView() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SOL PANEL
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: healthColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 160,
                          width: 160,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: healthValue,
                                strokeWidth: 15,
                                color: healthColor,
                                backgroundColor: Colors.white10,
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(healthPercent.replaceAll('%', ''),
                                        style: GoogleFonts.audiowide(
                                            fontSize: 32, color: Colors.white)),
                                    const Text("%",
                                        style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 14)),
                                    Text("SAĞLIK",
                                        style: TextStyle(
                                            color: healthColor, fontSize: 10)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(chargeLevel,
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(status,
                            style: const TextStyle(
                                color: Colors.grey, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // SAĞ PANEL
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("GERÇEK VERİLER (XML)",
                            style: GoogleFonts.shareTechMono(
                                color: Colors.cyanAccent, fontSize: 16)),
                        const Divider(color: Colors.cyanAccent),
                        Expanded(
                          child: ListView(
                            children: [
                              _buildTechRow("Fabrika Kapasitesi", designCap),
                              _buildTechRow("Mevcut Kapasite", fullCap),
                              _buildTechRow("Döngü (Cycle)", cycleCount,
                                  highlight: true),
                              _buildTechRow("Voltaj", voltage),
                              _buildTechRow("Kimya", chemistry),
                              _buildTechRow("Seri No / ID", deviceId),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _generateDeepReport,
                            icon: const Icon(Icons.description,
                                color: Colors.black),
                            label: const Text("ORİJİNAL RAPORU GÖSTER"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: GoogleFonts.robotoMono(
                  color: highlight ? Colors.yellowAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDesktopView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.desktop_windows, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 20),
          const Text("PİL VERİSİNE ERİŞİLEMEDİ",
              style: TextStyle(color: Colors.grey, fontSize: 20)),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: () {
                setState(() => isLoading = true);
                _getBatteryInfo();
              },
              child: const Text("Tekrar Dene")),
        ],
      ),
    );
  }
}
