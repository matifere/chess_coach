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
    return BlocProvider(create: (_) => ChessCubit(), child: const ChessView());
  }
}

class ChessView extends StatelessWidget {
  const ChessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chess Coach'), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          final boardWidget = Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? constraints.maxHeight : double.infinity,
                ),
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
                    border: const Border(
                      left: BorderSide(color: Colors.black12, width: 1),
                    ),
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
            if (state.resignedPlayer != null) {
              final winner = state.resignedPlayer == ch.Color.WHITE
                  ? 'Negras'
                  : 'Blancas';
              final loser = state.resignedPlayer == ch.Color.WHITE
                  ? 'Blancas'
                  : 'Negras';
              return Text(
                '¡$loser abandonaron!\nGanan las $winner',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              );
            }

            final isWhiteTurn = state.game.turn == ch.Color.WHITE;

            if (state.game.in_checkmate) {
              return Text(
                '¡Jaque Mate!\nGanan las ${isWhiteTurn ? 'Negras' : 'Blancas'}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              );
            }

            if (state.game.in_draw) {
              return const Text(
                '¡Empate!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              );
            }

            if (state.game.in_check) {
              return const Text(
                '¡Jaque!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              );
            }

            return Text(
              'Turno: ${isWhiteTurn ? 'Blancas' : 'Negras'}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            );
          },
        ),
        BlocBuilder<ChessCubit, ChessState>(
          buildWhen: (p, c) => p.lastMoveFeedback?['openingName'] != c.lastMoveFeedback?['openingName'],
          builder: (context, state) {
            final opening = state.lastMoveFeedback?['openingName'] as String?;
            if (opening != null && opening.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                child: Text(
                  opening,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.brown,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const Divider(height: 32),

        // Player Color Selector
        const Text(
          'Jugar como:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
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

        const SizedBox(height: 24),
        
        // Selector de Elo
        BlocBuilder<ChessCubit, ChessState>(
          buildWhen: (previous, current) => 
              previous.botElo != current.botElo ||
              previous.game.history.isEmpty != current.game.history.isEmpty,
          builder: (context, state) {
            final isGameActive = state.game.history.isNotEmpty;
            return Column(
              children: [
                Text(
                  'Nivel del Bot: ${state.botElo} Elo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isGameActive ? Colors.grey : Colors.black,
                  ),
                ),
                Slider(
                  value: state.botElo.toDouble(),
                  min: 600,
                  max: 2200,
                  divisions: 160,
                  label: '${state.botElo} Elo',
                  onChanged: isGameActive 
                    ? null 
                    : (value) {
                        context.read<ChessCubit>().setBotElo(value.toInt());
                      },
                ),
                if (isGameActive)
                  const Text(
                    '(Fijado durante la partida)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            );
          },
        ),

        const Divider(height: 32),

        // PGN History
        const Text(
          'Historial de Jugadas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
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
                  return const Text(
                    'Aún no hay jugadas.',
                    style: TextStyle(color: Colors.grey),
                  );
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

        // Acciones (Abandonar / Nueva Partida)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: BlocBuilder<ChessCubit, ChessState>(
            builder: (context, state) {
              final isGameOver =
                  state.game.in_checkmate ||
                  state.game.in_draw ||
                  state.resignedPlayer != null;

              if (isGameOver) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<ChessCubit>().resetGame(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Nueva Partida'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              }

              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showResignDialog(context),
                  icon: const Icon(Icons.flag),
                  label: const Text('Abandonar Partida'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showResignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Abandonar partida?'),
          content: const Text(
            'Si abandonas, la partida terminará y tu oponente ganará.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<ChessCubit>().resign();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Abandonar'),
            ),
          ],
        );
      },
    );
  }
}
