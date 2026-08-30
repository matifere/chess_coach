import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chess/chess.dart' as ch;
import 'chess_state.dart';

class ChessCubit extends Cubit<ChessState> {
  ChessCubit() : super(ChessState(game: ch.Chess()));

  void onSquareTapped(String square) {
    // Si estamos esperando promoción o la partida terminó, ignoramos toques
    if (state.pendingPromotion != null || _isGameOver()) return;

    // Si ya hay un cuadro seleccionado, intentamos mover
    if (state.selectedSquare != null) {
      if (state.legalMoveDestinations.contains(square)) {
        // Chequear si es un movimiento de promoción (peón llegando a última fila)
        final piece = state.game.get(state.selectedSquare!);
        if (piece != null && piece.type == ch.PieceType.PAWN && (square[1] == '8' || square[1] == '1')) {
          emit(state.copyWith(pendingPromotion: {'from': state.selectedSquare!, 'to': square}));
        } else {
          _makeMove(state.selectedSquare!, square);
        }
        return;
      }
      
      // Si toca el mismo cuadro, deseleccionamos
      if (state.selectedSquare == square) {
        emit(state.copyWith(clearSelection: true));
        return;
      }
    }

    // Seleccionamos un nuevo cuadro (si hay una pieza nuestra ahí)
    final piece = state.game.get(square);
    if (piece != null && piece.color == state.game.turn) {
      _selectSquare(square);
    } else {
      // Si tocamos un lugar inválido, limpiamos
      emit(state.copyWith(clearSelection: true));
    }
  }

  void onDraggedMove(String from, String to) {
    if (state.pendingPromotion != null || _isGameOver()) return;
    if (from == to) return; // Ignorar si se suelta en la misma casilla

    final moves = state.game.generate_moves({'square': from});
    final destinations = moves.map((m) => m.toAlgebraic).toList();

    if (destinations.contains(to)) {
      final piece = state.game.get(from);
      if (piece != null && piece.type == ch.PieceType.PAWN && (to[1] == '8' || to[1] == '1')) {
        emit(state.copyWith(pendingPromotion: {'from': from, 'to': to}));
      } else {
        _makeMove(from, to);
      }
    } else {
      emit(state.copyWith(clearSelection: true));
    }
  }

  void _selectSquare(String square) {
    // Generamos los movimientos legales para ese cuadro
    final moves = state.game.generate_moves({'square': square});
    final destinations = moves.map((m) => m.toAlgebraic).toList();

    emit(state.copyWith(
      selectedSquare: square,
      legalMoveDestinations: destinations,
    ));
  }

  void _makeMove(String from, String to, {String? promotion}) {
    // Copiamos el juego para que Bloc detecte el cambio con Equatable
    final newGame = ch.Chess.fromFEN(state.game.fen);
    
    // Armamos el movimiento
    Map<String, dynamic> moveObj = {'from': from, 'to': to};
    if (promotion != null) {
      moveObj['promotion'] = promotion;
    } else if (newGame.get(from)?.type == ch.PieceType.PAWN && (to[1] == '8' || to[1] == '1')) {
      moveObj['promotion'] = 'q'; // fallback por si acaso
    }

    final moveSuccess = newGame.move(moveObj);
    
    if (moveSuccess) {
      emit(state.copyWith(
        game: newGame,
        clearSelection: true,
        clearPendingPromotion: true,
      ));
    }
  }

  void executePromotion(String promotionPiece) {
    if (state.pendingPromotion != null) {
      _makeMove(state.pendingPromotion!['from']!, state.pendingPromotion!['to']!, promotion: promotionPiece);
    }
  }

  void cancelPromotion() {
    emit(state.copyWith(clearPendingPromotion: true, clearSelection: true));
  }

  void setPlayerColor(ch.Color color) {
    emit(state.copyWith(playerColor: color));
  }

  void resign() {
    if (_isGameOver()) return;
    emit(state.copyWith(resignedPlayer: state.playerColor));
  }

  void resetGame() {
    emit(ChessState(
      game: ch.Chess(),
      playerColor: state.playerColor,
    ));
  }

  bool _isGameOver() {
    return state.game.in_checkmate || state.game.in_draw || state.resignedPlayer != null;
  }
}
