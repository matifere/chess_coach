import 'package:flutter_bloc/flutter_bloc.dart';
import 'board_editor_state.dart';

class BoardEditorCubit extends Cubit<BoardEditorState> {
  BoardEditorCubit(String initialFen) : super(const BoardEditorState(board: {})) {
    _loadFen(initialFen);
  }

  void _loadFen(String fen) {
    if (fen.isEmpty) return;
    
    final parts = fen.split(' ');
    final position = parts[0];
    final turn = parts.length > 1 ? parts[1] : 'w';

    final Map<String, EditorPiece> newBoard = {};
    final ranks = position.split('/');
    
    for (int i = 0; i < ranks.length; i++) {
      if (i >= 8) break;
      final rankStr = ranks[i];
      final rank = 8 - i;
      int fileVal = 0;
      
      for (int j = 0; j < rankStr.length; j++) {
        if (fileVal >= 8) break;
        final char = rankStr[j];
        
        final emptyCount = int.tryParse(char);
        if (emptyCount != null) {
          fileVal += emptyCount;
        } else {
          final color = char == char.toLowerCase() ? 'b' : 'w';
          final type = char.toLowerCase();
          final file = String.fromCharCode('a'.codeUnitAt(0) + fileVal);
          newBoard['$file$rank'] = EditorPiece(color: color, type: type);
          fileVal++;
        }
      }
    }
    
    emit(BoardEditorState(board: newBoard, turn: turn));
  }

  void placePiece(String square, EditorPiece piece) {
    final newBoard = Map<String, EditorPiece>.from(state.board);
    newBoard[square] = piece;
    emit(state.copyWith(board: newBoard));
  }

  void removePiece(String square) {
    if (!state.board.containsKey(square)) return;
    final newBoard = Map<String, EditorPiece>.from(state.board);
    newBoard.remove(square);
    emit(state.copyWith(board: newBoard));
  }
  
  void movePiece(String fromSquare, String toSquare) {
    if (fromSquare == toSquare) return;
    if (!state.board.containsKey(fromSquare)) return;
    
    final piece = state.board[fromSquare]!;
    final newBoard = Map<String, EditorPiece>.from(state.board);
    newBoard.remove(fromSquare);
    newBoard[toSquare] = piece;
    
    emit(state.copyWith(board: newBoard));
  }

  void clearBoard() {
    emit(state.copyWith(board: const {}));
  }
  
  void setInitialPosition() {
    _loadFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
  }

  void setTurn(String turn) {
    emit(state.copyWith(turn: turn));
  }
}
