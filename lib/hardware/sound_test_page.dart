import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart'; // v5.1.0
import 'package:path_provider/path_provider.dart'; // Geçici dosya için

class SoundTestPage extends StatefulWidget {
  const SoundTestPage({super.key});

  @override
  State<SoundTestPage> createState() => _SoundTestPageState();
}

class _SoundTestPageState extends State<SoundTestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      appBar: AppBar(
        title: const Text("Ses Donanım Testi"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.speaker), text: "Hoparlör Çıkışı"),
            Tab(icon: Icon(Icons.mic), text: "Mikrofon Girişi"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SpeakerTestTab(),
          MicrophoneTestTab(),
        ],
      ),
    );
  }
}

// --- 1. HOPARLÖR TESTİ (Değişiklik Yok) ---
class SpeakerTestTab extends StatefulWidget {
  const SpeakerTestTab({super.key});

  @override
  State<SpeakerTestTab> createState() => _SpeakerTestTabState();
}

class _SpeakerTestTabState extends State<SpeakerTestTab> {
  final AudioPlayer _player = AudioPlayer();
  String statusText = "Test Hazır";
  bool isPlaying = false;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.stop);
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            statusText = "Test Tamamlandı";
            _balance = 0.0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playSound(double balance, String channelName) async {
    try {
      await _player.stop();
      await _player.setBalance(balance);
      await _player.play(UrlSource(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));
      setState(() {
        _balance = balance;
        statusText = "$channelName Çalıyor...";
      });
    } catch (e) {
      setState(() => statusText = "İnternet Hatası");
    }
  }

  Future<void> _openWindowsSoundSettings() async {
    await Process.run('start', ['ms-settings:sound'], runInShell: true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSpeakerIcon("L", -1.0, Colors.blueAccent),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.headphones,
                        size: 80, color: Colors.grey[700]),
                  ),
                  _buildSpeakerIcon("R", 1.0, Colors.redAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(statusText,
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBtn("SOL", Icons.arrow_back, Colors.blueAccent,
                  () => _playSound(-1.0, "Sol")),
              FloatingActionButton(
                onPressed: () => _player.stop(),
                backgroundColor: Colors.white10,
                child: const Icon(Icons.stop, color: Colors.red),
              ),
              _buildBtn("SAĞ", Icons.arrow_forward, Colors.redAccent,
                  () => _playSound(1.0, "Sağ")),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _openWindowsSoundSettings,
              icon: const Icon(Icons.settings_applications),
              label: const Text("Çıkış Aygıtını Değiştir (Windows Ayarları)"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerIcon(String label, double targetBal, Color color) {
    bool active = (_balance == targetBal && isPlaying) ||
        (_balance.abs() > 0.1 && targetBal.sign == _balance.sign && isPlaying);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.8) : Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
        boxShadow: active
            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 20)]
            : [],
      ),
      child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Colors.white))),
    );
  }

  Widget _buildBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
      ),
    );
  }
}

// --- 2. MİKROFON TESTİ (v5 GÜNCELLENMİŞ KOD) ---
class MicrophoneTestTab extends StatefulWidget {
  const MicrophoneTestTab({super.key});

  @override
  State<MicrophoneTestTab> createState() => _MicrophoneTestTabState();
}

class _MicrophoneTestTabState extends State<MicrophoneTestTab> {
  // DÜZELTME: v5'te sınıf adı AudioRecorder oldu
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _timer;

  double currentDecibel = -160.0;
  double normalizedLevel = 0.0;
  bool isRecording = false;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Geçici dosya yolu al (Windows için gerekli)
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}\\temp_mic_test.m4a';

        // DÜZELTME: v5 start metodu
        await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: tempPath);

        setState(() => isRecording = true);

        // Amplitude (Ses Şiddeti) dinleme
        _timer =
            Timer.periodic(const Duration(milliseconds: 50), (timer) async {
          // DÜZELTME: v5'te getAmplitude böyle çalışır
          final amplitude = await _audioRecorder.getAmplitude();
          final db = amplitude.current;

          setState(() {
            currentDecibel = db;
            // -60dB ile 0dB arasını normalize et
            double minDb = -60;
            double level = (db - minDb) / (0 - minDb);
            normalizedLevel = level.clamp(0.0, 1.0);
          });
        });
      }
    } catch (e) {
      print("Mic Hatası: $e");
    }
  }

  Future<void> _stopListening() async {
    _timer?.cancel();
    await _audioRecorder.stop();
    setState(() {
      isRecording = false;
      normalizedLevel = 0.0;
      currentDecibel = -160;
    });
  }

  Future<void> _openWindowsMicSettings() async {
    await Process.run('start', ['ms-settings:sound-devices'], runInShell: true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("SES GİRİŞ SEVİYESİ",
                      style: TextStyle(color: Colors.grey, letterSpacing: 2)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      width: 60,
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        width: 60,
                        height: MediaQuery.of(context).size.height *
                            0.4 *
                            normalizedLevel,
                        decoration: BoxDecoration(
                          color: _getColorForLevel(normalizedLevel),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                                color: _getColorForLevel(normalizedLevel)
                                    .withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5)
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${currentDecibel.toStringAsFixed(1)} dB",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getColorForLevel(normalizedLevel)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: isRecording ? _stopListening : _startListening,
                    icon: Icon(isRecording ? Icons.mic_off : Icons.mic),
                    label: Text(
                        isRecording ? "TESTİ DURDUR" : "MİKROFONU TEST ET"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isRecording ? Colors.redAccent : Colors.greenAccent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _openWindowsMicSettings,
              icon: const Icon(Icons.settings_voice),
              label: const Text("Giriş Aygıtını Değiştir (Windows Ayarları)"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForLevel(double level) {
    if (level < 0.4) return Colors.greenAccent;
    if (level < 0.7) return Colors.yellowAccent;
    return Colors.redAccent;
  }
}
