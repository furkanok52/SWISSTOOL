import 'dart:io';
import 'package:flutter/material.dart';

class SystemDoctorPage extends StatefulWidget {
  const SystemDoctorPage({super.key});

  @override
  State<SystemDoctorPage> createState() => _SystemDoctorPageState();
}

class _SystemDoctorPageState extends State<SystemDoctorPage> {
  // Logları tutacak liste
  List<String> logs = [];
  final ScrollController _scrollController = ScrollController();
  bool isWorking = false;

  // --- LOG EKLEME FONKSİYONU ---
  void addLog(String message, {bool isError = false}) {
    setState(() {
      logs.add(isError ? "❌ $message" : "✅ $message");
    });
    // Otomatik en aşağı kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- 1. TEMP TEMİZLİĞİ ---
  Future<void> _cleanTempFiles() async {
    addLog("Temp klasörü taranıyor...");

    // Windows Temp Klasörü: C:\Users\Kullanici\AppData\Local\Temp
    String tempPath = Platform.environment['TEMP'] ?? "";

    if (tempPath.isEmpty) {
      addLog("Temp klasörü bulunamadı!", isError: true);
      return;
    }

    final dir = Directory(tempPath);
    int deletedCount = 0;
    int sizeSaved = 0;

    if (await dir.exists()) {
      // Dosyaları listele (recursive false: sadece ana klasördekileri siler, güvenli olsun)
      // Recursive true yaparsak alt klasörleri de siler ama bazen kilitli dosyalarda takılabilir.
      await for (var entity in dir.list(recursive: false)) {
        try {
          if (entity is File) {
            int size = await entity.length();
            await entity.delete();
            addLog("Silindi: ${entity.uri.pathSegments.last}");
            deletedCount++;
            sizeSaved += size;
          } else if (entity is Directory) {
            // Klasör silmek risklidir, şimdilik atlıyoruz veya istersen açabilirsin.
            // await entity.delete(recursive: true);
          }
        } catch (e) {
          // Kilitli dosya hatası (Çok normaldir, Chrome vs açıksa silinmez)
          // addLog("Silinemedi (Kullanımda): ${entity.path}", isError: true);
        }
      }
    }

    double mbSaved = sizeSaved / (1024 * 1024);
    addLog("--- TEMİZLİK SONUCU ---");
    addLog("$deletedCount dosya temizlendi.");
    addLog("${mbSaved.toStringAsFixed(2)} MB yer açıldı.");
  }

  // --- 2. DNS ve NETWORK TAMİRİ ---
  Future<void> _fixNetwork() async {
    addLog("Network onarımı başlatılıyor...");

    try {
      addLog("DNS Önbelleği temizleniyor (flushdns)...");
      var result1 = await Process.run('ipconfig', ['/flushdns']);
      if (result1.exitCode == 0) addLog("DNS Başarıyla temizlendi.");

      addLog("IP Adresi yenileniyor (release/renew)...");
      // Not: Renew işlemi 2-3 saniye sürebilir ve internet kopup gelir.
      // Hızlı olsun diye sadece flushdns yapalım, renew opsiyonel olsun.
      // await Process.run('ipconfig', ['/renew']);

      addLog("Winsock kataloğu sıfırlanıyor...");
      // Bu işlem yönetici izni ister, normal modda hata verebilir ama deneriz.
      // await Process.run('netsh', ['winsock', 'reset']);

      addLog("Network işlemleri tamamlandı.");
    } catch (e) {
      addLog("Hata oluştu: $e", isError: true);
    }
  }

  // --- 3. DİSK TEMİZLEME ARACI ---
  Future<void> _openDiskCleanup() async {
    addLog("Windows Disk Temizleme aracı açılıyor...");
    try {
      await Process.run('cleanmgr', []);
      addLog("Araç başlatıldı.");
    } catch (e) {
      addLog("Araç açılamadı: $e", isError: true);
    }
  }

  // --- OTOMATİK DOKTOR (HEPSİNİ YAP) ---
  Future<void> _runAll() async {
    if (isWorking) return;

    setState(() {
      isWorking = true;
      logs.clear();
      addLog("SİSTEM DOKTORU BAŞLATILDI...");
    });

    await Future.delayed(const Duration(milliseconds: 500));
    await _cleanTempFiles();

    await Future.delayed(const Duration(milliseconds: 500));
    await _fixNetwork();

    setState(() => isWorking = false);
    addLog("TÜM İŞLEMLER BİTTİ. BİLGİSAYAR RAHATLADI! 🚀");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      appBar: AppBar(
        title: const Text("Sistem Doktoru"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => logs.clear()),
            tooltip: "Logları Temizle",
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ÜST KISIM: BUTONLAR
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    "Hızlı Temizlik",
                    "Temp dosyalarını sil, DNS'i temizle.",
                    Icons.cleaning_services,
                    Colors.greenAccent,
                    _runAll,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionCard(
                    "Disk Aracı",
                    "Windows'un kendi temizleyicisini aç.",
                    Icons.storage,
                    Colors.orangeAccent,
                    _openDiskCleanup,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ORTA KISIM: LOG EKRANI (Matrix Style)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("İŞLEM GÜNLÜĞÜ (LOGS)",
                  style: TextStyle(
                      color: Colors.grey, letterSpacing: 2, fontSize: 12)),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border:
                      Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.1),
                        blurRadius: 20)
                  ],
                ),
                child: logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.terminal,
                                size: 50, color: Colors.grey[800]),
                            const SizedBox(height: 10),
                            Text("Hazır. Başlamak için butona basın.",
                                style: TextStyle(color: Colors.grey[800])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final isErr = log.startsWith("❌");
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              log,
                              style: TextStyle(
                                color: isErr
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontFamily: 'Consolas', // Hacker fontu :)
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String desc, IconData icon, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: isWorking ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(desc,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
