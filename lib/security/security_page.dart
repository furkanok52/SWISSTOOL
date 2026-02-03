import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart'; // Hash için gerekli
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("SECURITY_CENTER",
            style: GoogleFonts.shareTechMono(
                color: Colors.redAccent, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.redAccent,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.shareTechMono(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "ŞİFRE ÜRETİCİ", icon: Icon(Icons.vpn_key)),
            Tab(text: "HASH HESAPLA", icon: Icon(Icons.fingerprint)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PasswordGeneratorTab(),
          HashCalculatorTab(),
        ],
      ),
    );
  }
}

// --- 1. ŞİFRE ÜRETİCİ SEKME ---
class PasswordGeneratorTab extends StatefulWidget {
  const PasswordGeneratorTab({super.key});

  @override
  State<PasswordGeneratorTab> createState() => _PasswordGeneratorTabState();
}

class _PasswordGeneratorTabState extends State<PasswordGeneratorTab> {
  double _length = 12;
  bool _useUpper = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  String _generatedPass = "";

  void _generate() {
    const lower = "abcdefghijklmnopqrstuvwxyz";
    const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const numbers = "0123456789";
    const symbols = "!@#\$%^&*()_+-=[]{}|;:,.<>?";

    String chars = lower;
    if (_useUpper) chars += upper;
    if (_useNumbers) chars += numbers;
    if (_useSymbols) chars += symbols;

    String result = "";
    final rnd = Random();
    for (int i = 0; i < _length.toInt(); i++) {
      result += chars[rnd.nextInt(chars.length)];
    }

    setState(() => _generatedPass = result);
  }

  @override
  void initState() {
    super.initState();
    _generate(); // Açılışta bir tane üret
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // ŞİFRE EKRANI
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                SelectableText(
                  _generatedPass,
                  style: GoogleFonts.robotoMono(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text("GÜÇLÜ ŞİFRE",
                    style: GoogleFonts.shareTechMono(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AYARLAR
          _buildSwitch("Büyük Harf (A-Z)", _useUpper,
              (v) => setState(() => _useUpper = v)),
          _buildSwitch("Rakamlar (0-9)", _useNumbers,
              (v) => setState(() => _useNumbers = v)),
          _buildSwitch("Semboller (!@#)", _useSymbols,
              (v) => setState(() => _useSymbols = v)),

          const SizedBox(height: 10),
          Row(
            children: [
              const Text("Uzunluk:", style: TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: _length,
                  min: 6,
                  max: 32,
                  divisions: 26,
                  label: _length.toInt().toString(),
                  activeColor: Colors.redAccent,
                  onChanged: (v) => setState(() => _length = v),
                ),
              ),
              Text("${_length.toInt()}",
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.refresh),
                  label: const Text("YENİ OLUŞTUR"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(15)),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedPass));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Kopyalandı!"),
                      duration: Duration(milliseconds: 500)));
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white10,
                    padding: const EdgeInsets.all(15)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, bool val, Function(bool) onChange) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      value: val,
      activeColor: Colors.redAccent,
      onChanged: onChange,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// --- 2. HASH HESAPLAYICI SEKME ---
class HashCalculatorTab extends StatefulWidget {
  const HashCalculatorTab({super.key});

  @override
  State<HashCalculatorTab> createState() => _HashCalculatorTabState();
}

class _HashCalculatorTabState extends State<HashCalculatorTab> {
  final TextEditingController _inputCtrl = TextEditingController();
  String _md5 = "";
  String _sha1 = "";
  String _sha256 = "";

  void _calculateHash(String text) {
    if (text.isEmpty) {
      setState(() {
        _md5 = "";
        _sha1 = "";
        _sha256 = "";
      });
      return;
    }
    var bytes = utf8.encode(text);
    setState(() {
      _md5 = md5.convert(bytes).toString();
      _sha1 = sha1.convert(bytes).toString();
      _sha256 = sha256.convert(bytes).toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: _calculateHash,
              decoration: InputDecoration(
                labelText: "Metin Giriniz...",
                labelStyle: const TextStyle(color: Colors.redAccent),
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.redAccent),
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.text_fields, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            _buildHashResult("MD5", _md5),
            const SizedBox(height: 15),
            _buildHashResult("SHA-1", _sha1),
            const SizedBox(height: 15),
            _buildHashResult("SHA-256", _sha256),
          ],
        ),
      ),
    );
  }

  Widget _buildHashResult(String label, String result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: SelectableText(
            result.isEmpty ? "-" : result,
            style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
