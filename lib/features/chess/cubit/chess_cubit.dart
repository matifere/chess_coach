import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chess/chess.dart' as ch;
import 'chess_state.dart';

class ChessCubit extends Cubit<ChessState> {
  ChessCubit() : super(ChessState(game: ch.Chess()));

  void onSquareTapped(String square) {
    // Si ya hay un cuadro seleccionado, intentamos mover
    if (state.selectedSquare != null) {
      if (state.legalMoveDestinations.contains(square)) {
        _makeMove(state.selectedSquare!, square);
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

  void _selectSquare(String square) {
    // Generamos los movimientos legales para ese cuadro
    final moves = state.game.generate_moves({'square': square});
    final destinations = moves.map((m) => m.toAlgebraic).toList();

    emit(state.copyWith(
      selectedSquare: square,
      legalMoveDestinations: destinations,
    ));
  }

  void _makeMove(String from, String to) {
    // Copiamos el juego para que Bloc detecte el cambio con Equatable
    final newGame = ch.Chess.fromFEN(state.game.fen);
    
    // Ejecutamos el movimiento (asumimos que es promoción a reina si aplica para simplificar por ahora)
    final moveSuccess = newGame.move({'from': from, 'to': to, 'promotion': 'q'});
    
    if (moveSuccess) {
      emit(state.copyWith(
        game: newGame,
        clearSelection: true,
      ));
    }
  }

  void setPlayerColor(ch.Color color) {
    emit(state.copyWith(playerColor: color));
  }
}
