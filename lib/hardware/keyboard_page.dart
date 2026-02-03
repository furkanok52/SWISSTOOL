import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardPage extends StatefulWidget {
  const KeyboardPage({super.key});

  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage> {
  final Set<LogicalKeyboardKey> pressedKeys = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Odaklanmayı garantiye al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      appBar: AppBar(
        title: const Text("Full Keyboard Test"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                pressedKeys.clear();
              });
              // Sıfırlayınca odağı kaybetmesin
              _focusNode.requestFocus();
            },
            tooltip: "Testi Sıfırla",
          ),
        ],
      ),
      // DÜZELTME: Focus widget'ı en dışa aldık
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            setState(() {
              pressedKeys.add(event.logicalKey);
            });
            return KeyEventResult.handled; // Olayı yakaladığımızı bildiriyoruz
          }
          return KeyEventResult.ignored;
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.keyboard, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Text(
                      "Algılanan Tuş: ${pressedKeys.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainBlock(),
                          const SizedBox(width: 15),
                          _buildNavBlock(),
                          const SizedBox(width: 15),
                          _buildNumpadBlock(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. ANA BLOK ---
  Widget _buildMainBlock() {
    return Column(
      children: [
        Row(
          children: [
            _k(LogicalKeyboardKey.escape, w: 50, color: Colors.redAccent),
            const SizedBox(width: 20),
            _k(LogicalKeyboardKey.f1),
            _k(LogicalKeyboardKey.f2),
            _k(LogicalKeyboardKey.f3),
            _k(LogicalKeyboardKey.f4),
            const SizedBox(width: 10),
            _k(LogicalKeyboardKey.f5),
            _k(LogicalKeyboardKey.f6),
            _k(LogicalKeyboardKey.f7),
            _k(LogicalKeyboardKey.f8),
            const SizedBox(width: 10),
            _k(LogicalKeyboardKey.f9),
            _k(LogicalKeyboardKey.f10),
            _k(LogicalKeyboardKey.f11),
            _k(LogicalKeyboardKey.f12),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _k(LogicalKeyboardKey.backquote),
            _k(LogicalKeyboardKey.digit1),
            _k(LogicalKeyboardKey.digit2),
            _k(LogicalKeyboardKey.digit3),
            _k(LogicalKeyboardKey.digit4),
            _k(LogicalKeyboardKey.digit5),
            _k(LogicalKeyboardKey.digit6),
            _k(LogicalKeyboardKey.digit7),
            _k(LogicalKeyboardKey.digit8),
            _k(LogicalKeyboardKey.digit9),
            _k(LogicalKeyboardKey.digit0),
            _k(LogicalKeyboardKey.minus),
            _k(LogicalKeyboardKey.equal),
            _k(LogicalKeyboardKey.backspace, w: 70, label: "BACK"),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _k(LogicalKeyboardKey.tab, w: 60),
            _k(LogicalKeyboardKey.keyQ),
            _k(LogicalKeyboardKey.keyW),
            _k(LogicalKeyboardKey.keyE),
            _k(LogicalKeyboardKey.keyR),
            _k(LogicalKeyboardKey.keyT),
            _k(LogicalKeyboardKey.keyY),
            _k(LogicalKeyboardKey.keyU),
            _k(LogicalKeyboardKey.keyI),
            _k(LogicalKeyboardKey.keyO),
            _k(LogicalKeyboardKey.keyP),
            _k(LogicalKeyboardKey.bracketLeft),
            _k(LogicalKeyboardKey.bracketRight),
            _k(LogicalKeyboardKey.backslash, w: 50),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _k(LogicalKeyboardKey.capsLock, w: 70, label: "CAPS"),
            _k(LogicalKeyboardKey.keyA),
            _k(LogicalKeyboardKey.keyS),
            _k(LogicalKeyboardKey.keyD),
            _k(LogicalKeyboardKey.keyF),
            _k(LogicalKeyboardKey.keyG),
            _k(LogicalKeyboardKey.keyH),
            _k(LogicalKeyboardKey.keyJ),
            _k(LogicalKeyboardKey.keyK),
            _k(LogicalKeyboardKey.keyL),
            _k(LogicalKeyboardKey.semicolon),
            _k(LogicalKeyboardKey.quote),
            _k(LogicalKeyboardKey.enter, w: 85),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _k(LogicalKeyboardKey.shiftLeft, w: 90, label: "SHIFT"),
            _k(LogicalKeyboardKey.keyZ),
            _k(LogicalKeyboardKey.keyX),
            _k(LogicalKeyboardKey.keyC),
            _k(LogicalKeyboardKey.keyV),
            _k(LogicalKeyboardKey.keyB),
            _k(LogicalKeyboardKey.keyN),
            _k(LogicalKeyboardKey.keyM),
            _k(LogicalKeyboardKey.comma),
            _k(LogicalKeyboardKey.period),
            _k(LogicalKeyboardKey.slash),
            _k(LogicalKeyboardKey.shiftRight, w: 105, label: "SHIFT"),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _k(LogicalKeyboardKey.controlLeft, w: 50, label: "CTRL"),
            _k(LogicalKeyboardKey.metaLeft, w: 50, label: "WIN"),
            _k(LogicalKeyboardKey.altLeft, w: 50, label: "ALT"),
            _k(LogicalKeyboardKey.space, w: 290, label: ""),
            _k(LogicalKeyboardKey.altRight, w: 50, label: "ALT"),
            _k(LogicalKeyboardKey.contextMenu, w: 50, label: "FN"),
            _k(LogicalKeyboardKey.controlRight, w: 50, label: "CTRL"),
          ],
        ),
      ],
    );
  }

  // --- 2. ORTA BLOK ---
  Widget _buildNavBlock() {
    return Column(
      children: [
        Row(
          children: [
            _k(LogicalKeyboardKey.printScreen, label: "PRT"),
            _k(LogicalKeyboardKey.scrollLock, label: "SCR"),
            _k(LogicalKeyboardKey.pause, label: "PAU"),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _k(LogicalKeyboardKey.insert, label: "INS"),
            _k(LogicalKeyboardKey.home, label: "HM"),
            _k(LogicalKeyboardKey.pageUp, label: "PU"),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _k(LogicalKeyboardKey.delete, label: "DEL"),
            _k(LogicalKeyboardKey.end, label: "END"),
            _k(LogicalKeyboardKey.pageDown, label: "PD"),
          ],
        ),
        const SizedBox(height: 35),
        Row(
          children: [
            const SizedBox(width: 45),
            _k(LogicalKeyboardKey.arrowUp, label: "▲"),
            const SizedBox(width: 45),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _k(LogicalKeyboardKey.arrowLeft, label: "◀"),
            _k(LogicalKeyboardKey.arrowDown, label: "▼"),
            _k(LogicalKeyboardKey.arrowRight, label: "▶"),
          ],
        ),
      ],
    );
  }

  // --- 3. NUMPAD BLOK ---
  Widget _buildNumpadBlock() {
    return Column(
      children: [
        Row(
          children: [
            _k(LogicalKeyboardKey.numLock, label: "NUM"),
            _k(LogicalKeyboardKey.numpadDivide, label: "/"),
            _k(LogicalKeyboardKey.numpadMultiply, label: "*"),
            _k(LogicalKeyboardKey.numpadSubtract, label: "-"),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _k(LogicalKeyboardKey.numpad7, label: "7"),
            _k(LogicalKeyboardKey.numpad8, label: "8"),
            _k(LogicalKeyboardKey.numpad9, label: "9"),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _k(LogicalKeyboardKey.numpad4, label: "4"),
            _k(LogicalKeyboardKey.numpad5, label: "5"),
            _k(LogicalKeyboardKey.numpad6, label: "6"),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _k(LogicalKeyboardKey.numpad1, label: "1"),
            _k(LogicalKeyboardKey.numpad2, label: "2"),
            _k(LogicalKeyboardKey.numpad3, label: "3"),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _k(LogicalKeyboardKey.numpad0, w: 90, label: "0"),
            _k(LogicalKeyboardKey.numpadDecimal, label: "."),
          ],
        ),
      ],
    );
  }

  Widget _k(
    LogicalKeyboardKey key, {
    double w = 40,
    String? label,
    Color? color,
  }) {
    bool isPressed = pressedKeys.contains(key);
    String text = label ?? key.keyLabel.toUpperCase();

    if (text.startsWith("NUMPAD ")) text = text.replaceFirst("NUMPAD ", "");
    if (text == "ALTRIGHT") text = "ALT";
    if (text == "ALTLEFT") text = "ALT";
    if (text == "METALEFT") text = "WIN";

    return Container(
      width: w,
      height: 40,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isPressed
            ? (color ?? Colors.greenAccent)
            : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPressed ? Colors.green : Colors.white10,
          width: isPressed ? 2 : 1,
        ),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: (color ?? Colors.greenAccent).withOpacity(0.6),
                  blurRadius: 10,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isPressed ? Colors.black : Colors.white60,
            fontSize: text.length > 2 ? 10 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
