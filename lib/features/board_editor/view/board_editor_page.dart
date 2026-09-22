import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../cubit/board_editor_cubit.dart';
import '../cubit/board_editor_state.dart';

class BoardEditorPage extends StatelessWidget {
  final String initialFen;

  const BoardEditorPage({super.key, required this.initialFen});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BoardEditorCubit(initialFen),
      child: const _BoardEditorView(),
    );
  }
}

class _BoardEditorView extends StatelessWidget {
  const _BoardEditorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Posición'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              final fen = context.read<BoardEditorCubit>().state.toFen();
              Navigator.pop(context, fen);
            },
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;
          
          final boardWidget = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? constraints.maxHeight : double.infinity,
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: EditorBoardWidget(),
              ),
            ),
          );

          final toolsWidget = const EditorToolsWidget();

          if (isDesktop) {
            return Row(
              children: [
                Expanded(flex: 3, child: boardWidget),
                Container(
                  width: 300,
                  color: Colors.grey[100],
                  child: toolsWidget,
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(child: boardWidget),
                toolsWidget,
              ],
            );
          }
        },
      ),
    );
  }
}

class EditorBoardWidget extends StatelessWidget {
  const EditorBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardEditorCubit, BoardEditorState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double boardSize = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

            final squareSize = boardSize / 8;

            final boardGrid = Column(
              children: List.generate(8, (rowIdx) {
                final rank = 8 - rowIdx;

                return Expanded(
                  child: Row(
                    children: List.generate(8, (colIdx) {
                      final fileIndex = colIdx;
                      final file = String.fromCharCode('a'.codeUnitAt(0) + fileIndex);
                      final squareId = '$file$rank';

                      final isLightSquare = (rank + fileIndex) % 2 == 0;
                      final color = isLightSquare ? Colors.amber[200] : Colors.brown[600];
                      final piece = state.board[squareId];

                      return Expanded(
                        child: DragTarget<Object>(
                          onWillAcceptWithDetails: (details) => true,
                          onAcceptWithDetails: (details) {
                            final data = details.data;
                            if (data is EditorPiece) {
                              // From palette
                              context.read<BoardEditorCubit>().placePiece(squareId, data);
                            } else if (data is String) {
                              // From another square
                              context.read<BoardEditorCubit>().movePiece(data, squareId);
                            }
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              color: color,
                              child: piece != null
                                  ? Draggable<String>(
                                      data: squareId,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: SizedBox(
                                          width: squareSize * 1.5,
                                          height: squareSize * 1.5,
                                          child: SvgPicture.asset('assets/pieces/${piece.color}${piece.type.toUpperCase()}.svg'),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.3,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: SvgPicture.asset('assets/pieces/${piece.color}${piece.type.toUpperCase()}.svg'),
                                        ),
                                      ),
                                      onDragCompleted: () {
                                        // Handled in movePiece
                                      },
                                      onDraggableCanceled: (velocity, offset) {
                                        // Dragged off board
                                        context.read<BoardEditorCubit>().removePiece(squareId);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: SvgPicture.asset('assets/pieces/${piece.color}${piece.type.toUpperCase()}.svg'),
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                      );
                    }),
                  ),
                );
              }),
            );

            return DragTarget<String>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                // If dropped outside the 8x8 grid but inside the board container
                context.read<BoardEditorCubit>().removePiece(details.data);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: boardSize,
                  height: boardSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown[800]!, width: 2),
                  ),
                  child: boardGrid,
                );
              },
            );
          },
        );
      },
    );
  }
}

class EditorToolsWidget extends StatelessWidget {
  const EditorToolsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Piezas (Arrastra al tablero)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildPiecePalette('w'),
          const SizedBox(height: 8),
          _buildPiecePalette('b'),
          const Divider(height: 32),
          const Text('Juegan:', style: TextStyle(fontWeight: FontWeight.bold)),
          BlocBuilder<BoardEditorCubit, BoardEditorState>(
            builder: (context, state) {
              return SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'w', label: Text('Blancas')),
                  ButtonSegment(value: 'b', label: Text('Negras')),
                ],
                selected: {state.turn},
                onSelectionChanged: (Set<String> newSelection) {
                  context.read<BoardEditorCubit>().setTurn(newSelection.first);
                },
              );
            },
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => context.read<BoardEditorCubit>().clearBoard(),
                child: const Text('Limpiar'),
              ),
              OutlinedButton(
                onPressed: () => context.read<BoardEditorCubit>().setInitialPosition(),
                child: const Text('Inicial'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Arrastra piezas fuera del tablero para eliminarlas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPiecePalette(String color) {
    final pieces = ['k', 'q', 'r', 'b', 'n', 'p'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: pieces.map((type) {
        final piece = EditorPiece(color: color, type: type);
        return Draggable<EditorPiece>(
          data: piece,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 50,
              height: 50,
              child: SvgPicture.asset('assets/pieces/$color${type.toUpperCase()}.svg'),
            ),
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: SvgPicture.asset('assets/pieces/$color${type.toUpperCase()}.svg'),
          ),
        );
      }).toList(),
    );
  }
}
