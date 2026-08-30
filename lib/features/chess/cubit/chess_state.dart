import 'package:equatable/equatable.dart';
import 'package:chess/chess.dart' as ch;

class ChessState extends Equatable {
  final ch.Chess game;
  final String? selectedSquare;
  final List<String> legalMoveDestinations;
  final ch.Color playerColor;

  const ChessState({
    required this.game,
    this.selectedSquare,
    this.legalMoveDestinations = const [],
    this.playerColor = ch.Color.WHITE,
  });

  ChessState copyWith({
    ch.Chess? game,
    String? selectedSquare,
    List<String>? legalMoveDestinations,
    ch.Color? playerColor,
    bool clearSelection = false,
  }) {
    return ChessState(
      game: game ?? this.game,
      selectedSquare: clearSelection ? null : (selectedSquare ?? this.selectedSquare),
      legalMoveDestinations: clearSelection ? const [] : (legalMoveDestinations ?? this.legalMoveDestinations),
      playerColor: playerColor ?? this.playerColor,
    );
  }

  @override
  List<Object?> get props => [
        game.fen, // Usamos el FEN para comparar si el tablero cambió
        selectedSquare,
        legalMoveDestinations,
        playerColor,
      ];
}
