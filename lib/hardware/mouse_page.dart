import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MousePage extends StatefulWidget {
  const MousePage({super.key});

  @override
  State<MousePage> createState() => _MousePageState();
}

class _MousePageState extends State<MousePage> {
  // Tuş Durumları
  bool isLeftPressed = false;
  bool isRightPressed = false;
  bool isMiddlePressed = false;

  // Veriler
  int scrollValue = 0;
  int doubleClickCount = 0;
  String statusMessage = "Test için tuşlara bas...";
  Color statusColor = Colors.grey;

  // Çift Tıklama Algoritması
  int _lastLeftClickTime = 0;

  void _handleMouseDown(PointerDownEvent event) {
    setState(() {
      if (event.buttons == kPrimaryMouseButton) {
        isLeftPressed = true;
        _checkDoubleClick();
      } else if (event.buttons == kSecondaryMouseButton) {
        isRightPressed = true;
        statusMessage = "Sağ Tuş Çalışıyor";
        statusColor = Colors.blueAccent;
      } else if (event.buttons == kMiddleMouseButton) {
        isMiddlePressed = true;
        statusMessage = "Orta Tuş (Tekerlek) Çalışıyor";
        statusColor = Colors.purpleAccent;
      }
    });
  }

  void _handleMouseUp(PointerUpEvent event) {
    setState(() {
      isLeftPressed = false;
      isRightPressed = false;
      isMiddlePressed = false;
    });
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      setState(() {
        if (event.scrollDelta.dy < 0) {
          scrollValue++;
          statusMessage = "Yukarı Scroll";
        } else {
          scrollValue--;
          statusMessage = "Aşağı Scroll";
        }
        statusColor = Colors.orangeAccent;
      });
    }
  }

  void _checkDoubleClick() {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastLeftClickTime < 400) {
      doubleClickCount++;
      statusMessage = "⚠️ ÇİFT TIKLAMA ALGILANDI!";
      statusColor = Colors.redAccent;
    } else {
      statusMessage = "Sol Tuş Normal";
      statusColor = Colors.greenAccent;
    }
    _lastLeftClickTime = now;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      appBar: AppBar(
        title: const Text("Mouse Testi"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                scrollValue = 0;
                doubleClickCount = 0;
                statusMessage = "Sıfırlandı";
              });
            },
          ),
        ],
      ),
      // Listener tüm ekranı dinler
      body: Listener(
        onPointerDown: _handleMouseDown,
        onPointerUp: _handleMouseUp,
        onPointerSignal: _handleScroll,
        // DÜZELTME BURADA: SingleChildScrollView eklendi
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Tatlı bir kaydırma efekti
          child: Container(
            // Ekran küçükse bile içeriği ortalamaya çalış, ama taşarsa kaydır
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  100, // AppBar payı düşünce
            ),
            width: double.infinity,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // BİLGİ KUTUSU
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusMessage,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // --- SANAL MOUSE GÖRSELİ ---
                SizedBox(
                  width: 200,
                  height: 300,
                  child: Stack(
                    children: [
                      // GÖVDE
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 180,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(50),
                            ),
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mouse,
                              size: 50,
                              color: Colors.white10,
                            ),
                          ),
                        ),
                      ),
                      // SOL TIK
                      Positioned(
                        top: 0,
                        left: 0,
                        width: 95,
                        height: 110,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            color: isLeftPressed
                                ? Colors.greenAccent
                                : Colors.grey[700],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(50),
                            ),
                            border: Border.all(
                              color: isLeftPressed
                                  ? Colors.green
                                  : Colors.white24,
                              width: 2,
                            ),
                            boxShadow: isLeftPressed
                                ? [
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 20,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              "SOL",
                              style: TextStyle(
                                color: isLeftPressed
                                    ? Colors.black
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // SAĞ TIK
                      Positioned(
                        top: 0,
                        right: 0,
                        width: 95,
                        height: 110,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            color: isRightPressed
                                ? Colors.blueAccent
                                : Colors.grey[700],
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(50),
                            ),
                            border: Border.all(
                              color: isRightPressed
                                  ? Colors.blue
                                  : Colors.white24,
                              width: 2,
                            ),
                            boxShadow: isRightPressed
                                ? [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.5),
                                      blurRadius: 20,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              "SAĞ",
                              style: TextStyle(
                                color: isRightPressed
                                    ? Colors.black
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // SCROLL
                      Positioned(
                        top: 0,
                        left: 100 - 15,
                        width: 30,
                        height: 80,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            color: isMiddlePressed
                                ? Colors.purpleAccent
                                : Colors.black,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white38),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.arrow_drop_up,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 4,
                                height: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 2),
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 12,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // İSTATİSTİKLER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      "Scroll Sayacı",
                      "$scrollValue",
                      Icons.unfold_more,
                    ),
                    _buildStatCard(
                      "Double Click",
                      "$doubleClickCount",
                      Icons.ads_click,
                      color: doubleClickCount > 0
                          ? Colors.redAccent
                          : Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  "Not: Tek basmanıza rağmen Double Click artıyorsa mouse anahtarında sorun olabilir.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    Color color = Colors.grey,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
