import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/chess_cubit.dart';
import '../cubit/chess_state.dart';
import 'widgets/chess_board.dart';
import 'package:chess/chess.dart' as ch;

class ChessPage extends StatelessWidget {
  const ChessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChessCubit(),
      child: const ChessView(),
    );
  }
}

class ChessView extends StatelessWidget {
  const ChessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Coach'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          final boardWidget = Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? constraints.maxHeight : double.infinity),
                child: const ChessBoard(),
              ),
            ),
          );

          final menuWidget = const SideMenu();

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: boardWidget),
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: const Border(left: BorderSide(color: Colors.black12, width: 1)),
                  ),
                  child: menuWidget,
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(flex: 3, child: boardWidget),
                Expanded(flex: 2, child: menuWidget),
              ],
            );
          }
        },
      ),
    );
  }
}

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        // Turn Status
        BlocBuilder<ChessCubit, ChessState>(
          builder: (context, state) {
            final isWhiteTurn = state.game.turn == ch.Color.WHITE;

            if (state.game.in_checkmate) {
              return Text(
                '¡Jaque Mate!\nGanan las ${isWhiteTurn ? 'Negras' : 'Blancas'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              );
            }

            if (state.game.in_check) {
              return const Text(
                '¡Jaque!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
              );
            }

            return Text(
              'Turno: ${isWhiteTurn ? 'Blancas' : 'Negras'}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            );
          },
        ),
        const Divider(height: 48),

        // Player Color Selector
        const Text('Jugar como:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        BlocBuilder<ChessCubit, ChessState>(
          builder: (context, state) {
            return SegmentedButton<ch.Color>(
              segments: const [
                ButtonSegment(value: ch.Color.WHITE, label: Text('Blancas')),
                ButtonSegment(value: ch.Color.BLACK, label: Text('Negras')),
              ],
              selected: {state.playerColor},
              onSelectionChanged: (Set<ch.Color> newSelection) {
                context.read<ChessCubit>().setPlayerColor(newSelection.first);
              },
            );
          },
        ),
        
        const Divider(height: 48),

        // PGN History
        const Text('Historial de Jugadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: BlocBuilder<ChessCubit, ChessState>(
              builder: (context, state) {
                if (state.game.history.isEmpty) {
                  return const Text('Aún no hay jugadas.', style: TextStyle(color: Colors.grey));
                }
                return SingleChildScrollView(
                  child: Text(
                    state.game.pgn(),
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
