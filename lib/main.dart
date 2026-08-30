import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:chess_coach/src/rust/api/simple.dart' as rust_api;
import 'package:chess_coach/src/rust/frb_generated.dart';
import 'features/chess/view/chess_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // Load the NNUE network
  try {
    final byteData = await rootBundle.load('assets/nn/maia-1100.nnue');
    final bytes = byteData.buffer.asUint8List();
    final loaded = rust_api.initNnue(bytes: bytes);
    debugPrint('NNUE loaded: $loaded');
  } catch (e) {
    debugPrint('Failed to load NNUE: $e');
  }

  runApp(const ChessCoachApp());
}

class ChessCoachApp extends StatelessWidget {
  const ChessCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chess Coach',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const ChessPage(),
    );
  }
}
