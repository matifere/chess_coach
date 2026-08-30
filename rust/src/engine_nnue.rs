use nnue_rs::{Board, Color as NnueColor, Piece as NnuePiece, PieceKind, Network};
use shakmaty::{Chess, Position, Role, Color, Square};

pub struct ShakmatyBoard<'a> {
    pub pos: &'a Chess,
}

impl<'a> Board for ShakmatyBoard<'a> {
    fn side_to_move(&self) -> NnueColor {
        match self.pos.turn() {
            Color::White => NnueColor::White,
            Color::Black => NnueColor::Black,
        }
    }

    fn king_square(&self, color: NnueColor) -> u8 {
        let sc = match color {
            NnueColor::White => Color::White,
            NnueColor::Black => Color::Black,
        };
        let bitboard = self.pos.board().king() & self.pos.board().by_color(sc);
        bitboard.first().map(|sq| sq.u32() as u8).unwrap_or(0)
    }

    fn for_each_piece(&self, f: &mut dyn FnMut(u8, NnuePiece)) {
        let board = self.pos.board();
        for sq_idx in 0..64 {
            let sq = Square::new(sq_idx);
            if let Some(piece) = board.piece_at(sq) {
                let color = match piece.color {
                    Color::White => NnueColor::White,
                    Color::Black => NnueColor::Black,
                };
                let kind = match piece.role {
                    Role::Pawn => PieceKind::Pawn,
                    Role::Knight => PieceKind::Knight,
                    Role::Bishop => PieceKind::Bishop,
                    Role::Rook => PieceKind::Rook,
                    Role::Queen => PieceKind::Queen,
                    Role::King => PieceKind::King,
                };
                f(sq_idx as u8, NnuePiece { color, kind });
            }
        }
    }
}
