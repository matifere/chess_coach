import 'dart:math';
double getWinProb(int cp) { return 1.0 / (1.0 + exp(-0.00368208 * cp)); }
void main() {
  int cpBefore = -50;
  int cpAfter = -350;
  double loss = getWinProb(cpBefore) - getWinProb(cpAfter);
  print('Loss: ' + loss.toString());
}
