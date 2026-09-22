import json

with open('/mnt/hdd2t/prog/chess_coach/assets/openings.json', 'r') as f:
    tree = json.load(f)

try:
    c = tree['c']['e2e4']['c']['c7c6']['c']['d2d4']['c']['d7d5']['c']
    for move, node in c.items():
        name = node.get('n', 'No name')
        print(f"Move: {move}, Name: {name}, Subtree size: {len(str(node))}")
except KeyError as e:
    print(f"Key error: {e}")
