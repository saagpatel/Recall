.PHONY: run export clean

run:
	godot --path . --editor

export:
	godot --headless --export-release "Linux" build/game

clean:
	rm -rf build/ .godot/imported/
