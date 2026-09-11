import 'dart:math';
double getWinProb(int cp) { return 1.0 / (1.0 + exp(-0.00368208 * cp)); }
void main() {
  int evalBefore = 89;
  int evalAfter = 300;
  double winProbBefore = getWinProb(-evalBefore);
  double winProbAfter = getWinProb(-evalAfter);
  double loss = winProbBefore - winProbAfter;
  print('winProbBefore: ' + winProbBefore.toString());
  print('winProbAfter: ' + winProbAfter.toString());
  print('loss: ' + loss.toString());
}
