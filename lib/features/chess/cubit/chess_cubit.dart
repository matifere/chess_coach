import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chess/chess.dart' as ch;
import 'chess_state.dart';
import 'package:chess_coach/src/rust/api/simple.dart' as rust_api;

class ChessCubit extends Cubit<ChessState> {
  ChessCubit() : super(ChessState(game: ch.Chess()));

  void onSquareTapped(String square) {
    if (state.pendingPromotion != null || _isGameOver()) return;
    if (state.game.turn != state.playerColor) return; // Turno del bot

    if (state.selectedSquare != null) {
      if (state.legalMoveDestinations.contains(square)) {
        final piece = state.game.get(state.selectedSquare!);
        if (piece != null &&
            piece.type == ch.PieceType.PAWN &&
            (square[1] == '8' || square[1] == '1')) {
          emit(
            state.copyWith(
              pendingPromotion: {'from': state.selectedSquare!, 'to': square},
            ),
          );
        } else {
          _makeMove(state.selectedSquare!, square);
        }
        return;
      }

      if (state.selectedSquare == square) {
        emit(state.copyWith(clearSelection: true));
        return;
      }
    }

    final piece = state.game.get(square);
    if (piece != null && piece.color == state.game.turn) {
      _selectSquare(square);
    } else {
      emit(state.copyWith(clearSelection: true));
    }
  }

  void onDraggedMove(String from, String to) {
    if (state.pendingPromotion != null || _isGameOver()) return;
    if (from == to) return; 
    if (state.game.turn != state.playerColor) return; // Turno del bot

    final moves = state.game.generate_moves({'square': from});
    final destinations = moves.map((m) => m.toAlgebraic).toList();

    if (destinations.contains(to)) {
      final piece = state.game.get(from);
      if (piece != null &&
          piece.type == ch.PieceType.PAWN &&
          (to[1] == '8' || to[1] == '1')) {
        emit(state.copyWith(pendingPromotion: {'from': from, 'to': to}));
      } else {
        _makeMove(from, to);
      }
    } else {
      emit(state.copyWith(clearSelection: true));
    }
  }

  void _selectSquare(String square) {
    final moves = state.game.generate_moves({'square': square});
    final destinations = moves.map((m) => m.toAlgebraic).toList();

    emit(
      state.copyWith(
        selectedSquare: square,
        legalMoveDestinations: destinations,
      ),
    );
  }

  void _makeMove(String from, String to, {String? promotion, bool isBotMove = false}) {
    final newGame = ch.Chess.fromFEN(state.game.fen);

    Map<String, dynamic> moveObj = {'from': from, 'to': to};
    if (promotion != null) {
      moveObj['promotion'] = promotion;
    } else if (newGame.get(from)?.type == ch.PieceType.PAWN &&
        (to[1] == '8' || to[1] == '1')) {
      moveObj['promotion'] = 'q'; 
    }

    final moveSuccess = newGame.move(moveObj);

    if (moveSuccess) {
      // Simulación de evaluación del Coach (reemplazaremos con analyze_position pronto)
      final qualities = MoveQuality.values;
      final randomQuality = qualities[Random().nextInt(qualities.length)];

      emit(
        state.copyWith(
          game: newGame,
          clearSelection: true,
          clearPendingPromotion: true,
          lastMoveFeedback: {
            'from': from,
            'to': to,
            'quality': randomQuality,
          },
        ),
      );

      if (!isBotMove && newGame.turn != state.playerColor && !_isGameOver()) {
        _triggerBotMove();
      }
    }
  }

  Future<void> _triggerBotMove() async {
    if (state.game.turn == state.playerColor || _isGameOver()) return;

    // Pequeña pausa visual para que no sea automático
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (state.game.turn == state.playerColor || _isGameOver()) return;

    final fen = state.game.fen;
    
    // Depth 3 para rapidez, luego lo movemos a un isolate
    final uciMove = rust_api.getBestMove(fen: fen, depth: 3);

    if (uciMove.isNotEmpty && uciMove.length >= 4) {
      final from = uciMove.substring(0, 2);
      final to = uciMove.substring(2, 4);
      String? promotion;
      if (uciMove.length == 5) {
        promotion = uciMove.substring(4, 5);
      }

      // Asegurar que no se reinició en medio
      if (state.game.fen == fen) {
        _makeMove(from, to, promotion: promotion, isBotMove: true);
      }
    }
  }

  void executePromotion(String promotionPiece) {
    if (state.pendingPromotion != null) {
      _makeMove(
        state.pendingPromotion!['from']!,
        state.pendingPromotion!['to']!,
        promotion: promotionPiece,
      );
    }
  }

  void cancelPromotion() {
    emit(state.copyWith(clearPendingPromotion: true, clearSelection: true));
  }

  void setPlayerColor(ch.Color color) {
    emit(state.copyWith(playerColor: color));
    if (state.game.turn != color && !_isGameOver()) {
      _triggerBotMove();
    }
  }

  void resign() {
    if (_isGameOver()) return;
    emit(state.copyWith(resignedPlayer: state.playerColor));
  }

  void resetGame() {
    emit(ChessState(game: ch.Chess(), playerColor: state.playerColor));
    if (state.playerColor == ch.Color.BLACK) {
      _triggerBotMove();
    }
  }

  bool _isGameOver() {
    return state.game.in_checkmate ||
        state.game.in_draw ||
        state.resignedPlayer != null;
  }
}
