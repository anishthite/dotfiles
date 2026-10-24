bin/bar_art: bar_art.m ../event_providers/sketchybar.h | bin
	clang -O2 -fobjc-arc -framework Foundation -framework CoreGraphics -framework ImageIO $< -o $@

bin:
	mkdir bin
