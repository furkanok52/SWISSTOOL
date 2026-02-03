import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("DEVELOPER_KIT_V1",
            style: GoogleFonts.shareTechMono(
                color: Colors.greenAccent, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.shareTechMono(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "JSON FORMAT"),
            Tab(text: "BASE64"),
            Tab(text: "URL ENC/DEC"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          JsonTab(),
          Base64Tab(),
          UrlTab(),
        ],
      ),
    );
  }
}

// --- 1. JSON FORMATTER TAB ---
class JsonTab extends StatefulWidget {
  const JsonTab({super.key});

  @override
  State<JsonTab> createState() => _JsonTabState();
}

class _JsonTabState extends State<JsonTab> {
  final TextEditingController _inputCtrl = TextEditingController();
  String _output = "";

  void _formatJson() {
    try {
      if (_inputCtrl.text.isEmpty) return;
      // JSON'u parse et ve girintili (indent) string'e çevir
      var object = json.decode(_inputCtrl.text);
      var prettyString = const JsonEncoder.withIndent('  ').convert(object);
      setState(() => _output = prettyString);
    } catch (e) {
      setState(() => _output = "HATA: Geçersiz JSON Formatı!\n${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildToolLayout(
      inputCtrl: _inputCtrl,
      output: _output,
      inputHint: 'Karışık JSON verisini buraya yapıştır...',
      actions: [
        _actionBtn("GÜZELLEŞTİR (BEAUTIFY)", Icons.auto_fix_high, _formatJson),
      ],
    );
  }
}

// --- 2. BASE64 TAB ---
class Base64Tab extends StatefulWidget {
  const Base64Tab({super.key});

  @override
  State<Base64Tab> createState() => _Base64TabState();
}

class _Base64TabState extends State<Base64Tab> {
  final TextEditingController _inputCtrl = TextEditingController();
  String _output = "";

  void _encode() {
    try {
      String encoded = base64.encode(utf8.encode(_inputCtrl.text));
      setState(() => _output = encoded);
    } catch (e) {
      setState(() => _output = "Hata: $e");
    }
  }

  void _decode() {
    try {
      String decoded = utf8.decode(base64.decode(_inputCtrl.text));
      setState(() => _output = decoded);
    } catch (e) {
      setState(() => _output = "HATA: Geçersiz Base64 formatı!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildToolLayout(
      inputCtrl: _inputCtrl,
      output: _output,
      inputHint: 'Metni veya Base64 kodunu buraya gir...',
      actions: [
        _actionBtn("ŞİFRELE (ENCODE)", Icons.lock_outline, _encode),
        const SizedBox(width: 10),
        _actionBtn("ÇÖZ (DECODE)", Icons.lock_open, _decode),
      ],
    );
  }
}

// --- 3. URL TAB ---
class UrlTab extends StatefulWidget {
  const UrlTab({super.key});

  @override
  State<UrlTab> createState() => _UrlTabState();
}

class _UrlTabState extends State<UrlTab> {
  final TextEditingController _inputCtrl = TextEditingController();
  String _output = "";

  void _encode() {
    setState(() => _output = Uri.encodeFull(_inputCtrl.text));
  }

  void _decode() {
    try {
      setState(() => _output = Uri.decodeFull(_inputCtrl.text));
    } catch (e) {
      setState(() => _output = "Hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildToolLayout(
      inputCtrl: _inputCtrl,
      output: _output,
      inputHint:
          'URL adresini buraya gir (örn: https://site.com?q=merhaba dünya)...',
      actions: [
        _actionBtn("ENCODE", Icons.link, _encode),
        const SizedBox(width: 10),
        _actionBtn("DECODE", Icons.link_off, _decode),
      ],
    );
  }
}

// --- ORTAK TASARIM KALIBI (DRY PRINCIPLE) ---
Widget _buildToolLayout({
  required TextEditingController inputCtrl,
  required String output,
  required String inputHint,
  required List<Widget> actions,
}) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SOL TARAF: GİRİŞ (INPUT)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const Text("GİRİŞ",
                  style: TextStyle(color: Colors.grey, letterSpacing: 2)),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: TextField(
                    controller: inputCtrl,
                    maxLines: null,
                    style: GoogleFonts.robotoMono(
                        color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: inputHint,
                      hintStyle: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(children: actions), // Butonlar burada
            ],
          ),
        ),

        const SizedBox(width: 20),

        // SAĞ TARAF: ÇIKIŞ (OUTPUT)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("SONUÇ",
                      style: TextStyle(
                          color: Colors.greenAccent, letterSpacing: 2)),
                  if (output.isNotEmpty)
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: output));
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.copy, size: 14, color: Colors.greenAccent),
                          SizedBox(width: 5),
                          Text("KOPYALA",
                              style: TextStyle(
                                  color: Colors.greenAccent, fontSize: 12)),
                        ],
                      ),
                    )
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F), // Daha koyu
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      // Kopyalanabilir metin
                      output,
                      style: GoogleFonts.robotoMono(
                          color: output.startsWith("HATA") ||
                                  output.startsWith("Hata")
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Boşluk doldurucu (Buton hizası için)
              const SizedBox(height: 45),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
  return Expanded(
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent.withOpacity(0.1),
        foregroundColor: Colors.greenAccent,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
      ),
    ),
  );
}
