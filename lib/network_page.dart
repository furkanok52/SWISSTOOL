import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http; // IP için http lazım

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  // --- IP ve Ping Değişkenleri ---
  String localIp = "Bekleniyor...";
  String publicIp = "Bekleniyor...";
  String pingStatus = "Başlatılmadı";
  bool isScanningIp = false;

  // --- Speedtest Değişkenleri ---
  String downloadSpeed = "0.0";
  String uploadSpeed = "0.0";
  String speedPing = "--";
  String jitter = "--";
  String serverName = "Hazır";
  String ispName = "--";
  double progressValue = 0;
  bool isTesting = false;

  Process? _process;

  @override
  void initState() {
    super.initState();
    _getNetworkInfo(); // Sayfa açılınca IP'leri çek
  }

  @override
  void dispose() {
    _process?.kill();
    super.dispose();
  }

  // 1. ESKİ IP BULMA FONKSİYONUMUZ (Geri Döndü!)
  Future<void> _getNetworkInfo() async {
    if (!mounted) return;
    setState(() => isScanningIp = true);

    try {
      // Yerel IP
      String foundIp = "Bulunamadı";
      var interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            foundIp = addr.address;
            break;
          }
        }
        if (foundIp != "Bulunamadı") break;
      }

      // Dış IP
      var response = await http.get(Uri.parse('https://api.ipify.org'));

      // Basit Google Pingi
      String pingCmd = Platform.isWindows ? '-n' : '-c';
      var pingResult = await Process.run('ping', [pingCmd, '1', '8.8.8.8']);

      if (mounted) {
        setState(() {
          localIp = foundIp;
          publicIp = response.statusCode == 200 ? response.body : "Hata";
          pingStatus = (pingResult.exitCode == 0) ? "Online" : "Hata";
        });
      }
    } catch (e) {
      if (mounted) setState(() => localIp = "Hata");
    }

    if (mounted) setState(() => isScanningIp = false);
  }

  // 2. NATIVE SPEEDTEST (Düzeltildi)
  Future<void> _runNativeSpeedTest() async {
    if (isTesting) return;

    setState(() {
      isTesting = true;
      downloadSpeed = "Başlıyor...";
      uploadSpeed = "0.0";
      progressValue = 0;
      serverName = "Sunucu Aranıyor...";
    });

    try {
      // DÜZELTME: Exe'yi projenin ana dizininde ara
      // (Debug modunda assets içinden exe çalışmaz)
      String exePath = 'speedtest.exe';

      if (!File(exePath).existsSync()) {
        // Belki assets klasöründedir diye oraya da bakalım
        if (File('assets/speedtest.exe').existsSync()) {
          exePath = 'assets/speedtest.exe';
        } else {
          setState(() {
            downloadSpeed = "EXE YOK!";
            serverName = "Lütfen speedtest.exe'yi proje klasörüne at.";
          });
          isTesting = false;
          return;
        }
      }

      // Komutu çalıştır
      _process = await Process.start(exePath, [
        '--format=json-pretty',
        '--progress=yes',
        '--accept-license',
        '--accept-gdpr',
      ], runInShell: true);

      // Çıktıları satır satır oku
      _process!.stdout.transform(utf8.decoder).listen((data) {
        print("LOG: $data"); // Konsoldan takip et
        _parseSpeedtestOutput(data);
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        print("HATA: $data");
      });

      await _process!.exitCode;

      if (mounted) {
        setState(() {
          isTesting = false;
          progressValue = 1.0;
          if (downloadSpeed == "Başlıyor...") downloadSpeed = "Tamamlandı";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          downloadSpeed = "Hata";
          serverName = e.toString();
          isTesting = false;
        });
      }
    }
  }

  void _parseSpeedtestOutput(String data) {
    try {
      // İLERLEME (JSON değil, text olarak gelir)
      // Örnek: "Download: 45.5 Mbps (12%)"
      if (data.contains('Download:') && data.contains('%')) {
        setState(() => serverName = "İndirme Testi...");
        // Görsel animasyon
        if (progressValue < 0.5) progressValue += 0.05;
      }
      if (data.contains('Upload:') && data.contains('%')) {
        setState(() => serverName = "Yükleme Testi...");
        if (progressValue < 0.9) progressValue += 0.05;
      }

      // JSON VERİSİ
      if (data.contains('{')) {
        final cleanData = data.trim();

        // PING
        if (cleanData.contains('"ping":')) {
          final jsonMap = jsonDecode(cleanData);
          if (jsonMap['ping'] != null) {
            setState(() {
              speedPing = double.parse(
                jsonMap['ping']['latency'].toString(),
              ).toStringAsFixed(0);
              jitter = double.parse(
                jsonMap['ping']['jitter'].toString(),
              ).toStringAsFixed(0);
            });
          }
        }

        // DOWNLOAD SONUCU
        if (cleanData.contains('"download":') &&
            cleanData.contains('"bandwidth":')) {
          final jsonMap = jsonDecode(cleanData);
          final bandwidth = jsonMap['download']['bandwidth'];
          final mbps = (bandwidth * 8 / 1000000).toStringAsFixed(1);
          setState(() {
            downloadSpeed = mbps;
            progressValue = 0.5;
          });
        }

        // UPLOAD SONUCU
        if (cleanData.contains('"upload":') &&
            cleanData.contains('"bandwidth":')) {
          final jsonMap = jsonDecode(cleanData);
          final bandwidth = jsonMap['upload']['bandwidth'];
          final mbps = (bandwidth * 8 / 1000000).toStringAsFixed(1);
          setState(() {
            uploadSpeed = mbps;
            progressValue = 1.0;
          });
        }

        // SUNUCU & ISP
        if (cleanData.contains('"server":')) {
          final jsonMap = jsonDecode(cleanData);
          setState(() {
            serverName =
                "${jsonMap['server']['name']} (${jsonMap['server']['location']})";
            ispName = jsonMap['isp'] ?? "--";
          });
        }
      }
    } catch (e) {
      // JSON parse hatası önemsiz, parça veri gelmiştir
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SwissTool Network"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isScanningIp ? null : _getNetworkInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. IP BİLGİ KARTLARI (Geri Geldi!) ---
              _buildInfoCard("Local IP", localIp, Icons.laptop, Colors.blue),
              const SizedBox(height: 10),
              _buildInfoCard(
                "Public IP",
                publicIp,
                Icons.public,
                Colors.purple,
              ),
              const SizedBox(height: 10),
              _buildInfoCard(
                "Google Ping",
                pingStatus,
                Icons.network_check,
                Colors.green,
              ),

              const SizedBox(height: 30),
              const Divider(color: Colors.white10),
              const SizedBox(height: 20),

              // --- 2. OOKLA SPEEDTEST BÖLÜMÜ ---
              Text(
                "Ookla Speedtest Native",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Detaylar (Ping, Jitter, ISP)
              Row(
                children: [
                  Expanded(
                    child: _buildMiniCard(
                      "Ping",
                      "$speedPing ms",
                      Icons.speed,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMiniCard(
                      "Jitter",
                      "$jitter ms",
                      Icons.graphic_eq,
                      Colors.pink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMiniCard(
                      "ISP",
                      ispName,
                      Icons.wifi,
                      Colors.teal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Hız Göstergesi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isTesting ? Colors.cyanAccent : Colors.white10,
                  ),
                  boxShadow: isTesting
                      ? [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.2),
                            blurRadius: 40,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    const Text(
                      "DOWNLOAD",
                      style: TextStyle(
                        letterSpacing: 2,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          downloadSpeed,
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: isTesting ? Colors.cyanAccent : Colors.white,
                          ),
                        ),
                        const Text(
                          " Mbps",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 15),
                    const Text(
                      "UPLOAD",
                      style: TextStyle(
                        letterSpacing: 2,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "$uploadSpeed Mbps",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // İlerleme ve Sunucu Adı
              Text(
                serverName,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progressValue,
                color: Colors.cyanAccent,
                backgroundColor: Colors.white10,
                minHeight: 4,
              ),

              const SizedBox(height: 30),

              // Başlat Butonu
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: isTesting ? null : _runNativeSpeedTest,
                  icon: isTesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.rocket_launch),
                  label: Text(
                    isTesting ? "TEST YAPILIYOR..." : "HIZ TESTİNİ BAŞLAT",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // IP Kart Tasarımı (Eski stil)
  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Speedtest Mini Kart Tasarımı
  Widget _buildMiniCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
