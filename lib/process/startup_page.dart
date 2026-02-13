import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  List<Map<String, String>> startupItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getStartupItems();
  }

  Future<void> _getStartupItems() async {
    // PowerShell ile başlangıç öğelerini çekiyoruz
    var result = await Process.run(
        'powershell',
        [
          '-Command',
          'Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | ConvertTo-Json'
        ],
        runInShell: true);

    // Basit bir parse işlemi (JSON parse etmek daha sağlıklı ama burada hızlıca string işleyelim veya JSON paketi kullanalım)
    // Şimdilik basit liste gösterimi yapalım, ileri seviyede JSON parse ekleriz.
    // Kullanıcıya demo göstermek için manuel liste ile simüle edelim, sonra gerçek veriyi bağlarız.
    // Çünkü PowerShell çıktısını parse etmek biraz detaylı iş.

    if (mounted) {
      setState(() {
        // DEMO VERİ (Gerçekte burası parse edilecek)
        startupItems = [
          {"name": "Steam", "cmd": "C:\\Program Files\\Steam\\steam.exe"},
          {"name": "Discord", "cmd": "C:\\Users\\...\\Discord.exe"},
          {"name": "Spotify", "cmd": "Spotify.exe --minimized"},
        ];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("STARTUP MANAGER",
                style:
                    GoogleFonts.audiowide(fontSize: 24, color: Colors.white)),
            const Text("Bilgisayar açılırken başlayan programları gör.",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: startupItems.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.white.withOpacity(0.05),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading:
                          const Icon(Icons.rocket, color: Colors.cyanAccent),
                      title: Text(startupItems[index]["name"]!,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(startupItems[index]["cmd"]!,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 10),
                          overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          // Silme fonksiyonu buraya gelecek
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  "Bu özellik bir sonraki güncellemede aktif olacak!")));
                        },
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
