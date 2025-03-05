#!/usr/bin/env python

import sys
import base64
import argparse

parser = argparse.ArgumentParser(description="Encode a file with BASE64 encoding for copy/paste from the terminal.")
parser.add_argument('-i', '--input-file', type=str, help='Input file pathname.')
parser.add_argument('-o', '--output-file', type=str, help='Output file pathname.')

args = parser.parse_args()

if args.input_file:
    with open(args.input_file, 'rb') as f:
        binary = f.read()
else:
    binary = sys.stdin.buffer.read()

if args.output_file:
    with open(args.output_file, 'w') as f:
        f.write(base64.b64encode(binary).decode('ascii'))
else:
    sys.stdout.write(str(base64.b64encode(binary)).decode('ascii'))
