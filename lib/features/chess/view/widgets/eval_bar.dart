import 'package:flutter/material.dart';

class EvalBarWidget extends StatelessWidget {
  final int eval; // Centipeones (positivo = blancas, negativo = negras)
  final bool isWhiteView; // Orientación del tablero

  const EvalBarWidget({
    super.key,
    required this.eval,
    required this.isWhiteView,
  });

  @override
  Widget build(BuildContext context) {
    double clampEval = eval.toDouble();
    if (clampEval > 1000) clampEval = 1000;
    if (clampEval < -1000) clampEval = -1000;

    // Si la evaluación es +10.00 (1000 cp), la barra será 100% blanca.
    double whitePercentage = 0.5 + (clampEval / 2000.0);

    double fillPercentage = isWhiteView ? whitePercentage : (1.0 - whitePercentage);
    
    Color bottomColor = isWhiteView ? Colors.white : Colors.black87;
    Color topColor = isWhiteView ? Colors.black87 : Colors.white;
    
    bool whiteAdvantage = eval > 0;
    String evalText;
    
    if (eval >= 9000 || eval <= -9000) {
      // Calculamos en cuántos movimientos (full moves) es el mate
      int movesToMate = ((10000 - eval.abs()) + 1) ~/ 2;
      if (movesToMate == 0) movesToMate = 1; // Para evitar "M0"
      evalText = "M$movesToMate";
    } else {
      evalText = (eval.abs() / 100.0).toStringAsFixed(1);
      if (evalText == "0.0") evalText = "0.0";
    }

    return Container(
      width: 24,
      decoration: BoxDecoration(
        color: topColor,
        border: Border.all(color: Colors.brown[800]!, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            FractionallySizedBox(
              heightFactor: fillPercentage,
              widthFactor: 1.0,
              child: Container(color: bottomColor),
            ),
            Positioned(
              top: whiteAdvantage == isWhiteView ? null : 4,
              bottom: whiteAdvantage == isWhiteView ? 4 : null,
              child: Text(
                evalText,
                style: TextStyle(
                  color: whiteAdvantage ? Colors.black87 : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
