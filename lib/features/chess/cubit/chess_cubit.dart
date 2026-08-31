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
        _makeMove(from, to, wasDragged: true);
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

  void _makeMove(String from, String to, {String? promotion, bool isBotMove = false, bool wasDragged = false}) {
    final newGame = ch.Chess.fromFEN(state.game.fen);

    // Detectar enroque para animar la torre también
    final piece = newGame.get(from);
    Map<String, String>? secondaryMove;
    if (piece != null && piece.type == ch.PieceType.KING) {
      int fileFrom = from.codeUnitAt(0);
      int fileTo = to.codeUnitAt(0);
      if ((fileFrom - fileTo).abs() == 2) {
        String rank = from[1];
        if (fileTo > fileFrom) {
          secondaryMove = {'from': 'h$rank', 'to': 'f$rank'};
        } else {
          secondaryMove = {'from': 'a$rank', 'to': 'd$rank'};
        }
      }
    }

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
            'wasDragged': wasDragged,
            if (secondaryMove != null) 'secondaryMove': secondaryMove,
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
    
    // Mapeamos el Elo a profundidad de búsqueda (Depth 1 a 4)
    // 600 -> 1, 1000 -> 2, 1400 -> 3, 1800+ -> 4
    int depth = (state.botElo / 450).floor(); 
    if (depth < 1) depth = 1;
    if (depth > 4) depth = 4;

    final uciMove = rust_api.getBestMove(fen: fen, depth: depth);

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

  void setBotElo(int elo) {
    emit(state.copyWith(botElo: elo));
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
