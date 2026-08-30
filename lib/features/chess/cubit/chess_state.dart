import 'package:equatable/equatable.dart';
import 'package:chess/chess.dart' as ch;

class ChessState extends Equatable {
  final ch.Chess game;
  final String? selectedSquare;
  final List<String> legalMoveDestinations;
  final ch.Color playerColor;
  final Map<String, String>? pendingPromotion;
  final ch.Color? resignedPlayer;

  const ChessState({
    required this.game,
    this.selectedSquare,
    this.legalMoveDestinations = const [],
    this.playerColor = ch.Color.WHITE,
    this.pendingPromotion,
    this.resignedPlayer,
  });

  ChessState copyWith({
    ch.Chess? game,
    String? selectedSquare,
    List<String>? legalMoveDestinations,
    ch.Color? playerColor,
    Map<String, String>? pendingPromotion,
    ch.Color? resignedPlayer,
    bool clearSelection = false,
    bool clearPendingPromotion = false,
    bool clearResignedPlayer = false,
  }) {
    return ChessState(
      game: game ?? this.game,
      selectedSquare: clearSelection ? null : (selectedSquare ?? this.selectedSquare),
      legalMoveDestinations: clearSelection ? const [] : (legalMoveDestinations ?? this.legalMoveDestinations),
      playerColor: playerColor ?? this.playerColor,
      pendingPromotion: clearPendingPromotion ? null : (pendingPromotion ?? this.pendingPromotion),
      resignedPlayer: clearResignedPlayer ? null : (resignedPlayer ?? this.resignedPlayer),
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
      ];
}
