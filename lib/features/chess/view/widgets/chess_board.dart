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

                          // Historial y Coach Feedback
                          final isLastMoveFrom = state.lastMoveFeedback?['from'] == squareId;
                          final isLastMoveTo = state.lastMoveFeedback?['to'] == squareId;
                          final isLastMove = isLastMoveFrom || isLastMoveTo;
                          final moveQuality = isLastMoveTo ? (state.lastMoveFeedback?['quality'] as MoveQuality?) : null;

                          Color finalColor = color!;
                          if (isSelected) {
                            finalColor = Colors.blue.withValues(alpha:0.8);
                          } else if (isLegalMove) {
                            finalColor = Colors.green.withValues(alpha:0.5);
                          } else if (isLastMove) {
                            finalColor = Color.lerp(color, Colors.yellow[600], 0.4)!;
                          }

                          return Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final currentSquareSize = constraints.maxWidth;

                                return DragTarget<String>(
                                  onWillAcceptWithDetails: (details) => true,
                                  onAcceptWithDetails: (details) {
                                    context.read<ChessCubit>().onDraggedMove(
                                      details.data,
                                      squareId,
                                    );
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    return GestureDetector(
                                      onTap: () => context
                                          .read<ChessCubit>()
                                          .onSquareTapped(squareId),
                                      child: Container(
                                        color: finalColor,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            if (isLegalMove)
                                              Center(
                                                child: FractionallySizedBox(
                                                  widthFactor: 0.3,
                                                  heightFactor: 0.3,
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.black26,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
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
                                              
                                            if (moveQuality != null)
                                              Positioned(
                                                top: -4,
                                                right: -4,
                                                child: MoveQualityBadge(quality: moveQuality),
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
                              context.read<ChessCubit>().cancelPromotion(),
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
                                      onTap: () => context
                                          .read<ChessCubit>()
                                          .executePromotion(p),
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

                return Stack(children: [boardGrid, ?promotionOverlay]);
              },
            ),
          ),
        );
      },
    );
  }

  int _getColIdx(String sq, bool isWhiteView) {
    int file = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    return isWhiteView ? file : 7 - file;
  }

  int _getRowIdx(String sq, bool isWhiteView) {
    int rank = int.parse(sq[1]);
    return isWhiteView ? 8 - rank : rank - 1;
  }

  Widget _buildAnimatedPiece(
    BuildContext context,
    ChessState state,
    String squareId,
    ch.Piece piece,
    double currentSquareSize,
    bool isWhiteView,
  ) {
    Widget pieceWidget = piece.color == state.game.turn
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
        : _getPieceWidget(piece);

    final wasDragged = state.lastMoveFeedback?['wasDragged'] == true;
    if (!wasDragged && state.lastMoveFeedback != null) {
      String? animFrom;
      String? animTo;

      if (state.lastMoveFeedback!['to'] == squareId) {
        animFrom = state.lastMoveFeedback!['from'];
        animTo = squareId;
      } else if (state.lastMoveFeedback!['secondaryMove']?['to'] == squareId) {
        animFrom = state.lastMoveFeedback!['secondaryMove']!['from'];
        animTo = squareId;
      }

      if (animFrom != null && animTo != null) {
        int colFrom = _getColIdx(animFrom, isWhiteView);
        int rowFrom = _getRowIdx(animFrom, isWhiteView);
        int colTo = _getColIdx(animTo, isWhiteView);
        int rowTo = _getRowIdx(animTo, isWhiteView);

        double dx = (colFrom - colTo) * currentSquareSize;
        double dy = (rowFrom - rowTo) * currentSquareSize;

        return TweenAnimationBuilder<Offset>(
          key: ValueKey('${state.game.fen}_${animFrom}_$animTo'),
          tween: Tween<Offset>(begin: Offset(dx, dy), end: Offset.zero),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) {
            return Transform.translate(
              offset: offset,
              child: child,
            );
          },
          child: pieceWidget,
        );
      }
    }

    return pieceWidget;
  }

  Widget _getPieceWidget(ch.Piece piece) {
    final colorPrefix = piece.color == ch.Color.WHITE ? 'w' : 'b';
    String typeStr = '';
    switch (piece.type) {
      case ch.PieceType.KING:
        typeStr = 'K';
        break;
      case ch.PieceType.QUEEN:
        typeStr = 'Q';
        break;
      case ch.PieceType.ROOK:
        typeStr = 'R';
        break;
      case ch.PieceType.BISHOP:
        typeStr = 'B';
        break;
      case ch.PieceType.KNIGHT:
        typeStr = 'N';
        break;
      case ch.PieceType.PAWN:
        typeStr = 'P';
        break;
    }
    return SvgPicture.asset(
      'assets/pieces/$colorPrefix$typeStr.svg',
      fit: BoxFit.contain,
    );
  }
}

class MoveQualityBadge extends StatelessWidget {
  final MoveQuality quality;
  const MoveQualityBadge({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String text;
    IconData? icon;

    switch (quality) {
      case MoveQuality.brilliant: bgColor = Colors.cyan; text = '!!'; break;
      case MoveQuality.great: bgColor = Colors.indigoAccent; text = '!'; break;
      case MoveQuality.best: bgColor = Colors.green; icon = Icons.star; text = ''; break;
      case MoveQuality.excellent: bgColor = Colors.green; text = '✓'; break;
      case MoveQuality.good: bgColor = Colors.green[300]!; text = '👍'; break;
      case MoveQuality.inaccuracy: bgColor = Colors.amber; text = '?!'; break;
      case MoveQuality.mistake: bgColor = Colors.orange; text = '?'; break;
      case MoveQuality.blunder: bgColor = Colors.red; text = '??'; break;
      case MoveQuality.book: bgColor = Colors.brown; icon = Icons.menu_book; text = ''; break;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))
        ]
      ),
      alignment: Alignment.center,
      child: icon != null 
          ? Icon(icon, size: 12, color: Colors.white)
          : Text(
              text, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 10, 
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
    );
  }
}
