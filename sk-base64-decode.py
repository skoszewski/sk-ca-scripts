#!/usr/bin/env python

import sys
import base64
import argparse

parser = argparse.ArgumentParser(description="Decode a file with BASE64 encoding.")
parser.add_argument('-i', '--input-file', type=str, help='Input file pathname.')
parser.add_argument('-o', '--output-file', type=str, help='Output file pathname.')

args = parser.parse_args()

if args.input_file:
    f = open(args.input_file, 'r')
    encoded = f.read()
    f.close()
else:
    encoded = sys.stdin.read()

if args.output_file:
    f = open(args.output_file, 'wb')
    f.write(base64.b64decode(encoded))
    f.close()
else:
    sys.stdout.buffer.write(base64.b64decode(encoded))
