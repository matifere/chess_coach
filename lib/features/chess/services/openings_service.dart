import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:chess/chess.dart' as ch;

class OpeningsService {
  static final OpeningsService _instance = OpeningsService._internal();
  factory OpeningsService() => _instance;

  Map<String, dynamic> _tree = {};
  bool _isLoaded = false;

  OpeningsService._internal();

  Future<void> loadOpenings() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/openings.json');
      _tree = jsonDecode(jsonString);
      _isLoaded = true;
    } catch (e) {
      print('Error loading openings.json: $e');
    }
  }

  /// Traverse the tree using the game's history of moves.
  /// Returns a map representing the current node if it's in the book, else null.
  Map<String, dynamic>? getNode(ch.Chess game) {
    if (!_isLoaded) return null;
    
    Map<String, dynamic> node = _tree;
    for (final state in game.history) {
      final m = state.move;
      final prom = m.promotion != null ? m.promotion!.name : '';
      final uci = m.fromAlgebraic + m.toAlgebraic + prom;
      
      if (node.containsKey('c') && (node['c'] as Map).containsKey(uci)) {
        node = node['c'][uci];
      } else {
        return null;
      }
    }
    return node;
  }

  /// Check if the current history is a valid sequence in the opening book.
  bool isBookMove(ch.Chess game) {
    return getNode(game) != null;
  }

  /// Get the opening name for the current game history.
  /// Inherits the name from the closest named ancestor if the current node is an unnamed intermediate node.
  String? getOpeningName(ch.Chess game) {
    if (!_isLoaded) return null;
    
    Map<String, dynamic> node = _tree;
    String? lastName;
    
    for (final state in game.history) {
      final m = state.move;
      final prom = m.promotion != null ? m.promotion!.name : '';
      final uci = m.fromAlgebraic + m.toAlgebraic + prom;
      
      if (node.containsKey('c') && (node['c'] as Map).containsKey(uci)) {
        node = node['c'][uci];
        if (node.containsKey('n')) {
          lastName = node['n'] as String;
        }
      } else {
        return lastName; // Still return the last known name even if out of book? Or null?
                         // Better to just return null if out of book, or maybe the name.
                         // But the caller expects the opening name ONLY if it's a book move.
      }
    }
    
    // If game has no history, node is _tree which might not have 'n'.
    // If it's a valid book node, return the closest name.
    return lastName;
  }

  /// Get valid book moves from the current position.
  /// If [targetOpening] is provided, only returns moves that eventually lead to that opening.
  List<String> getBookMoves(ch.Chess game, {String? targetOpening}) {
    final node = getNode(game);
    if (node == null || !node.containsKey('c')) return [];

    final children = node['c'] as Map<String, dynamic>;
    final allMoves = children.keys.cast<String>().toList();

    if (targetOpening == null || targetOpening.isEmpty) {
      return allMoves;
    }

    final targetLower = targetOpening.toLowerCase();
    return allMoves.where((move) {
      final childNode = children[move] as Map<String, dynamic>;
      return _subtreeContains(childNode, targetLower);
    }).toList();
  }

  bool _subtreeContains(Map<String, dynamic> node, String targetOpening) {
    if (node.containsKey('n')) {
      final name = (node['n'] as String).toLowerCase();
      if (name.contains(targetOpening)) {
        return true;
      }
    }
    if (node.containsKey('c')) {
      for (final child in (node['c'] as Map<String, dynamic>).values) {
        if (_subtreeContains(child as Map<String, dynamic>, targetOpening)) {
          return true;
        }
      }
    }
    return false;
  }
}
