import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chess/chess.dart' as ch;
import 'chess_state.dart';
import 'package:chess_coach/src/rust/api/simple.dart' as rust_api;
import '../services/stockfish_service.dart';
import '../services/openings_service.dart';
class ChessCubit extends Cubit<ChessState> {
  ChessCubit() : super(ChessState(game: ch.Chess()));

  void onSquareTapped(String square) {
    if (state.pendingPromotion != null || _isGameOver()) return;

    if (state.selectedSquare != null) {
      if (state.game.turn != state.playerColor) {
        // Lógica de premove (tap)
        if (state.selectedSquare != square) {
          final piece = state.game.get(state.selectedSquare!);
          if (piece != null && piece.color == state.playerColor) {
            // Generación pseudo-legal para premoves
            final copy = state.game.copy();
            copy.turn = state.playerColor;
            final moves = copy.generate_moves({'square': state.selectedSquare!});
            if (moves.any((m) => m.toAlgebraic == square)) {
              emit(state.copyWith(
                premove: {'from': state.selectedSquare!, 'to': square},
                clearSelection: true,
              ));
              return;
            }
          }
        }
        emit(state.copyWith(clearSelection: true, clearPremove: true));
        return;
      }

      if (state.legalMoveDestinations.contains(square)) {
        final piece = state.game.get(state.selectedSquare!);
        if (piece != null &&
            piece.type == ch.PieceType.PAWN &&
            (square[1] == '8' || square[1] == '1')) {
          emit(state.copyWith(pendingPromotion: {'from': state.selectedSquare!, 'to': square}));
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
    if (piece != null && piece.color == state.playerColor) {
      if (state.game.turn != state.playerColor) {
        // Seleccionar pieza para premove (con movimientos pseudo-legales)
        final copy = state.game.copy();
        copy.turn = state.playerColor;
        final moves = copy.generate_moves({'square': square});
        final destinations = moves.map((m) => m.toAlgebraic).toList();
        emit(state.copyWith(
          selectedSquare: square, 
          legalMoveDestinations: destinations, 
          clearPremove: true
        ));
      } else {
        _selectSquare(square);
      }
    } else {
      emit(state.copyWith(clearSelection: true));
    }
  }

  void onDraggedMove(String from, String to) {
    if (state.pendingPromotion != null || _isGameOver()) return;
    if (from == to) return; 
    
    if (state.game.turn != state.playerColor) {
      // Lógica de premove (drag)
      final piece = state.game.get(from);
      if (piece != null && piece.color == state.playerColor) {
        final copy = state.game.copy();
        copy.turn = state.playerColor;
        final moves = copy.generate_moves({'square': from});
        if (moves.any((m) => m.toAlgebraic == to)) {
          emit(state.copyWith(
            premove: {'from': from, 'to': to},
            clearSelection: true,
          ));
        }
      }
      return; 
    }

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

  Future<void> _makeMove(String from, String to, {String? promotion, bool isBotMove = false, bool wasDragged = false}) async {
    final newGame = state.game.copy();

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
      final oldFen = state.game.fen;
      final newFen = newGame.fen;
      final turnBefore = state.game.turn;

      // ACTUALIZACIÓN VISUAL INMEDIATA (sin bloquear)
      emit(
        state.copyWith(
          game: newGame,
          clearSelection: true,
          clearPendingPromotion: true,
          lastMoveFeedback: {
            'from': from,
            'to': to,
            'wasDragged': wasDragged,
            if (secondaryMove != null) 'secondaryMove': secondaryMove,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        ),
      );

      // Actualizamos UI de inmediato


      int evalBefore = state.currentEval;
      if (state.lastMoveFeedback == null && evalBefore == 0) {
        final sfBefore = await StockfishService().evaluatePosition(oldFen, depth: 10);
        evalBefore = sfBefore.score;
      }

      final sfAfter = await StockfishService().evaluatePosition(newFen, depth: 10);
      final evalAfter = sfAfter.score;

      double getWinProb(int cp) {
        return 1.0 / (1.0 + exp(-0.00368208 * cp));
      }

      double winProbBefore = turnBefore == ch.Color.WHITE ? getWinProb(evalBefore) : getWinProb(-evalBefore);
      double winProbAfter = turnBefore == ch.Color.WHITE ? getWinProb(evalAfter) : getWinProb(-evalAfter);
      
      double loss = winProbBefore - winProbAfter;

      MoveQuality computedQuality = MoveQuality.good;
      if (loss <= 0.015) {
        computedQuality = MoveQuality.best;
        if (loss < -0.015) computedQuality = MoveQuality.great;
      } else if (loss <= 0.03) {
        computedQuality = MoveQuality.excellent;
      } else if (loss <= 0.06) {
        computedQuality = MoveQuality.good;
      } else if (loss <= 0.10) {
        computedQuality = MoveQuality.inaccuracy;
      } else if (loss <= 0.15) {
        computedQuality = MoveQuality.mistake;
      } else {
        computedQuality = MoveQuality.blunder;
      }

      if (OpeningsService().isBookMove(newGame)) {
        computedQuality = MoveQuality.book;
      }
      final openingName = OpeningsService().getOpeningName(newGame);
      // La evaluación de la UI es exactamente la evaluación que acabamos de calcular
      final uiEval = evalAfter;

      // Protegemos el estado por si el usuario movió mientras calculábamos
      if (state.game.fen == newFen) {
        final finalFeedback = Map<String, dynamic>.from(state.lastMoveFeedback ?? {});
        finalFeedback['quality'] = computedQuality;
        if (openingName != null) {
          finalFeedback['openingName'] = openingName;
        }

        final hasValidPremove = isBotMove && state.premove != null && newGame.turn == state.playerColor && !_isGameOver();
        bool executePremove = false;
        String? pmFrom;
        String? pmTo;
        
        if (hasValidPremove) {
          pmFrom = state.premove!['from'];
          pmTo = state.premove!['to'];
          final moves = newGame.generate_moves({'square': pmFrom!});
          executePremove = moves.any((m) => m.toAlgebraic == pmTo!);
        }
        
        emit(
          state.copyWith(
            currentEval: uiEval,
            lastMoveFeedback: finalFeedback,
            clearPremove: hasValidPremove,
          ),
        );

        if (executePremove && pmFrom != null && pmTo != null) {
          _makeMove(pmFrom, pmTo, wasDragged: true);
        }

        // Ya calculamos y mostramos TU medalla. Ahora le decimos a Maia que juegue.
        if (!isBotMove && newGame.turn != state.playerColor && !_isGameOver()) {
          _triggerBotMove();
        }
      }
    }
  }

  Future<void> _triggerBotMove() async {
    if (state.game.turn == state.playerColor || _isGameOver()) return;

    // Pausa visual intencional larga para que el usuario pueda ver su medalla (Badge)
    // y la barra de evaluación antes de que el bot mueva y sobreescriba la pantalla.
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (state.game.turn == state.playerColor || _isGameOver()) return;

    final fen = state.game.fen;
    
    // 1. Intentar hacer una jugada de libro teórica si estamos practicando una apertura o si estamos en la teoría
    final bookUciMove = OpeningsService().getRandomBookMove(state.game, targetOpening: state.practiceOpening);
    if (bookUciMove != null) {
      final from = bookUciMove.substring(0, 2);
      final to = bookUciMove.substring(2, 4);
      String? promotion;
      if (bookUciMove.length == 5) {
        promotion = bookUciMove[4];
      }
      
      print('🤖 MAIA juega de LIBRO: $from$to (Target: ${state.practiceOpening ?? "ninguno"})');
      _makeMove(from, to, promotion: promotion, isBotMove: true);
      return;
    }

    // 2. Si no hay jugadas de libro (o nos salimos de la teoría), usar el motor
    int depth = (state.botElo / 450).floor(); 
    if (depth < 1) depth = 1;
    if (depth > 4) depth = 4;
    
    print('🤖 MAIA ELO: ${state.botElo} -> Jugando a Profundidad (Depth): $depth');

    // Llamada asíncrona a Rust pasando el Elo para añadir ruido (noise)
    final uciMove = await rust_api.getBestMove(fen: fen, depth: depth, elo: state.botElo);

    if (uciMove.isNotEmpty && uciMove.length >= 4) {
      final from = uciMove.substring(0, 2);
      final to = uciMove.substring(2, 4);
      String? promotion;
      if (uciMove.length == 5) {
        promotion = uciMove.substring(4, 5);
      }

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
    emit(ChessState(
      game: ch.Chess(), 
      playerColor: state.playerColor, 
      botElo: state.botElo,
      practiceOpening: state.practiceOpening,
    ));
    if (state.playerColor == ch.Color.BLACK) {
      _triggerBotMove();
    }
  }

  void setPracticeOpening(String? opening) {
    emit(state.copyWith(practiceOpening: opening));
    // Si estamos en el turno del bot y en la jugada 1, forzamos un recalculo? 
    // No hace falta, el usuario lo elige antes de empezar.
  }

  bool _isGameOver() {
    return state.game.in_checkmate ||
        state.game.in_draw ||
        state.resignedPlayer != null;
  }
}
