import 'package:flutter/material.dart';
// Sayfa Importları
import 'screen_test_page.dart';
import 'keyboard_page.dart';
import 'mouse_page.dart';
import 'sound_test_page.dart';
import 'system_info_page.dart';
import 'battery_page.dart';

// BU FONKSİYON ÖNEMLİ, main.dart BUNU ARİYOR:
void showHardwareMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.grey, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          const Text("Donanım Testi Seç",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),

          // 1. SİSTEM BİLGİSİ
          ListTile(
            leading: const Icon(Icons.info_outline,
                color: Colors.tealAccent, size: 30),
            title: const Text("Sistem Özellikleri",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("CPU, RAM, GPU ve Disk",
                style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SystemInfoPage()));
            },
          ),
          const Divider(color: Colors.white10),

          // 2. EKRAN TESTİ
          ListTile(
            leading: const Icon(Icons.desktop_windows,
                color: Colors.cyanAccent, size: 30),
            title: const Text("Ekran & Monitör Testi",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Ölü piksel, Ghosting",
                style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ScreenTestPage()));
            },
          ),
          const Divider(color: Colors.white10),

          // 3. KLAVYE TESTİ
          ListTile(
            leading: const Icon(Icons.keyboard,
                color: Colors.orangeAccent, size: 30),
            title: const Text("Klavye Testi",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Tuş basım kontrolü",
                style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const KeyboardPage()));
            },
          ),
          const Divider(color: Colors.white10),

          // 4. MOUSE TESTİ
          ListTile(
            leading:
                const Icon(Icons.mouse, color: Colors.blueAccent, size: 30),
            title: const Text("Mouse Testi",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Tık ve Scroll kontrolü",
                style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const MousePage()));
            },
          ),
          const Divider(color: Colors.white10),

          // 5. SES TESTİ
          ListTile(
            leading:
                const Icon(Icons.speaker, color: Colors.redAccent, size: 30),
            title: const Text("Ses & Hoparlör Testi",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Stereo ve Mikrofon",
                style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SoundTestPage()));
            },
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),

// PİL SAĞLIĞI BUTONU
          ListTile(
            leading: const Icon(Icons.battery_charging_full,
                color: Colors.greenAccent, size: 30),
            title: const Text("Pil Sağlığı & Rapor",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Sağlık yüzdesi ve döngü sayısı",
                style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const BatteryPage()));
            },
          ),
        ],
      ),
    ),
  );
}
