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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = constraints.maxWidth;
                final squareSize = boardSize / 8;
                final isWhiteView = state.playerColor == ch.Color.WHITE;

                final boardGrid = Column(
                  children: List.generate(8, (rowIdx) {
                    final rank = isWhiteView ? 8 - rowIdx : 1 + rowIdx;
                    
                    return Expanded(
                      child: Row(
                        children: List.generate(8, (colIdx) {
                          final fileIndex = isWhiteView ? colIdx : 7 - colIdx;
                          final file = String.fromCharCode('a'.codeUnitAt(0) + fileIndex);
                          final squareId = '$file$rank';

                          final isLightSquare = (rank + fileIndex) % 2 == 0;
                          final color = isLightSquare ? Colors.amber[200] : Colors.brown[600];

                          final isSelected = state.selectedSquare == squareId;
                          final isLegalMove = state.legalMoveDestinations.contains(squareId);
                          final piece = state.game.get(squareId);
                          
                          return Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final currentSquareSize = constraints.maxWidth;
                                
                                return DragTarget<String>(
                                  onWillAcceptWithDetails: (details) => true,
                                  onAcceptWithDetails: (details) {
                                    context.read<ChessCubit>().onDraggedMove(details.data, squareId);
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    return GestureDetector(
                                      onTap: () => context.read<ChessCubit>().onSquareTapped(squareId),
                                      child: Container(
                                        color: isSelected 
                                            ? Colors.blue.withValues(alpha:0.8)
                                            : isLegalMove 
                                                ? Colors.green.withValues(alpha:0.5)
                                                : color,
                                        child: Stack(
                                          children: [
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
                                            
                                            if (piece != null)
                                              Positioned.fill(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: piece.color == state.game.turn
                                                      ? Draggable<String>(
                                                          data: squareId,
                                                          onDragStarted: () {
                                                            context.read<ChessCubit>().onSquareTapped(squareId);
                                                          },
                                                          feedback: Material(
                                                            color: Colors.transparent,
                                                            child: SizedBox(
                                                              width: currentSquareSize,
                                                              height: currentSquareSize,
                                                              child: Padding(
                                                                padding: const EdgeInsets.all(4.0),
                                                                child: _getPieceWidget(piece),
                                                              ),
                                                            ),
                                                          ),
                                                          childWhenDragging: Opacity(
                                                            opacity: 0.2,
                                                            child: _getPieceWidget(piece),
                                                          ),
                                                          child: _getPieceWidget(piece),
                                                        )
                                                      : _getPieceWidget(piece),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                );

                Widget? promotionOverlay;
                if (state.pendingPromotion != null) {
                  final to = state.pendingPromotion!['to']!;
                  final turn = state.game.turn;
                  final colorPrefix = turn == ch.Color.WHITE ? 'w' : 'b';

                  int fileVal = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
                  int rankVal = int.parse(to[1]);
                  
                  int fileIndex = isWhiteView ? fileVal : 7 - fileVal;
                  int rankIndex = isWhiteView ? 8 - rankVal : rankVal - 1;

                  bool isTop = rankIndex == 0;
                  double top = isTop ? 0 : boardSize - (4 * squareSize);
                  List<String> pieces = isTop ? ['q', 'r', 'b', 'n'] : ['n', 'b', 'r', 'q'];

                  promotionOverlay = Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => context.read<ChessCubit>().cancelPromotion(),
                          child: Container(color: Colors.black.withValues(alpha: 0.2)),
                        ),
                      ),
                      Positioned(
                        left: fileIndex * squareSize,
                        top: top,
                        width: squareSize,
                        height: squareSize * 4,
                        child: Material(
                          elevation: 12,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: pieces.map((p) => Expanded(
                              child: GestureDetector(
                                onTap: () => context.read<ChessCubit>().executePromotion(p),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.black12)),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: SvgPicture.asset('assets/pieces/$colorPrefix${p.toUpperCase()}.svg'),
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Stack(
                  children: [
                    boardGrid,
                    ?promotionOverlay,
                  ],
                );
              },
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
