import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chess/chess.dart' as ch;
import 'analysis_state.dart';
import '../../chess/services/stockfish_service.dart';

class AnalysisCubit extends Cubit<AnalysisState> {
  final StockfishService _stockfishService = StockfishService();
  bool _isEvaluating = false;

  AnalysisCubit() : super(AnalysisState(game: ch.Chess())) {
    _evaluatePosition();
  }

  void loadFen(String fen) {
    final game = ch.Chess();
    if (game.load(fen)) {
      emit(state.copyWith(game: game, clearSelected: true, clearPromotion: true, clearEval: true));
      _evaluatePosition();
    }
  }
  
  void loadPgn(String pgn) {
    final game = ch.Chess();
    if (game.load_pgn(pgn)) {
      emit(state.copyWith(game: game, clearSelected: true, clearPromotion: true, clearEval: true));
      _evaluatePosition();
    }
  }

  void onSquareTapped(String square) {
    if (state.selectedSquare == square) {
      emit(state.copyWith(clearSelected: true));
      return;
    }

    if (state.selectedSquare != null) {
      final move = {
        'from': state.selectedSquare!,
        'to': square,
      };

      // Check if it's a promotion
      final piece = state.game.get(state.selectedSquare!);
      if (piece != null && piece.type == ch.PieceType.PAWN) {
        final isWhite = piece.color == ch.Color.WHITE;
        final rank = int.parse(square[1]);
        if ((isWhite && rank == 8) || (!isWhite && rank == 1)) {
          final legalMoves = state.game.moves({'verbose': true}) as List;
          final isLegal = legalMoves.any((m) => m['from'] == move['from'] && m['to'] == move['to']);
          if (isLegal) {
            emit(state.copyWith(
              pendingPromotion: move,
              clearSelected: true,
            ));
            return;
          }
        }
      }

      final moveResult = state.game.move(move);
      if (moveResult != false) {
        emit(state.copyWith(
          game: state.game,
          clearSelected: true,
          clearEval: true,
        ));
        _evaluatePosition();
        return;
      }
    }

    // Select piece if exists and belongs to current turn
    final piece = state.game.get(square);
    if (piece != null && piece.color == state.game.turn) {
      final moves = state.game.moves({'square': square, 'verbose': true}) as List;
      final destinations = moves.map((m) => m['to'] as String).toList();
      emit(state.copyWith(
        selectedSquare: square,
        legalMoveDestinations: destinations,
      ));
    } else {
      emit(state.copyWith(clearSelected: true));
    }
  }

  void onDraggedMove(String from, String to) {
    emit(state.copyWith(selectedSquare: from));
    onSquareTapped(to);
  }

  void executePromotion(String promotionPiece) {
    if (state.pendingPromotion == null) return;

    final move = {
      'from': state.pendingPromotion!['from']!,
      'to': state.pendingPromotion!['to']!,
      'promotion': promotionPiece,
    };

    if (state.game.move(move) != false) {
      emit(state.copyWith(
        game: state.game,
        clearPromotion: true,
        clearEval: true,
      ));
      _evaluatePosition();
    } else {
      emit(state.copyWith(clearPromotion: true));
    }
  }

  void cancelPromotion() {
    emit(state.copyWith(clearPromotion: true));
  }
  
  void undoMove() {
    if (state.game.undo() != null) {
      emit(state.copyWith(
        game: state.game,
        clearSelected: true,
        clearPromotion: true,
        clearEval: true,
      ));
      _evaluatePosition();
    }
  }
  
  Future<void> _evaluatePosition() async {
    if (_isEvaluating) return;
    _isEvaluating = true;
    emit(state.copyWith(isEvaluating: true));
    
    try {
      final fen = state.game.fen;
      final eval = await _stockfishService.evaluatePosition(fen, depth: 15); // higher depth for analysis
      
      // Ensure the state hasn't changed while evaluating
      if (state.game.fen == fen) {
        emit(state.copyWith(
          currentEval: eval.score,
          bestMove: eval.bestMove,
          pv: eval.pv,
          isEvaluating: false,
        ));
      }
    } finally {
      _isEvaluating = false;
    }
  }
}
