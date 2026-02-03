import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LargeFileFinderPage extends StatefulWidget {
  const LargeFileFinderPage({super.key});

  @override
  State<LargeFileFinderPage> createState() => _LargeFileFinderPageState();
}

class _LargeFileFinderPageState extends State<LargeFileFinderPage> {
  String? selectedDirectory;
  List<FileSystemEntity> largeFiles = [];
  bool isScanning = false;
  int sizeLimitMB = 100; // Varsayılan sınır 100 MB

  // Klasör Seçme Fonksiyonu
  Future<void> _pickDirectory() async {
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        selectedDirectory = result;
        largeFiles.clear(); // Yeni klasör seçince eski listeyi temizle
      });
    }
  }

  // Tarama Fonksiyonu (Recursion yerine güvenli tarama)
  Future<void> _scanFiles() async {
    if (selectedDirectory == null) return;

    setState(() {
      isScanning = true;
      largeFiles.clear();
    });

    try {
      final dir = Directory(selectedDirectory!);
      // Recursive: true diyerek alt klasörlere de bakıyoruz
      var stream = dir.list(recursive: true, followLinks: false);

      await for (var entity in stream) {
        if (entity is File) {
          try {
            int sizeBytes = await entity.length();
            double sizeMB = sizeBytes / (1024 * 1024);

            if (sizeMB > sizeLimitMB) {
              setState(() {
                largeFiles.add(entity);
                // Büyükten küçüğe sırala
                largeFiles.sort((a, b) => (b as File)
                    .lengthSync()
                    .compareTo((a as File).lengthSync()));
              });
            }
          } catch (e) {
            // Erişim izni olmayan dosyaları atla
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint("Tarama Hatası: $e");
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  // Dosya Silme Fonksiyonu
  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      setState(() {
        largeFiles.remove(file);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Dosya başarıyla silindi.",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Hata: Dosya silinemedi! $e",
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red),
      );
    }
  }

  // Dosya Boyutunu Okunabilir Yapma (MB/GB)
  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
    } else {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BAŞLIK
          Text("LARGE FILE FINDER",
              style: GoogleFonts.audiowide(fontSize: 24, color: Colors.white)),
          const Text("Diskinde yer kaplayan devasa dosyaları bul ve yok et.",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),

          // KONTROL PANELİ
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                // Klasör Seç Butonu
                ElevatedButton.icon(
                  onPressed: isScanning ? null : _pickDirectory,
                  icon: const Icon(Icons.folder_open, color: Colors.black),
                  label: Text(
                      selectedDirectory == null
                          ? "Klasör Seç"
                          : ".../${selectedDirectory!.split('\\').last}",
                      style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent),
                ),
                const SizedBox(width: 15),

                // Boyut Limiti Dropdown
                DropdownButton<int>(
                  value: sizeLimitMB,
                  dropdownColor: const Color(0xFF222222),
                  style: const TextStyle(color: Colors.white),
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 50, child: Text("> 50 MB")),
                    DropdownMenuItem(value: 100, child: Text("> 100 MB")),
                    DropdownMenuItem(value: 500, child: Text("> 500 MB")),
                    DropdownMenuItem(value: 1000, child: Text("> 1 GB")),
                  ],
                  onChanged: (val) => setState(() => sizeLimitMB = val!),
                ),

                const Spacer(),

                // Tara Butonu
                ElevatedButton.icon(
                  onPressed: (selectedDirectory == null || isScanning)
                      ? null
                      : _scanFiles,
                  icon: isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search, color: Colors.white),
                  label: Text(isScanning ? "Taranıyor..." : "TARAMAYI BAŞLAT",
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SONUÇ LİSTESİ
          Expanded(
            child: largeFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.magnifyingGlass,
                            size: 50, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 10),
                        Text(
                            isScanning
                                ? "Dosyalar taranıyor, lütfen bekle..."
                                : "Henüz bir dosya bulunamadı.\nBir klasör seç ve taramayı başlat.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.2))),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: largeFiles.length,
                    itemBuilder: (context, index) {
                      final file = largeFiles[index] as File;
                      int size = file.lengthSync();

                      return Card(
                        color: const Color(0xFF1A1A1A),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.05)),
                            borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: const Icon(FontAwesomeIcons.file,
                              color: Colors.orangeAccent),
                          title: Text(file.uri.pathSegments.last,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(file.path,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 10)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_formatSize(size),
                                  style: GoogleFonts.jetBrainsMono(
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 15),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () {
                                  // Silme Onayı
                                  showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                            backgroundColor:
                                                const Color(0xFF222222),
                                            title: const Text("Dosyayı Sil?",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            content: Text(
                                                "Bu işlem geri alınamaz:\n${file.uri.pathSegments.last}",
                                                style: const TextStyle(
                                                    color: Colors.grey)),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text("İptal")),
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    _deleteFile(file);
                                                  },
                                                  child: const Text("SİL",
                                                      style: TextStyle(
                                                          color: Colors
                                                              .redAccent))),
                                            ],
                                          ));
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
