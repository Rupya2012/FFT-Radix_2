import scipy.io as sio
import numpy as np

mat = sio.loadmat('golden_fft_reference.mat')
inp = mat['complex_input'].flatten()

def to_q(val):
    re = int(round(val.real * 16384))
    im = int(round(val.imag * 16384))
    return re, im

def bitrev(val, width=12):
    return int('{:0{w}b}'.format(val, w=width)[::-1], 2)

print("=== Golden Stage 1 Butterflies ===")
for k in range(4):
    idx1 = bitrev(2*k, 12)
    idx2 = bitrev(2*k + 1, 12)
    x1_r, x1_i = to_q(inp[idx1])
    x2_r, x2_i = to_q(inp[idx2])
    y1_r = (x1_r + x2_r) // 2
    y1_i = (x1_i + x2_i) // 2
    y2_r = (x1_r - x2_r) // 2
    y2_i = (x1_i - x2_i) // 2
    print(f"BF {k}: idx1={idx1} (Addr {idx1//2} {'MSB' if idx1%2==0 else 'LSB'}), idx2={idx2} (Addr {idx2//2} {'MSB' if idx2%2==0 else 'LSB'})")
    print(f"      x1=({x1_r:6d}, {x1_i:6d}i), x2=({x2_r:6d}, {x2_i:6d}i)")
    print(f"   -> y1=({y1_r:6d}, {y1_i:6d}i), y2=({y2_r:6d}, {y2_i:6d}i)")
