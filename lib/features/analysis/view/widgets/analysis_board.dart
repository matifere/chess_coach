import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../cubit/analysis_cubit.dart';
import '../../cubit/analysis_state.dart';
import '../../../chess/view/widgets/eval_bar.dart';
import 'package:chess/chess.dart' as ch;

class AnalysisBoard extends StatelessWidget {
  final bool isWhiteView;

  const AnalysisBoard({super.key, this.isWhiteView = true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalysisCubit, AnalysisState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            final double availableHeight = constraints.maxHeight;
            
            double maxBoardWidth = availableWidth - 32;
            if (maxBoardWidth < 0) maxBoardWidth = 0;
            
            double boardSize = maxBoardWidth;
            if (availableHeight != double.infinity && availableHeight < boardSize) {
              boardSize = availableHeight;
            }

            final squareSize = boardSize / 8;

            final boardGrid = Column(
              children: List.generate(8, (rowIdx) {
                final rank = isWhiteView ? 8 - rowIdx : 1 + rowIdx;

                return Expanded(
                  child: Row(
                    children: List.generate(8, (colIdx) {
                      final fileIndex = isWhiteView ? colIdx : 7 - colIdx;
                      final file = String.fromCharCode(
                        'a'.codeUnitAt(0) + fileIndex,
                      );
                      final squareId = '$file$rank';

                      final isLightSquare = (rank + fileIndex) % 2 == 0;
                      final color = isLightSquare
                          ? Colors.amber[200]
                          : Colors.brown[600];

                      final isSelected = state.selectedSquare == squareId;
                      final isLegalMove = state.legalMoveDestinations
                          .contains(squareId);
                      final piece = state.game.get(squareId);
                      final hasPieceToCapture = piece != null && piece.color != state.game.turn;

                      // Move highlight for best move (from stockfish pv)
                      bool isBestMove = false;
                      if (state.bestMove != null && state.bestMove!.length >= 4) {
                        final bestFrom = state.bestMove!.substring(0, 2);
                        final bestTo = state.bestMove!.substring(2, 4);
                        if (squareId == bestFrom || squareId == bestTo) {
                          isBestMove = true;
                        }
                      }
                      
                      Color finalColor = color!;
                      if (isSelected) {
                        finalColor = Colors.blue.withValues(alpha:0.8);
                      } else if (isLegalMove) {
                        finalColor = Colors.green.withValues(alpha:0.5);
                      } else if (isBestMove) {
                        finalColor = Color.lerp(color, Colors.blue[300], 0.6)!;
                      }

                      return Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final currentSquareSize = constraints.maxWidth;

                            return DragTarget<String>(
                              onWillAcceptWithDetails: (details) => true,
                              onAcceptWithDetails: (details) { 
                                HapticFeedback.mediumImpact();
                                context.read<AnalysisCubit>().onDraggedMove(
                                  details.data,
                                  squareId,
                                );
                              },
                              builder: (context, candidateData, rejectedData) {
                                return GestureDetector(
                                  onTap: () { 
                                    HapticFeedback.lightImpact(); 
                                    context.read<AnalysisCubit>().onSquareTapped(squareId); 
                                  },
                                  child: Container(
                                    color: finalColor,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        if (isLegalMove)
                                          Positioned.fill(
                                            child: TweenAnimationBuilder<double>(
                                              tween: Tween<double>(begin: 0.0, end: 1.0),
                                              duration: const Duration(milliseconds: 150),
                                              curve: Curves.easeOutBack,
                                              builder: (context, scale, child) {
                                                return Transform.scale(
                                                  scale: scale,
                                                  child: FractionallySizedBox(
                                                    widthFactor: hasPieceToCapture ? 0.9 : 0.3,
                                                    heightFactor: hasPieceToCapture ? 0.9 : 0.3,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: hasPieceToCapture 
                                                            ? Colors.transparent 
                                                            : Colors.black.withValues(alpha: 0.2),
                                                        shape: BoxShape.circle,
                                                        border: hasPieceToCapture 
                                                            ? Border.all(color: Colors.black.withValues(alpha: 0.2), width: 6)
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                        if (piece != null)
                                          Positioned.fill(
                                            child: Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: _buildAnimatedPiece(
                                                context,
                                                state,
                                                squareId,
                                                piece,
                                                currentSquareSize,
                                                isWhiteView,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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
              List<String> pieces = isTop
                  ? ['q', 'r', 'b', 'n']
                  : ['n', 'b', 'r', 'q'];

              promotionOverlay = Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () =>
                          context.read<AnalysisCubit>().cancelPromotion(),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
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
                        children: pieces
                            .map(
                              (p) => Expanded(
                                child: GestureDetector(
                                  onTap: () { 
                                    HapticFeedback.lightImpact(); 
                                    context.read<AnalysisCubit>().executePromotion(p); 
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.black12,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: SvgPicture.asset(
                                      'assets/pieces/$colorPrefix${p.toUpperCase()}.svg',
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: boardSize,
                  child: EvalBarWidget(
                    eval: state.currentEval,
                    isWhiteView: isWhiteView,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: boardSize,
                  height: boardSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown[800]!, width: 2),
                  ),
                  child: Stack(children: [boardGrid, if (promotionOverlay != null) promotionOverlay]),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedPiece(
    BuildContext context,
    AnalysisState state,
    String squareId,
    ch.Piece piece,
    double currentSquareSize,
    bool isWhiteView,
  ) {
    Widget pieceWidget = piece.color == state.game.turn
        ? Draggable<String>(
            data: squareId,
            onDragStarted: () {
              HapticFeedback.lightImpact();
              context.read<AnalysisCubit>().onSquareTapped(squareId);
            },
            feedback: Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 1.3,
                child: SizedBox(
                  width: currentSquareSize,
                  height: currentSquareSize,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          )
                        ],
                        shape: BoxShape.circle,
                      ),
                      child: _getPieceWidget(piece),
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.2,
              child: _getPieceWidget(piece),
            ),
            child: _getPieceWidget(piece),
          )
        : _getPieceWidget(piece);

    return pieceWidget;
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
