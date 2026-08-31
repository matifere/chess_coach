use crate::engine;
use shakmaty::{Chess, fen::Fen, CastlingMode, Position};

#[flutter_rust_bridge::frb(sync)]
pub fn init_nnue(bytes: Vec<u8>) -> bool {
    engine::load_nnue_bytes(&bytes)
}

pub fn analyze_position(fen: String) -> i32 {
    let setup = match Fen::from_ascii(fen.as_bytes()) {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let pos: Chess = match setup.into_position(CastlingMode::Standard) {
        Ok(p) => p,
        Err(_) => return 0,
    };
    engine::evaluate(&pos, 0)
}

pub fn get_best_move(fen: String, depth: u8) -> String {
    let setup = match Fen::from_ascii(fen.as_bytes()) {
        Ok(s) => s,
        Err(_) => return String::new(),
    };
    let pos: Chess = match setup.into_position(CastlingMode::Standard) {
        Ok(p) => p,
        Err(_) => return String::new(),
    };
    let (best_move, _) = engine::search(&pos, depth, -20000, 20000, 0);
    
    match best_move {
        Some(m) => m.to_uci(CastlingMode::Standard).to_string(),
        None => String::new(),
    }
}

pub fn evaluate_with_search(fen: String, depth: u8) -> i32 {
    let setup = match Fen::from_ascii(fen.as_bytes()) {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let pos: Chess = match setup.into_position(CastlingMode::Standard) {
        Ok(p) => p,
        Err(_) => return 0,
    };
    let (_, score) = engine::search(&pos, depth, -20000, 20000, 0);
    score
}
