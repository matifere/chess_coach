import 'package:flutter/material.dart';
import '../../features/chess/view/chess_page.dart';
import '../../features/analysis/view/analysis_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.brown,
            ),
            child: Text(
              'Chess Coach',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Jugar'),
            selected: currentRoute == '/' || currentRoute == null,
            onTap: () {
              if (currentRoute != '/') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ChessPage(), settings: const RouteSettings(name: '/')),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Análisis'),
            selected: currentRoute == '/analysis',
            onTap: () {
              if (currentRoute != '/analysis') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AnalysisPage(), settings: const RouteSettings(name: '/analysis')),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
