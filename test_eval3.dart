import 'dart:math';
double getWinProb(int cp) { return 1.0 / (1.0 + exp(-0.00368208 * cp)); }
void printLoss(int cp1, int cp2, String name) {
  double l = getWinProb(cp1) - getWinProb(cp2);
  print(name + ': ' + l.toString());
}
void main() {
  printLoss(0, -50, "Pawn inaccuracy"); // 0 to -0.5
  printLoss(0, -100, "1 pawn drop"); // 0 to -1.0
  printLoss(0, -200, "2 pawn drop"); // 0 to -2.0
  printLoss(0, -300, "3 pawn drop (piece)"); // 0 to -3.0
  printLoss(300, 0, "Piece drop when ahead"); // +3.0 to 0
  printLoss(89, -300, "Alekhine hang piece");
}
