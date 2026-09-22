import 'package:equatable/equatable.dart';
import 'package:chess/chess.dart' as ch;

class AnalysisState extends Equatable {
  final ch.Chess game;
  final int currentEval;
  final String? bestMove;
  final String? pv;
  final String? selectedSquare;
  final List<String> legalMoveDestinations;
  final Map<String, String>? pendingPromotion;
  final bool isEvaluating;

  const AnalysisState({
    required this.game,
    this.currentEval = 0,
    this.bestMove,
    this.pv,
    this.selectedSquare,
    this.legalMoveDestinations = const [],
    this.pendingPromotion,
    this.isEvaluating = false,
  });

  AnalysisState copyWith({
    ch.Chess? game,
    int? currentEval,
    String? bestMove,
    String? pv,
    String? selectedSquare,
    List<String>? legalMoveDestinations,
    Map<String, String>? pendingPromotion,
    bool? isEvaluating,
    bool clearSelected = false,
    bool clearPromotion = false,
    bool clearEval = false,
  }) {
    return AnalysisState(
      game: game ?? this.game,
      currentEval: clearEval ? 0 : (currentEval ?? this.currentEval),
      bestMove: clearEval ? null : (bestMove ?? this.bestMove),
      pv: clearEval ? null : (pv ?? this.pv),
      selectedSquare: clearSelected ? null : (selectedSquare ?? this.selectedSquare),
      legalMoveDestinations: clearSelected ? [] : (legalMoveDestinations ?? this.legalMoveDestinations),
      pendingPromotion: clearPromotion ? null : (pendingPromotion ?? this.pendingPromotion),
      isEvaluating: isEvaluating ?? this.isEvaluating,
    );
  }

  @override
  List<Object?> get props => [
        game.fen,
        currentEval,
        bestMove,
        pv,
        selectedSquare,
        legalMoveDestinations,
        pendingPromotion,
        isEvaluating,
      ];
}
