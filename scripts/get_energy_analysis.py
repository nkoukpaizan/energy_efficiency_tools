import sys
import argparse
import energy_analysis as scripts

parser = argparse.ArgumentParser( description="Plot power profile.")
parser.add_argument('--input_dir', dest='input_dir', type=str, help='Input directory where stats and counters dirs are located', default=None, nargs='+' )
parser.add_argument('--edp_alpha', dest='edp_alpha', type=float, help='EDP alpha value', default=1.0 )
parser.add_argument('--edp_beta', dest='edp_beta', type=float, help='EDP beta value', default=1.0 )
args = parser.parse_args()

if args.input_dir is None:
  print("ERROR: You need to pass the path to the directory containing the rocprof output")
  sys.exit(1)

input_dirs = args.input_dir
edp_alpha = args.edp_alpha
edp_beta = args.edp_beta

scripts.energy_analysis(input_dirs, edp_alpha, edp_beta)