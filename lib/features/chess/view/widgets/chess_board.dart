import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../cubit/chess_cubit.dart';
import '../../cubit/chess_state.dart';
import 'package:chess/chess.dart' as ch;

class ChessBoard extends StatelessWidget {
  const ChessBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChessCubit, ChessState>(
      builder: (context, state) {
        return AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.brown[800]!, width: 2),
            ),
            child: Column(
              children: List.generate(8, (rowIdx) {
                final isWhiteView = state.playerColor == ch.Color.WHITE;
                final rank = isWhiteView ? 8 - rowIdx : 1 + rowIdx;
                
                return Expanded(
                  child: Row(
                    children: List.generate(8, (colIdx) {
                      final fileIndex = isWhiteView ? colIdx : 7 - colIdx;
                      final file = String.fromCharCode('a'.codeUnitAt(0) + fileIndex);
                      final squareId = '$file$rank';

                      // a1 (rank=1, file=0) is dark. 1+0 = 1 (odd).
                      // h1 (rank=1, file=7) is light. 1+7 = 8 (even).
                      final isLightSquare = (rank + fileIndex) % 2 == 0;
                      final color = isLightSquare ? Colors.amber[200] : Colors.brown[600];

                      final isSelected = state.selectedSquare == squareId;
                      final isLegalMove = state.legalMoveDestinations.contains(squareId);

                      // Obtenemos la pieza
                      final piece = state.game.get(squareId);
                      
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => context.read<ChessCubit>().onSquareTapped(squareId),
                          child: Container(
                            color: isSelected 
                                ? Colors.blue.withValues(alpha:0.8)
                                : isLegalMove 
                                    ? Colors.green.withValues(alpha:0.5)
                                    : color,
                            child: Stack(
                              children: [
                                // Pequeña marca para cuadros de destino legal
                                if (isLegalMove)
                                  Center(
                                    child: FractionallySizedBox(
                                      widthFactor: 0.3,
                                      heightFactor: 0.3,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black26,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Renderizamos la pieza si existe
                                if (piece != null)
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: _getPieceWidget(piece),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _getPieceWidget(ch.Piece piece) {
    final colorPrefix = piece.color == ch.Color.WHITE ? 'w' : 'b';
    String typeStr = '';
    switch (piece.type) {
      case ch.PieceType.KING: typeStr = 'K'; break;
      case ch.PieceType.QUEEN: typeStr = 'Q'; break;
      case ch.PieceType.ROOK: typeStr = 'R'; break;
      case ch.PieceType.BISHOP: typeStr = 'B'; break;
      case ch.PieceType.KNIGHT: typeStr = 'N'; break;
      case ch.PieceType.PAWN: typeStr = 'P'; break;
    }
    return SvgPicture.asset(
      'assets/pieces/$colorPrefix$typeStr.svg',
      fit: BoxFit.contain,
    );
  }
}
