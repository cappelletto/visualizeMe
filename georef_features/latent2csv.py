

# Convert Numpy file containing latent representation to CSV file. No aguments/parameters used

import numpy as np
import pandas as pd
import argparse
import os, sys

# def handler(signum, frame):
#     Console.warn ("CTRL + C pressed. Stopping...")
#     exit(1)

def main(args=None):
    description_str = "dataProcessing module: [latent2csv] converts numpy array of latent representations into CSV files for BNN compatible training phase"
    formatter = lambda prog: argparse.HelpFormatter(prog, width=120)
    parser = argparse.ArgumentParser(description=description_str, formatter_class=formatter)
    # argparse.HelpFormatter(parser,'width=120')
    parser.add_argument(
    "-i", "--input",
    type=str,
    # default='input_latents.csv',
    help="Path to numpy file containing the latent representation vectors for each entry (image)"
    )

    # output #########################
    parser.add_argument(
        "-o", "--output",
        # default='inferred.csv',
        type=str,
        help="Filename of the exported CSV output. Rows follow the same order as defined in the input file."
    )

    # key #########################
    parser.add_argument(
        "-k", "--key",
#        default='key',
        type=str,
        help="Defines output file column prefix. Default is 'latent_'"
    )

    print ("Start")
    args = parser.parse_args(args)
    if len(sys.argv) == 1 and args is None: # no argument passed? show help as some parameters were expected
        parser.print_help(sys.stderr)
        sys.exit(2)


    # Default values
    input_file = "latents.npy"
    output_file = "latents.csv"

    if (args.input):    # user provided input filename
        input_file = args.input
        print ("User defined input filename: " + input_file)
    else:
        # use default filename
        print ("Using default input filename: " + input_file)

    if os.path.isfile(input_file):
        print("Input file:\t", input_file)
    else:
        print("Input file [" + input_file + "] not found. Please check the provided input path (-i, --input)")
        exit(1)    # error, end

    if (args.output):    # user provided input filename
        output_file = args.output
        print ("User-defined output filename: " + output_file)
    else:
        # use default filename
        print ("Using default output filename: " + output_file)

    if (args.key):
        output_key = args.key
        print("Using user-defined latent column prefix:\t[", output_key, "]")
    else:
        output_key = 'latent_'
        print("Using default latent column prefix:     \t[", output_key, "]")

    latents_np = np.load(input_file)
    # Convert the numpy array to a pandas dataframe
    # Retrieve number of latents dimensions = number of columns
    latents_dim = latents_np.shape[1]
    # Retrieve number of entries = number of rows
    entries = latents_np.shape[0]

    # Print the number of entries and latents dimensions
    print("Total entries:", entries)
    print("Latents dimensions:", latents_dim)

    # create header for the dataframe with the string "latent_" + number
    header = ["output_key" + str(i) for i in range(latents_dim)]
    # create a dataframe with the header and the entries
    df = pd.DataFrame(latents_np, index=None, columns=header)
    # save the dataframe to a csv file
    df.to_csv(output_file)

if __name__ == '__main__':
    main()
