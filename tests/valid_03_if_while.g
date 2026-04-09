principal {
    x: int;
} {
    x = 1;
    se (x < 10) entao enquanto (x < 5) x = x + 1; fimse
}
