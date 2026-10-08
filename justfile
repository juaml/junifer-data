default:
    just --list

julich-brain:
    ./get_siibra_julich_brain.py

brainnetome:
    ./convert_brainnetome_labels.py
