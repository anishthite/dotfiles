#!/bin/sh
# Readability test card: run in kitty, then flip presets with ctrl+cmd+0..5
e=$(printf '\033')
echo "Prose:  The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs."
echo "Shapes: Il1| O0o rnm cl d S5 Z2 B8 {}[]() ;:,. \`'\" -- ~= != <= >= => -> |> ::"
echo "Code:   const total = items.filter((x) => x.size > 0).reduce((a, b) => a + b.size, 0);"
echo "${e}[1mBold:   function readability(lineHeight, letterSpacing) { return true; }${e}[0m"
echo "${e}[3mItalic: // comments and docstrings usually render in italics${e}[0m"
echo "${e}[90mDim:    zsh autosuggestions, git hints and code comments use this gray${e}[0m"
for i in 31 32 33 34 35 36 37 91 92 94 95; do printf "${e}[${i}m%s${e}[0m  " "color $i: error src/main.rs:42"; [ $i = 34 ] && echo; done; echo
echo "${e}[30;47m black-on-white ${e}[0m ${e}[30m<- color0 text (often near-invisible)${e}[0m"
