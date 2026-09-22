import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/analysis_cubit.dart';
import '../cubit/analysis_state.dart';
import 'widgets/analysis_board.dart';
import '../../board_editor/view/board_editor_page.dart';
import '../../../core/widgets/app_drawer.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnalysisCubit(),
      child: const AnalysisView(),
    );
  }
}

class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  final TextEditingController _fenController = TextEditingController();
  final TextEditingController _pgnController = TextEditingController();
  bool _isWhiteView = true;

  @override
  void dispose() {
    _fenController.dispose();
    _pgnController.dispose();
    super.dispose();
  }

  void _importFen() {
    context.read<AnalysisCubit>().loadFen(_fenController.text);
  }

  void _importPgn() {
    context.read<AnalysisCubit>().loadPgn(_pgnController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis Puro'), centerTitle: true),
      drawer: const AppDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          final boardWidget = Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? constraints.maxHeight : double.infinity,
                ),
                child: AnalysisBoard(isWhiteView: _isWhiteView),
              ),
            ),
          );

          final menuWidget = _buildAnalysisMenu();

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: boardWidget),
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: const Border(
                      left: BorderSide(color: Colors.black12, width: 1),
                    ),
                  ),
                  child: menuWidget,
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(flex: 3, child: boardWidget),
                Expanded(flex: 2, child: menuWidget),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildAnalysisMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Importar Posición', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _fenController,
            decoration: InputDecoration(
              labelText: 'FEN',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: _importFen,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pgnController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'PGN',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: _importPgn,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final currentFen = context.read<AnalysisCubit>().state.game.fen;
              final fen = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BoardEditorPage(
                    initialFen: currentFen,
                  ),
                ),
              );
              if (fen != null && fen is String && fen.isNotEmpty) {
                _fenController.text = fen;
                _importFen();
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Editor Visual de Tablero'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isWhiteView = !_isWhiteView;
              });
            },
            icon: const Icon(Icons.flip_camera_android),
            label: const Text('Girar Tablero'),
          ),
          const Divider(height: 32),
          const Text('Evaluación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          BlocBuilder<AnalysisCubit, AnalysisState>(
            builder: (context, state) {
              if (state.isEvaluating) {
                return const Center(child: CircularProgressIndicator());
              }
              
              String evalStr;
              if (state.currentEval >= 9000 || state.currentEval <= -9000) {
                 int movesToMate = ((10000 - state.currentEval.abs()) + 1) ~/ 2;
                 if (movesToMate == 0) movesToMate = 1;
                 String sign = state.currentEval > 0 ? '+' : '-';
                 evalStr = 'MATE $sign$movesToMate';
              } else {
                 evalStr = (state.currentEval / 100.0).toStringAsFixed(2);
                 if (state.currentEval > 0) evalStr = '+$evalStr';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Eval: $evalStr', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (state.bestMove != null)
                    Text('Mejor Movimiento: ${state.bestMove}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  if (state.pv != null)
                    Text('Línea Principal:\n${state.pv}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              );
            },
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.read<AnalysisCubit>().undoMove(),
                  icon: const Icon(Icons.undo),
                  label: const Text('Deshacer'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.read<AnalysisCubit>().loadFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reiniciar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
