import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';

class FloatingMonitor extends StatefulWidget {
  final VoidCallback onExpand;
  const FloatingMonitor({super.key, required this.onExpand});

  @override
  State<FloatingMonitor> createState() => _FloatingMonitorState();
}

class _FloatingMonitorState extends State<FloatingMonitor> {
  String cpu = "0";
  String ram = "0";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateStats();
    // Oyundayken işlemciyi yormasın diye 3 saniyede bir güncelliyoruz
    _timer =
        Timer.periodic(const Duration(seconds: 3), (timer) => _updateStats());
  }

  Future<void> _updateStats() async {
    try {
      // Hızlı PowerShell sorguları
      var cpuRes = await Process.run(
          'powershell',
          [
            '-Command',
            'Get-WmiObject Win32_Processor | Select-Object -ExpandProperty LoadPercentage'
          ],
          runInShell: true);
      var ramRes = await Process.run(
          'powershell',
          [
            '-Command',
            'Get-CimInstance Win32_OperatingSystem | Select-Object @{Name="U";Expression={"{0:N1}" -f ((\$_.TotalVisibleMemorySize - \$_.FreePhysicalMemory) / 1024 / 1024)}} | Select-Object -ExpandProperty U'
          ],
          runInShell: true);

      if (mounted) {
        setState(() {
          cpu = cpuRes.stdout.toString().trim();
          ram = ramRes.stdout.toString().trim();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      // Tıklamaları algılaması için Material şart
      color: Colors.transparent,
      child: GestureDetector(
        onPanStart: (details) => windowManager.startDragging(),
        onDoubleTap: widget.onExpand,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6), // Daha şeffaf
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem("CPU", "$cpu%", Colors.orangeAccent),
              _statItem("RAM", "${ram}GB", Colors.purpleAccent),
              InkWell(
                onTap: widget.onExpand,
                child: const Icon(Icons.open_in_full,
                    size: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: GoogleFonts.shareTechMono(color: Colors.grey, fontSize: 9)),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
