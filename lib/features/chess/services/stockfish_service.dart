import 'dart:async';
import 'package:stockfish_chess_engine/stockfish_chess_engine.dart';

class StockfishEvaluation {
  final int score; // in centipawns, or a large number for mate
  final bool isMate;
  final String? bestMove;
  final String? pv;

  StockfishEvaluation({required this.score, this.isMate = false, this.bestMove, this.pv});
}

class StockfishService {
  static final StockfishService _instance = StockfishService._internal();
  factory StockfishService() => _instance;

  late Stockfish _stockfish;
  StreamSubscription<String>? _stdoutSub;

  StockfishService._internal() {
    _stockfish = Stockfish();
  }

  void dispose() {
    _stdoutSub?.cancel();
    _stockfish.dispose();
  }

  bool _isEvaluating = false;

  /// Returns the evaluation for white. (centipawns)
  Future<StockfishEvaluation> evaluatePosition(String fen, {int depth = 12}) async {
    while (_isEvaluating) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    _isEvaluating = true;

    try {
      if (_stockfish.state.value.name != 'ready') {
        final completer = Completer<void>();
        void listener() {
          if (_stockfish.state.value.name == 'ready') {
            _stockfish.state.removeListener(listener);
            completer.complete();
          }
        }
        _stockfish.state.addListener(listener);
        await completer.future;
      }

      final completer = Completer<StockfishEvaluation>();
      StockfishEvaluation? lastEval;
      final isWhiteToMove = fen.split(' ')[1] == 'w';

      _stdoutSub?.cancel();
      _stdoutSub = _stockfish.stdout.listen((line) {
      if (line.startsWith('info depth')) {
        final parts = line.split(' ');
        final scoreIndex = parts.indexOf('score');
        final pvIndex = parts.indexOf('pv');
        String? pvStr;
        if (pvIndex != -1 && pvIndex + 1 < parts.length) {
          pvStr = parts.sublist(pvIndex + 1).join(' ');
        }
        
        if (scoreIndex != -1 && scoreIndex + 2 < parts.length) {
          final type = parts[scoreIndex + 1];
          final val = int.tryParse(parts[scoreIndex + 2]);
          if (val != null) {
            int scoreWhite = isWhiteToMove ? val : -val;
            if (type == 'cp') {
              lastEval = StockfishEvaluation(score: scoreWhite, isMate: false, pv: pvStr);
            } else if (type == 'mate') {
              // mate score: val is mate in N moves. Positive means engine mates, negative means engine is mated.
              // We translate it to a large score, e.g. 10000
              int mateScore = val > 0 ? 10000 - val.abs() : -10000 + val.abs();
              int mateScoreWhite = isWhiteToMove ? mateScore : -mateScore;
              lastEval = StockfishEvaluation(
                score: mateScoreWhite,
                isMate: true,
                pv: pvStr
              );
            }
          }
        }
      } else if (line.startsWith('bestmove')) {
        if (!completer.isCompleted) {
          final parts = line.split(' ');
          String? bestMove = parts.length > 1 ? parts[1] : null;
          completer.complete(lastEval != null 
            ? StockfishEvaluation(
                score: lastEval!.score, 
                isMate: lastEval!.isMate, 
                pv: lastEval!.pv, 
                bestMove: bestMove)
            : StockfishEvaluation(score: 0, bestMove: bestMove));
        }
      }
    });


    _stockfish.stdin = 'position fen $fen';
    _stockfish.stdin = 'go depth $depth';

    final result = await completer.future;
    _stdoutSub?.cancel();
    _stdoutSub = null;
    
    return result;
    } finally {
      _isEvaluating = false;
    }
  }
}
