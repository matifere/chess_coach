import subprocess
import time

p = subprocess.Popen(['stockfish'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)

p.stdin.write("position startpos moves e2e4 g8f6 e4e5\ngo depth 10\n")
p.stdin.flush()

for i in range(20):
    line = p.stdout.readline().strip()
    print(line)
    if "bestmove" in line:
        break

print("---")

p.stdin.write("position startpos moves e2e4 g8f6 e4e5 b8c6\ngo depth 10\n")
p.stdin.flush()

for i in range(20):
    line = p.stdout.readline().strip()
    print(line)
    if "bestmove" in line:
        break

p.terminate()
