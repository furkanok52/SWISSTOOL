import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemInfoPage extends StatefulWidget {
  const SystemInfoPage({super.key});

  @override
  State<SystemInfoPage> createState() => _SystemInfoPageState();
}

class _SystemInfoPageState extends State<SystemInfoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  // --- VERİLER ---
  // Özet
  String pcName = "-";
  String osVersion = "-";
  String upTime = "-"; // Bilgisayar ne kadar süredir açık

  // CPU Detay
  String cpuName = "-";
  String cpuCores = "-";
  String cpuSocket = "-";
  String cpuL3Cache = "-";
  String cpuVoltage = "-";
  String cpuArch = "x64";

  // GPU Detay
  String gpuName = "-";
  String gpuVram = "-"; // Video RAM
  String gpuDriverVer = "-";
  String gpuDriverDate = "-";
  String gpuRefresh = "-";

  // RAM Detay
  String ramTotal = "-";
  String ramSpeed = "-";
  String ramManufacturer = "-";
  String ramSerial = "-";
  String ramPartNumber = "-";

  // Disk & Network
  String diskModel = "-";
  String diskSize = "-";
  String diskSerial = "-";
  String macAddress = "-";
  String localIp = "-";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getSystemInfo();
  }

  Future<void> _getSystemInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final windowsInfo = await deviceInfo.windowsInfo;

    // --- WMIC SORGULARI (Derinlemesine) ---
    // CPU: Cache, Socket, Name
    String cpuRaw = await _runCommand(
        'wmic cpu get Name, NumberOfCores, L3CacheSize, SocketDesignation, CurrentVoltage /format:list');

    // GPU: VRAM, DriverDate
    String gpuRaw = await _runCommand(
        'wmic path win32_VideoController get Name, DriverVersion, AdapterRAM, DriverDate, VideoModeDescription /format:list');

    // RAM: PartNumber, SerialNumber
    String ramRaw = await _runCommand(
        'wmic memorychip get Speed, Manufacturer, Capacity, PartNumber, SerialNumber /format:list');

    // Disk: SerialNumber
    String diskRaw = await _runCommand(
        'wmic diskdrive get Model, Size, SerialNumber /format:list');

    // Network: MAC (Basit yöntem)
    String netRaw = await _runCommand('getmac');

    // IP Adresi (Hack: ipconfig içinden bulmaca)
    String ipRaw = await _runCommand('ipconfig');

    if (mounted) {
      setState(() {
        pcName = windowsInfo.computerName;
        osVersion =
            "${windowsInfo.productName} (Build ${windowsInfo.buildNumber})";

        // CPU Parse
        cpuName = _getValue(cpuRaw, "Name");
        cpuCores = "${_getValue(cpuRaw, "NumberOfCores")} Çekirdek";
        cpuSocket = _getValue(cpuRaw, "SocketDesignation");
        double l3 = double.tryParse(_getValue(cpuRaw, "L3CacheSize")) ?? 0;
        cpuL3Cache =
            l3 > 0 ? "${(l3 / 1024).toStringAsFixed(1)} MB" : "Bilinmiyor";
        cpuVoltage = "${_getValue(cpuRaw, "CurrentVoltage")} V";

        // GPU Parse
        gpuName = _getValue(gpuRaw, "Name");
        gpuDriverVer = _getValue(gpuRaw, "DriverVersion");
        gpuRefresh = _getValue(gpuRaw, "VideoModeDescription")
            .split(' ')
            .last; // Hz'i alır

        // VRAM Hesapla (Byte -> GB)
        double vramBytes =
            double.tryParse(_getValue(gpuRaw, "AdapterRAM")) ?? 0;
        if (vramBytes > 0) {
          gpuVram =
              "${(vramBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
        } else {
          gpuVram = "Paylaşımlı (Integrated)";
        }

        // Sürücü Tarihi (20231025... formatında gelir)
        String rawDate = _getValue(gpuRaw, "DriverDate");
        if (rawDate.length >= 8) {
          gpuDriverDate =
              "${rawDate.substring(6, 8)}.${rawDate.substring(4, 6)}.${rawDate.substring(0, 4)}";
        }

        // RAM Parse
        final ramSizes = _getAllValues(ramRaw, "Capacity");
        double totalRamGb = 0;
        for (var size in ramSizes) {
          totalRamGb += (double.tryParse(size) ?? 0) / (1024 * 1024 * 1024);
        }
        ramTotal = "${totalRamGb.toStringAsFixed(1)} GB";
        ramSpeed = "${_getValue(ramRaw, "Speed")} MHz";
        ramManufacturer = _getValue(ramRaw, "Manufacturer");
        ramPartNumber = _getValue(ramRaw, "PartNumber");
        ramSerial = _getValue(ramRaw, "SerialNumber");

        // Disk Parse
        diskModel = _getValue(diskRaw, "Model");
        diskSerial = _getValue(diskRaw, "SerialNumber");
        double diskBytes = double.tryParse(_getValue(diskRaw, "Size")) ?? 0;
        diskSize =
            "${(diskBytes / (1024 * 1024 * 1024)).toStringAsFixed(0)} GB";

        // Network Parse (Basit)
        if (netRaw.length > 15) {
          // getmac çıktısının ilk satırı genelde MAC adresidir
          RegExp macReg = RegExp(r"([0-9A-F]{2}-){5}[0-9A-F]{2}");
          macAddress = macReg.firstMatch(netRaw)?.group(0) ?? "Bulunamadı";
        }

        // IP Parse
        RegExp ipReg = RegExp(r"IPv4.*: (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})");
        localIp = ipReg.firstMatch(ipRaw)?.group(1) ?? "Bulunamadı";

        isLoading = false;
      });
    }
  }

  // Helper Functions
  String _getValue(String raw, String key) {
    final lines = raw.split('\n');
    for (var line in lines) {
      if (line.trim().startsWith("$key=")) {
        return line.trim().split('=')[1].trim();
      }
    }
    return "-";
  }

  List<String> _getAllValues(String raw, String key) {
    List<String> values = [];
    final lines = raw.split('\n');
    for (var line in lines) {
      if (line.trim().startsWith("$key=")) {
        values.add(line.trim().split('=')[1].trim());
      }
    }
    return values;
  }

  Future<String> _runCommand(String command) async {
    try {
      List<String> parts = command.split(' ');
      var result =
          await Process.run(parts.first, parts.sublist(1), runInShell: true);
      return result.stdout.toString();
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Simsiyah tema
      appBar: AppBar(
        title: Text("SYSTEM_INFO_V2.0",
            style: GoogleFonts.shareTechMono(color: Colors.cyanAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.shareTechMono(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "ÖZET"),
            Tab(text: "CPU"),
            Tab(text: "GPU/RAM"),
            Tab(text: "DISK/NET"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildCpuTab(),
                _buildGpuRamTab(),
                _buildDiskNetTab(),
              ],
            ),
    );
  }

  // --- TAB 1: ÖZET ---
  Widget _buildSummaryTab() {
    return _buildMatrixContainer([
      _buildRow("PC Name", pcName, isTitle: true),
      _buildRow("OS Version", osVersion),
      const Divider(color: Colors.white24),
      _buildRow("Processor", cpuName),
      _buildRow("Graphics", gpuName),
      _buildRow("Memory", "$ramTotal ($ramSpeed)"),
      _buildRow("Storage", "$diskSize ($diskModel)"),
    ]);
  }

  // --- TAB 2: CPU ---
  Widget _buildCpuTab() {
    return _buildMatrixContainer([
      _buildRow("CPU Model", cpuName, isTitle: true),
      _buildRow("Architecture", "x64 (64-Bit)"),
      const Divider(color: Colors.white24),
      _buildRow("Cores/Threads",
          cpuCores), // Thread bilgisini cores içinden almak zor ama basitleştirdik
      _buildRow("Socket Type", cpuSocket),
      _buildRow("L3 Cache", cpuL3Cache),
      _buildRow("Voltage", cpuVoltage),
    ]);
  }

  // --- TAB 3: GPU & RAM ---
  Widget _buildGpuRamTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMatrixContainer([
            _buildRow("GPU Model", gpuName, isTitle: true),
            _buildRow("VRAM Size", gpuVram),
            _buildRow("Driver Ver", gpuDriverVer),
            _buildRow("Driver Date", gpuDriverDate),
            _buildRow("Refresh Rate", gpuRefresh),
          ]),
          const SizedBox(height: 10),
          _buildMatrixContainer([
            _buildRow("RAM Info", "$ramTotal Total", isTitle: true),
            _buildRow("Manufacturer", ramManufacturer),
            _buildRow("Speed", ramSpeed),
            _buildRow("Part Number", ramPartNumber),
            _buildRow("Serial Num", ramSerial),
          ]),
        ],
      ),
    );
  }

  // --- TAB 4: DISK & NETWORK ---
  Widget _buildDiskNetTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMatrixContainer([
            _buildRow("Disk Model", diskModel, isTitle: true),
            _buildRow("Capacity", diskSize),
            _buildRow("Serial Num", diskSerial),
          ]),
          const SizedBox(height: 10),
          _buildMatrixContainer([
            _buildRow("Network", "Active Connection", isTitle: true),
            _buildRow("Local IP", localIp),
            _buildRow("MAC Address", macAddress),
          ]),
        ],
      ),
    );
  }

  // --- TASARIM WIDGETLARI ---
  Widget _buildMatrixContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.05), blurRadius: 20),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(String label, String value, {bool isTitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.shareTechMono(
              color: isTitle ? Colors.cyanAccent : Colors.grey,
              fontSize: isTitle ? 16 : 13,
              fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.shareTechMono(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
