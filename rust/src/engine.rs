use shakmaty::{Chess, Position, Move, Color};
use std::cmp;
use std::sync::OnceLock;
use nnue_rs::Network;

static NNUE_NET: OnceLock<Network> = OnceLock::new();

pub fn load_nnue_bytes(bytes: &[u8]) -> bool {
    match Network::from_bytes(bytes) {
        Ok(net) => {
            // ignoramos el resultado si ya estaba cargado
            let _ = NNUE_NET.set(net);
            true
        },
        Err(_) => false,
    }
}

pub fn evaluate(pos: &Chess, ply: u8) -> i32 {
    if pos.is_checkmate() {
        // Si el turno es Blanco y hay jaque mate, el Blanco acaba de perder. 
        // El puntaje para quien recibe mate es negativo, pero preferimos los mates rápidos,
        // así que el puntaje es -10000 + ply (un mate en ply 1 es -9999, en ply 3 es -9997).
        // El jugador atacante buscará maximizar el valor absoluto, lo cual minimiza el ply.
        return if pos.turn() == Color::White { -10000 + (ply as i32) } else { 10000 - (ply as i32) };
    }
    if pos.is_game_over() { return 0; }

    if let Some(net) = NNUE_NET.get() {
        let fen = shakmaty::fen::Fen::from_position(pos.clone(), shakmaty::EnPassantMode::Legal).to_string();
        if let Ok(score) = net.evaluate_fen(&fen) {
            return if pos.turn() == Color::White { score } else { -score };
        }
    }

    fallback_evaluate(pos)
}

fn fallback_evaluate(pos: &Chess) -> i32 {
    use shakmaty::{Role, Square};
    let mut score = 0;
    let board = pos.board();
    for sq_idx in 0..64 {
        let sq = Square::new(sq_idx);
        if let Some(piece) = board.piece_at(sq) {
            let val = match piece.role {
                Role::Pawn => 100,
                Role::Knight => 300,
                Role::Bishop => 300,
                Role::Rook => 500,
                Role::Queen => 900,
                Role::King => 0,
            };
            if piece.color == Color::White {
                score += val;
            } else {
                score -= val;
            }
        }
    }
    score
}

pub fn quiescence_search(pos: &Chess, mut alpha: i32, mut beta: i32, limit: u8, ply: u8) -> i32 {
    let stand_pat = evaluate(pos, ply);
    if pos.is_game_over() || limit == 0 {
        return stand_pat;
    }

    let is_white = pos.turn() == Color::White;

    if is_white {
        if stand_pat >= beta { return beta; }
        if alpha < stand_pat { alpha = stand_pat; }
    } else {
        if stand_pat <= alpha { return alpha; }
        if beta > stand_pat { beta = stand_pat; }
    }

    let captures: Vec<Move> = pos.legal_moves().into_iter().filter(|m| m.is_capture()).collect();
    
    let mut best_score = stand_pat;

    for m in captures {
        let mut next_pos = pos.clone();
        next_pos.play_unchecked(&m);
        let score = quiescence_search(&next_pos, alpha, beta, limit - 1, ply + 1);

        if is_white {
            if score > best_score { best_score = score; }
            alpha = cmp::max(alpha, best_score);
        } else {
            if score < best_score { best_score = score; }
            beta = cmp::min(beta, best_score);
        }
        if beta <= alpha { break; }
    }

    best_score
}

pub fn search(pos: &Chess, depth: u8, mut alpha: i32, mut beta: i32, ply: u8) -> (Option<Move>, i32) {
    if pos.is_game_over() {
        return (None, evaluate(pos, ply));
    }
    if depth == 0 {
        return (None, quiescence_search(pos, alpha, beta, 4, ply));
    }

    let mut best_move = None;
    let is_white = pos.turn() == Color::White;
    // Iniciamos con +/- 20000 para no chocar con el mate que es 10000
    let mut best_score = if is_white { -20000 } else { 20000 };

    let moves = pos.legal_moves();
    if moves.is_empty() {
        return (None, evaluate(pos, ply));
    }

    for m in moves {
        let mut next_pos = pos.clone();
        next_pos.play_unchecked(&m);
        let (_, score) = search(&next_pos, depth - 1, alpha, beta, ply + 1);

        if is_white {
            if score > best_score {
                best_score = score;
                best_move = Some(m);
            }
            alpha = cmp::max(alpha, best_score);
        } else {
            if score < best_score {
                best_score = score;
                best_move = Some(m);
            }
            beta = cmp::min(beta, best_score);
        }
        if beta <= alpha { break; }
    }

    (best_move, best_score)
}
