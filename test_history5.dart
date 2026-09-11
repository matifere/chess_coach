import 'package:chess/chess.dart';
void main() {
  final chess = Chess();
  chess.move('e4');
  chess.move('Nf6');
  chess.move('e5');
  for (var state in chess.history) {
    var m = state.move;
    print(m.fromAlgebraic + m.toAlgebraic);
  }
}
