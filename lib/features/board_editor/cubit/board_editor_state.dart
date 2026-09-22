import 'package:equatable/equatable.dart';

class EditorPiece {
  final String color; // 'w' or 'b'
  final String type;  // 'p', 'n', 'b', 'r', 'q', 'k'

  const EditorPiece({required this.color, required this.type});
  
  String get fenChar => color == 'w' ? type.toUpperCase() : type.toLowerCase();
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorPiece &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          type == other.type;

  @override
  int get hashCode => color.hashCode ^ type.hashCode;
}

class BoardEditorState extends Equatable {
  final Map<String, EditorPiece> board;
  final String turn; // 'w' or 'b'

  const BoardEditorState({
    required this.board,
    this.turn = 'w',
  });

  BoardEditorState copyWith({
    Map<String, EditorPiece>? board,
    String? turn,
  }) {
    return BoardEditorState(
      board: board ?? this.board,
      turn: turn ?? this.turn,
    );
  }

  String toFen() {
    String fen = '';
    for (int rank = 8; rank >= 1; rank--) {
      int emptySpaces = 0;
      for (int fileVal = 0; fileVal < 8; fileVal++) {
        final file = String.fromCharCode('a'.codeUnitAt(0) + fileVal);
        final square = '$file$rank';
        final piece = board[square];

        if (piece == null) {
          emptySpaces++;
        } else {
          if (emptySpaces > 0) {
            fen += emptySpaces.toString();
            emptySpaces = 0;
          }
          fen += piece.fenChar;
        }
      }
      if (emptySpaces > 0) {
        fen += emptySpaces.toString();
      }
      if (rank > 1) {
        fen += '/';
      }
    }
    
    // Minimal standard FEN defaults:
    // Castling and en passant might be invalid based on pieces, but we assume no castling rights or en passant for an arbitrary setup by default.
    fen += ' $turn - - 0 1';
    return fen;
  }

  @override
  List<Object> get props => [board, turn];
}
