import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as p; // Dosya uzantılarını düzgün almak için

class BulkRenamerPage extends StatefulWidget {
  const BulkRenamerPage({super.key});

  @override
  State<BulkRenamerPage> createState() => _BulkRenamerPageState();
}

class _BulkRenamerPageState extends State<BulkRenamerPage> {
  String? selectedDirectory;
  List<FileSystemEntity> files = [];
  final TextEditingController _nameController = TextEditingController();

  // Klasör Seç
  Future<void> _pickDirectory() async {
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        selectedDirectory = result;
        _loadFiles();
      });
    }
  }

  // Dosyaları Yükle
  void _loadFiles() {
    if (selectedDirectory == null) return;
    final dir = Directory(selectedDirectory!);
    setState(() {
      // Sadece dosyaları al (Klasörleri alma), İsme göre sırala
      files = dir.listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
    });
  }

  // İsim Değiştirme Operasyonu
  Future<void> _renameAll() async {
    if (files.isEmpty || _nameController.text.trim().isEmpty) return;

    String baseName = _nameController.text.trim();
    int count = 0;

    for (int i = 0; i < files.length; i++) {
      var file = files[i];
      String extension = p.extension(file.path); // Örn: .jpg
      String dirPath = p.dirname(file.path);

      // Yeni İsim Formatı: KlasörYolu/YeniIsim-1.jpg
      String newPath = p.join(dirPath, "$baseName-${i + 1}$extension");

      try {
        await file.rename(newPath);
        count++;
      } catch (e) {
        debugPrint("Hata: $e");
      }
    }

    // İşlem bitince listeyi güncelle ve bilgi ver
    _loadFiles();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$count dosya başarıyla yeniden adlandırıldı!"),
        backgroundColor: Colors.green,
      ));
      _nameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("BULK RENAMER",
              style: GoogleFonts.audiowide(fontSize: 24, color: Colors.white)),
          const Text(
              "Yüzlerce dosyayı tek tıkla, düzenli bir şekilde yeniden isimlendir.",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),

          // KONTROL PANELİ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickDirectory,
                        icon:
                            const Icon(Icons.folder_open, color: Colors.black),
                        label: Text(
                            selectedDirectory == null
                                ? "Klasör Seç"
                                : ".../${p.basename(selectedDirectory!)}",
                            style: const TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            padding: const EdgeInsets.symmetric(vertical: 15)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (val) =>
                            setState(() {}), // Yazdıkça önizlemeyi güncelle
                        decoration: InputDecoration(
                          hintText: "Yeni İsim (Örn: Tatil_2024)",
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.edit,
                              color: Colors.purpleAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton.icon(
                      onPressed: (files.isEmpty || _nameController.text.isEmpty)
                          ? null
                          : _renameAll,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("UYGULA",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 20)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ÖNİZLEME LİSTESİ
          const Text("ÖNİZLEME",
              style:
                  TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Expanded(
            child: files.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.tags,
                            size: 50, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 10),
                        Text(
                            "Klasör seçilmedi.\nDosyaları görmek için yukarıdan bir klasör seç.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.2))),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.05))),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: files.length,
                      separatorBuilder: (ctx, i) => Divider(
                          color: Colors.white.withOpacity(0.05), height: 1),
                      itemBuilder: (context, index) {
                        FileSystemEntity file = files[index];
                        String oldName = p.basename(file.path);

                        // Önizleme İsmi Oluşturma
                        String newNamePreview = oldName;
                        if (_nameController.text.isNotEmpty) {
                          String ext = p.extension(file.path);
                          newNamePreview =
                              "${_nameController.text}-${index + 1}$ext";
                        }

                        return ListTile(
                          leading: const Icon(Icons.file_present,
                              color: Colors.grey, size: 20),
                          title: Row(
                            children: [
                              Text(oldName,
                                  style: const TextStyle(color: Colors.grey)),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_right_alt,
                                  color: Colors.cyanAccent, size: 20),
                              const SizedBox(width: 10),
                              Text(newNamePreview,
                                  style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
