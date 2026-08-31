#!/bin/bash

# Función auxiliar
make_svg() {
  local name=$1
  local color=$2
  local text=$3
  local fontsize=$4
  
  cat << INNER_EOF > "assets/badges/${name}.svg"
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="45" fill="${color}" stroke="white" stroke-width="8"/>
  <text x="50" y="72" text-anchor="middle" font-family="Arial, sans-serif" font-weight="900" font-size="${fontsize}" font-style="italic" fill="white">${text}</text>
</svg>
INNER_EOF
}

# Generamos las de texto
make_svg "brilliant" "#00BCD4" "!!" 50
make_svg "great" "#536DFE" "!" 60
make_svg "inaccuracy" "#FFC107" "?!" 50
make_svg "mistake" "#FF9800" "?" 60
make_svg "blunder" "#F44336" "??" 50

# Generamos los de iconos con paths (Best, Excellent, Good, Book)
cat << 'INNER_EOF' > assets/badges/best.svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="45" fill="#4CAF50" stroke="white" stroke-width="8"/>
  <path d="M50 20 l9 27 h28 l-23 16 l9 27 l-23 -16 l-23 16 l9 -27 l-23 -16 h28 z" fill="white"/>
</svg>
INNER_EOF

cat << 'INNER_EOF' > assets/badges/excellent.svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="45" fill="#4CAF50" stroke="white" stroke-width="8"/>
  <path d="M30 50 l15 15 l30 -30" fill="none" stroke="white" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
INNER_EOF

cat << 'INNER_EOF' > assets/badges/good.svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="45" fill="#81C784" stroke="white" stroke-width="8"/>
  <path d="M35 70 h-10 v-30 h10 z M35 40 c0 -15 10 -20 15 -20 c5 0 5 10 5 10 l-5 10 h20 c5 0 10 5 10 10 l-5 20 h-40 z" fill="white" stroke="white" stroke-width="2" stroke-linejoin="round"/>
</svg>
INNER_EOF

cat << 'INNER_EOF' > assets/badges/book.svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="45" fill="#795548" stroke="white" stroke-width="8"/>
  <path d="M30 30 c10 -5 20 -5 20 0 v40 c0 -5 -10 -5 -20 0 z M50 30 c10 -5 20 -5 20 0 v40 c0 -5 -10 -5 -20 0 z" fill="none" stroke="white" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
INNER_EOF

