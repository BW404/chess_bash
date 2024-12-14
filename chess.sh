# Initialize the chessboard
initialize_board() {
  board=(
    "♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜"
    "♟ ♟ ♟ ♟ ♟ ♟ ♟ ♟"
    ". . . . . . . ."
    ". . . . . . . ."
    ". . . . . . . ."
    ". . . . . . . ."
    "♙ ♙ ♙ ♙ ♙ ♙ ♙ ♙"
    "♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖"
  )
}

# Display the chessboard
display_board() {
  echo "    a   b   c   d   e   f   g   h"
  echo "  +---+---+---+---+---+---+---+---+"
  for i in {0..7}; do
    echo -n "$((8-i)) |"
    for j in {0..7}; do
      echo -n " ${board[i]:$((j*2)):1} |"
    done
    echo " $((8-i))"
    echo "  +---+---+---+---+---+---+---+---+"
  done
  echo "    a   b   c   d   e   f   g   h"
}

# Get piece at a specific position
get_piece() {
  echo "${board[$1]:$((2*$2)):1}"
}

# Set piece at a specific position
set_piece() {
  local row=$1 col=$2 piece=$3
  board[$row]="${board[$row]:0:$((2*$col))}$piece${board[$row]:$((2*$col+1))}"
}

# Move a piece
move_piece() {
  local from=$1 to=$2
  local from_row=$((8-${from:1:1}))
  local from_col=$(( $(ord ${from:0:1}) - $(ord a) ))
  local to_row=$((8-${to:1:1}))
  local to_col=$(( $(ord ${to:0:1}) - $(ord a) ))
  local piece=$(get_piece $from_row $from_col)

  set_piece $from_row $from_col "."
  set_piece $to_row $to_col "$piece"
}

# Helper to convert a character to its ASCII value
ord() {
  LC_CTYPE=C printf '%d' "'${1}"
}

# Validate if a move is legal (simplified rules)
validate_move() {
  local piece=$1 from_row=$2 from_col=$3 to_row=$4 to_col=$5
  local dr=$((to_row - from_row)) dc=$((to_col - from_col))

  case "$piece" in
    ♙) 
      # Forward movement
      if [[ $dr -eq -1 && $dc -eq 0 && $(get_piece $to_row $to_col) == "." ]]; then
        return 0
      # Initial two-square movement
      elif [[ $dr -eq -2 && $dc -eq 0 && from_row -eq 6 && $(get_piece $((to_row + 1)) $to_col) == "." && $(get_piece $to_row $to_col) == "." ]]; then
        return 0
      # Capture diagonally
      elif [[ $dr -eq -1 && ${dc#-} -eq 1 && $(get_piece $to_row $to_col) =~ [♟♜♞♝♛♚] ]]; then
        return 0
      fi
      ;;
    ♟) 
      # Forward movement
      if [[ $dr -eq 1 && $dc -eq 0 && $(get_piece $to_row $to_col) == "." ]]; then
        return 0
      # Initial two-square movement
      elif [[ $dr -eq 2 && $dc -eq 0 && from_row -eq 1 && $(get_piece $((to_row - 1)) $to_col) == "." && $(get_piece $to_row $to_col) == "." ]]; then
        return 0
      # Capture diagonally
      elif [[ $dr -eq 1 && ${dc#-} -eq 1 && $(get_piece $to_row $to_col) =~ [♙♖♘♗♕♔] ]]; then
        return 0
      fi
      ;;
    ♖|♜) 
      if [[ $dr -eq 0 || $dc -eq 0 ]]; then
        # Check if destination has opponent's piece or is empty
        local dest_piece=$(get_piece $to_row $to_col)
        if [[ "$piece" == "♖" && ( "$dest_piece" == "." || "$dest_piece" =~ [♟♜♞♝♛♚] ) ]] || \
           [[ "$piece" == "♜" && ( "$dest_piece" == "." || "$dest_piece" =~ [♙♖♘♗♕♔] ) ]]; then
          check_rook_path $from_row $from_col $to_row $to_col && return 0
        fi
      fi
      ;;
    ♘|♞)
      # Knight moves in L-shape: 2 squares in one direction and 1 square perpendicular
      if [[ ( ${dr#-} -eq 2 && ${dc#-} -eq 1 ) || ( ${dr#-} -eq 1 && ${dc#-} -eq 2 ) ]]; then
        local dest_piece=$(get_piece $to_row $to_col)
        if [[ "$piece" == "♘" && ( "$dest_piece" == "." || "$dest_piece" =~ [♟♜♞♝♛♚] ) ]] || \
           [[ "$piece" == "♞" && ( "$dest_piece" == "." || "$dest_piece" =~ [♙♖♘♗♕♔] ) ]]; then
          return 0
        fi
      fi
      ;;
    ♗|♝) 
      if [[ ${dr#-} -eq ${dc#-} ]]; then
        local dest_piece=$(get_piece $to_row $to_col)
        if [[ "$piece" == "♗" && ( "$dest_piece" == "." || "$dest_piece" =~ [♟♜♞♝♛♚] ) ]] || \
           [[ "$piece" == "♝" && ( "$dest_piece" == "." || "$dest_piece" =~ [♙♖♘♗♕♔] ) ]]; then
          check_bishop_path $from_row $from_col $to_row $to_col && return 0
        fi
      fi
      ;;
    ♕|♛) 
      local dest_piece=$(get_piece $to_row $to_col)
      if [[ $dr -eq 0 || $dc -eq 0 || ${dr#-} -eq ${dc#-} ]]; then
        if [[ "$piece" == "♕" && ( "$dest_piece" == "." || "$dest_piece" =~ [♟♜♞♝♛♚] ) ]] || \
           [[ "$piece" == "♛" && ( "$dest_piece" == "." || "$dest_piece" =~ [♙♖♘♗♕♔] ) ]]; then
          if [[ $dr -eq 0 || $dc -eq 0 ]]; then
            check_rook_path $from_row $from_col $to_row $to_col && return 0
          else
            check_bishop_path $from_row $from_col $to_row $to_col && return 0
          fi
        fi
      fi
      ;;
    ♔|♚) 
      if [[ ${dr#-} -le 1 && ${dc#-} -le 1 ]]; then
        local dest_piece=$(get_piece $to_row $to_col)
        if [[ "$piece" == "♔" && ( "$dest_piece" == "." || "$dest_piece" =~ [♟♜♞♝♛♚] ) ]] || \
           [[ "$piece" == "♚" && ( "$dest_piece" == "." || "$dest_piece" =~ [♙♖♘♗♕♔] ) ]]; then
          return 0
        fi
      fi
      ;;
  esac
  return 1
}

# Check path for rook movement
check_rook_path() {
  local from_row=$1 from_col=$2 to_row=$3 to_col=$4
  if [[ $from_row -eq $to_row ]]; then
    local start_col=$((from_col < to_col ? from_col + 1 : to_col + 1))
    local end_col=$((from_col < to_col ? to_col : from_col))
    for ((col = start_col; col < end_col; col++)); do
      if [[ $(get_piece $from_row $col) != "." ]]; then
        return 1
      fi
    done
  else
    local start_row=$((from_row < to_row ? from_row + 1 : to_row + 1))
    local end_row=$((from_row < to_row ? to_row : from_row))
    for ((row = start_row; row < end_row; row++)); do
      if [[ $(get_piece $row $from_col) != "." ]]; then
        return 1
      fi
    done
  fi
  return 0
}

# Check path for bishop movement
check_bishop_path() {
  local from_row=$1 from_col=$2 to_row=$3 to_col=$4
  local dr=$((to_row - from_row))
  local dc=$((to_col - from_col))
  local row_step=$(( dr / ${dr#-} ))
  local col_step=$(( dc / ${dc#-} ))
  local row=$((from_row + row_step))
  local col=$((from_col + col_step))

  while [[ $row != $to_row && $col != $to_col ]]; do
    if [[ $(get_piece $row $col) != "." ]]; then
      return 1
    fi
    row=$((row + row_step))
    col=$((col + col_step))
  done
  return 0
}

# Validate input format
validate_input_format() {
  [[ $1 =~ ^[a-h][1-8]$ ]]
}

# Check if the piece belongs to the current player
is_player_piece() {
  local piece=$1
  if [[ "$current_player" == "White" && "$piece" =~ [♙♖♗♕♔] ]]; then
    return 0
  elif [[ "$current_player" == "Black" && "$piece" =~ [♟♜♞♝♛♚] ]]; then
    return 0
  fi
  return 1
}

# Check for checkmate or stalemate
check_for_checkmate() {
  local king_pos
  local opponent_piece
  local can_move=0
  local king_symbol=$([[ "$current_player" == "White" ]] && echo "♔" || echo "♚")

  # Find the current player's king
  for row in {0..7}; do
    for col in {0..7}; do
      piece=$(get_piece $row $col)
      if [[ "$piece" == "$king_symbol" ]]; then
        king_pos="$row $col"
      fi
    done
  done

  for row in {0..7}; do
    for col in {0..7}; do
      opponent_piece=$(get_piece $row $col)
      if [[ "$opponent_piece" =~ ♟|♜|♞|♝|♛|♚ ]]; then
        for target_row in {0..7}; do
          for target_col in {0..7}; do
            if validate_move "$opponent_piece" "$row" "$col" "$target_row" "$target_col"; then
              can_move=1
              break 2
            fi
          done
        done
      fi
    done
  done

  if [[ $can_move -eq 0 ]]; then
    echo "Checkmate! White wins!"
    exit 0
  fi
}

# Main game loop
play_game() {
  current_player="White"
  initialize_board

  while true; do
    clear
    display_board
    echo "$current_player's turn"
    echo -n "Enter move (e.g., e2 e4): "
    read -r from to

    # Check if both from and to are provided
    if [[ -z "$from" || -z "$to" ]]; then echo "Error: You must enter both a starting and a destination position!"
      sleep 2
      continue
    fi

    if ! validate_input_format "$from" || ! validate_input_format "$to"; then
      echo "Error: Invalid input format! Use notation like 'e2' or 'e4'."
      sleep 2
      continue
    fi

    from_row=$((8-${from:1:1}))
    from_col=$(( $(ord ${from:0:1}) - $(ord a) ))
    to_row=$((8-${to:1:1}))
    to_col=$(( $(ord ${to:0:1}) - $(ord a) ))

    piece=$(get_piece "$from_row" "$from_col")

    if ! is_player_piece "$piece"; then
      echo "Error: You can only move your pieces!"
      sleep 2
      continue
    fi

    if validate_move "$piece" "$from_row" "$from_col" "$to_row" "$to_col"; then
      move_piece "$from" "$to"

      # Check for checkmate or stalemate
      check_for_checkmate

      current_player=$([[ "$current_player" == "White" ]] && echo "Black" || echo "White")
    else
      echo "Invalid move, try again!"
      sleep 2
    fi
  done
}

# Start the game
play_game
