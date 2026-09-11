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

pub fn evaluate(pos: &Chess, ply: u8, elo: Option<u16>) -> i32 {
    if pos.is_checkmate() {
        return if pos.turn() == Color::White { -10000 + (ply as i32) } else { 10000 - (ply as i32) };
    }
    if pos.is_game_over() { return 0; }

    let mut base_score = 0;
    if let Some(net) = NNUE_NET.get() {
        let fen = shakmaty::fen::Fen::from_position(pos.clone(), shakmaty::EnPassantMode::Legal).to_string();
        if let Ok(score) = net.evaluate_fen(&fen) {
            base_score = if pos.turn() == Color::White { score } else { -score };
        } else {
            base_score = fallback_evaluate(pos);
        }
    } else {
        base_score = fallback_evaluate(pos);
    }

    // Add noise if Elo is provided (meaning this is a Bot making a move)
    if let Some(e) = elo {
        if e < 2000 {
            // Random noise inversely proportional to Elo
            // Elo 600 -> noise_range = 1500 (15 pawns error margin!)
            // Elo 1500 -> noise_range = 500 (5 pawns)
            let noise_range = (2000 - e as i32) * 110 / 100; 
            
            // Generate a simple pseudo-random number based on the fen/hash
            use std::collections::hash_map::DefaultHasher;
            use std::hash::{Hash, Hasher};
            let mut hasher = DefaultHasher::new();
            let fen = shakmaty::fen::Fen::from_position(pos.clone(), shakmaty::EnPassantMode::Legal).to_string();
            fen.hash(&mut hasher);
            let hash = hasher.finish();
            
            let noise = (hash % (noise_range as u64 * 2 + 1)) as i32 - noise_range;
            base_score += noise;
        }
    }

    base_score
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

pub fn quiescence_search(pos: &Chess, mut alpha: i32, mut beta: i32, limit: u8, ply: u8, elo: Option<u16>) -> i32 {
    let stand_pat = evaluate(pos, ply, elo);
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
        let score = quiescence_search(&next_pos, alpha, beta, limit - 1, ply + 1, elo);

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

pub fn search(pos: &Chess, depth: u8, mut alpha: i32, mut beta: i32, ply: u8, elo: Option<u16>) -> (Option<Move>, i32) {
    if pos.is_game_over() {
        return (None, evaluate(pos, ply, elo));
    }
    if depth == 0 {
        return (None, quiescence_search(pos, alpha, beta, 4, ply, elo));
    }

    let mut best_move = None;
    let is_white = pos.turn() == Color::White;
    let mut best_score = if is_white { -20000 } else { 20000 };

    let moves = pos.legal_moves();
    if moves.is_empty() {
        return (None, evaluate(pos, ply, elo));
    }

    for m in moves {
        let mut next_pos = pos.clone();
        next_pos.play_unchecked(&m);
        let (_, score) = search(&next_pos, depth - 1, alpha, beta, ply + 1, elo);

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
