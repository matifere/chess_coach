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

pub fn evaluate(pos: &Chess) -> i32 {
    if pos.is_checkmate() {
        return if pos.turn() == Color::White { -9999 } else { 9999 };
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

pub fn search(pos: &Chess, depth: u8, mut alpha: i32, mut beta: i32) -> (Option<Move>, i32) {
    if depth == 0 || pos.is_game_over() {
        return (None, evaluate(pos));
    }

    let mut best_move = None;
    let is_white = pos.turn() == Color::White;
    let mut best_score = if is_white { -10000 } else { 10000 };

    let moves = pos.legal_moves();
    if moves.is_empty() {
        return (None, evaluate(pos));
    }

    for m in moves {
        let mut next_pos = pos.clone();
        next_pos.play_unchecked(&m);
        let (_, score) = search(&next_pos, depth - 1, alpha, beta);

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
