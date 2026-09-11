import 'package:chess/chess.dart';
import 'package:chess_coach/features/chess/services/openings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OpeningsService().loadOpenings();
  
  final chess = Chess();
  chess.move('e4');
  chess.move('Nf6');
  chess.move('e5');
  
  print('isBookMove: \${OpeningsService().isBookMove(chess)}');
  print('openingName: \${OpeningsService().getOpeningName(chess)}');
}
