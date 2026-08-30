// The original content is temporarily commented out to allow generating a self-contained demo - feel free to uncomment later.

// import 'package:flutter/material.dart';
// import 'features/chess/view/chess_page.dart';
//
// void main() {
//   runApp(const ChessCoachApp());
// }
//
// class ChessCoachApp extends StatelessWidget {
//   const ChessCoachApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Chess Coach',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
//         useMaterial3: true,
//       ),
//       home: const ChessPage(),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:chess_coach/src/rust/api/simple.dart';
import 'package:chess_coach/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Center(
          child: Text(
            'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`',
          ),
        ),
      ),
    );
  }
}
