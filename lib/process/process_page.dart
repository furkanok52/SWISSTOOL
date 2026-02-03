import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // EKLENDİ

class ProcessPage extends StatefulWidget {
  const ProcessPage({super.key});

  @override
  State<ProcessPage> createState() => _ProcessPageState();
}

class _ProcessPageState extends State<ProcessPage> {
  List<ProcessItem> processes = [];
  bool isLoading = true;
  Timer? _timer;
  double totalRamUsageMb = 0;

  @override
  void initState() {
    super.initState();
    _fetchProcesses();
    // 4 saniyede bir güncelle
    _timer = Timer.periodic(
        const Duration(seconds: 4), (timer) => _fetchProcesses());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchProcesses() async {
    // PowerShell komutu
    String cmd =
        r"Get-Process | Sort-Object -Descending WorkingSet | Select-Object -First 40 Id, ProcessName, WorkingSet | Format-List";

    String raw = await _runCommand(cmd);

    if (mounted) {
      setState(() {
        processes = _parseProcessOutput(raw);
        totalRamUsageMb = processes.fold(0, (sum, item) => sum + item.ramMb);
        isLoading = false;
      });
    }
  }

  Future<void> _killProcess(String id, String name) async {
    bool confirm = await _showConfirmDialog(name);
    if (!confirm) return;

    await Process.run('taskkill', ['/F', '/PID', id]);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 10),
        Text("$name sonlandırıldı.")
      ]),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
    _fetchProcesses();
  }

  Future<bool> _showConfirmDialog(String name) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF161616),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
            title: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 10),
              Text("FORCE KILL",
                  style: GoogleFonts.audiowide(color: Colors.redAccent))
            ]),
            content: Text(
                "$name işlemini zorla kapatmak üzeresin.\nKaydedilmemiş veriler kaybolabilir.",
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("İptal",
                      style: TextStyle(color: Colors.grey))),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                // DÜZELTME: FontAwesomeIcons.skull kullanıldı
                icon: const Icon(FontAwesomeIcons.skull, size: 18),
                label: const Text("YOK ET"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ) ??
        false;
  }

  List<ProcessItem> _parseProcessOutput(String raw) {
    List<ProcessItem> list = [];
    List<String> lines = raw.split('\n');

    String tempId = "";
    String tempName = "";
    double tempRam = 0;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        if (tempId.isNotEmpty) {
          list.add(ProcessItem(id: tempId, name: tempName, ramMb: tempRam));
          tempId = "";
          tempName = "";
          tempRam = 0;
        }
        continue;
      }

      if (line.startsWith("Id")) {
        tempId = line.split(':')[1].trim();
      } else if (line.startsWith("ProcessName")) {
        tempName = line.split(':')[1].trim();
      } else if (line.startsWith("WorkingSet")) {
        double bytes = double.tryParse(line.split(':')[1].trim()) ?? 0;
        tempRam = bytes / (1024 * 1024);
      }
    }
    return list;
  }

  Future<String> _runCommand(String cmd) async {
    try {
      var result =
          await Process.run('powershell', ['-Command', cmd], runInShell: true);
      return result.stdout.toString();
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text("ACTIVE_PROCESS_MONITOR",
            style: GoogleFonts.shareTechMono(
                color: Colors.pinkAccent, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.pinkAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pinkAccent.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.memory, size: 14, color: Colors.pinkAccent),
                const SizedBox(width: 8),
                // DÜZELTME: jetBrainsMono (B harfi büyük)
                Text(
                    "${(totalRamUsageMb / 1024).toStringAsFixed(1)} GB KULLANILIYOR",
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 12, color: Colors.white)),
              ],
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: processes.length,
              itemBuilder: (context, index) {
                final proc = processes[index];

                Color statusColor = Colors.cyanAccent;
                if (proc.ramMb > 1000)
                  statusColor = Colors.redAccent;
                else if (proc.ramMb > 400) statusColor = Colors.orangeAccent;

                double progressVal = (proc.ramMb / 4096).clamp(0.0, 1.0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                          left: BorderSide(color: statusColor, width: 4)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 3))
                      ]),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.grid_view,
                              color: Colors.grey[400], size: 20),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(proc.name,
                                      style: GoogleFonts.roboto(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text("PID: ${proc.id}",
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                            fontFamily: 'monospace')),
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                      height: 4,
                                      width: double.infinity,
                                      color: Colors.grey[800]),
                                  LayoutBuilder(builder: (ctx, constraints) {
                                    return Container(
                                      height: 4,
                                      width:
                                          constraints.maxWidth * progressVal +
                                              10,
                                      decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          boxShadow: [
                                            BoxShadow(
                                                color: statusColor
                                                    .withOpacity(0.6),
                                                blurRadius: 6)
                                          ]),
                                    );
                                  })
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // DÜZELTME: jetBrainsMono (B harfi büyük)
                            Text("${proc.ramMb.toStringAsFixed(0)} MB",
                                style: GoogleFonts.jetBrainsMono(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.power_settings_new,
                              color: Colors.white24),
                          hoverColor: Colors.redAccent,
                          tooltip: "Sonlandır",
                          onPressed: () => _killProcess(proc.id, proc.name),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ProcessItem {
  final String id;
  final String name;
  final double ramMb;

  ProcessItem({required this.id, required this.name, required this.ramMb});
}
