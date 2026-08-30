import 'package:equatable/equatable.dart';
import 'package:chess/chess.dart' as ch;

enum MoveQuality {
  brilliant,
  great,
  best,
  excellent,
  good,
  inaccuracy,
  mistake,
  blunder,
  book
}

class ChessState extends Equatable {
  final ch.Chess game;
  final String? selectedSquare;
  final List<String> legalMoveDestinations;
  final ch.Color playerColor;
  final Map<String, String>? pendingPromotion;
  final ch.Color? resignedPlayer;
  final Map<String, dynamic>? lastMoveFeedback;

  const ChessState({
    required this.game,
    this.selectedSquare,
    this.legalMoveDestinations = const [],
    this.playerColor = ch.Color.WHITE,
    this.pendingPromotion,
    this.resignedPlayer,
    this.lastMoveFeedback,
  });

  ChessState copyWith({
    ch.Chess? game,
    String? selectedSquare,
    List<String>? legalMoveDestinations,
    ch.Color? playerColor,
    Map<String, String>? pendingPromotion,
    ch.Color? resignedPlayer,
    Map<String, dynamic>? lastMoveFeedback,
    bool clearSelection = false,
    bool clearPendingPromotion = false,
    bool clearResignedPlayer = false,
  }) {
    return ChessState(
      game: game ?? this.game,
      selectedSquare: clearSelection
          ? null
          : (selectedSquare ?? this.selectedSquare),
      legalMoveDestinations: clearSelection
          ? const []
          : (legalMoveDestinations ?? this.legalMoveDestinations),
      playerColor: playerColor ?? this.playerColor,
      pendingPromotion: clearPendingPromotion
          ? null
          : (pendingPromotion ?? this.pendingPromotion),
      resignedPlayer: clearResignedPlayer
          ? null
          : (resignedPlayer ?? this.resignedPlayer),
      lastMoveFeedback: lastMoveFeedback ?? this.lastMoveFeedback,
    );
  }

  @override
  List<Object?> get props => [
    game.fen,
    selectedSquare,
    legalMoveDestinations,
    playerColor,
    pendingPromotion,
    resignedPlayer,
    lastMoveFeedback,
  ];
}
