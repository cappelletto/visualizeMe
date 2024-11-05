import os
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import argparse

# Improved function to handle CSV files with various distance parameters
def plot_bnn_loss(folder_path, dataset_key='valid', y_max=None, output_plot=None):
    # Construct folder path based on dataset key
    folder_path = os.path.join(folder_path, dataset_key)
    
    # Get list of CSV files matching the dataset key in the name
    file_pattern = os.path.join(folder_path, f'{dataset_key}_*.csv')
    files = glob.glob(file_pattern)
    
    # Initialize arrays to store results
    mean_error = []
    length_meter = []
    
    # Process each file to compute RMSE
    for file_path in files:
        # Read CSV data
        data = pd.read_csv(file_path)
        
        # Extract length from filename using regex to handle various formats
        file_name = os.path.basename(file_path)
        length_str = ''.join(filter(str.isdigit, file_name.split('_L')[1].split('m')[0]))
        if length_str.isdigit():
            length = float(length_str)
            length_meter.append(length)
        else:
            continue
        
        # Get target and prediction columns
        target = data.iloc[:, 0]
        predicted = data.iloc[:, 1]
        
        # Check for transformations in column names
        if 'log' in data.columns[0].lower():
            target = 10 ** target
            predicted = 10 ** predicted
        elif 'exp' in data.columns[0].lower():
            target = 10 * np.log(target)
            predicted = 10 * np.log(predicted)
        
        # Calculate RMSE
        error = np.sqrt(np.mean((target - predicted) ** 2))
        mean_error.append(error)
    
    # Convert lists to arrays for sorting and aggregation
    length_meter = np.array(length_meter)
    mean_error = np.array(mean_error)
    
    # Sort by length
    sorted_indices = np.argsort(length_meter)
    length_meter = length_meter[sorted_indices]
    mean_error = np.sqrt(mean_error[sorted_indices])
    
    # Calculate unique length statistics
    unique_lengths = np.unique(length_meter)
    mean_error_unique = [np.mean(mean_error[length_meter == length]) for length in unique_lengths]
    std_error_unique = [np.std(mean_error[length_meter == length]) for length in unique_lengths]
    
    # Define color and labels based on dataset key
    if dataset_key == 'train':
        edge_color = (0, 0.447, 0.741)
        ylabel = 'RMSE - Prediction error for Training dataset'
        title_label = 'BNN - Training loss vs distance parameter'
    else:
        edge_color = (0.850, 0.325, 0.098)
        ylabel = 'RMSE - Prediction error for Validation dataset'
        title_label = 'BNN - Validation loss vs distance parameter'
    
    # Plotting
    # Figure 1: Box plot of RMSE per unique length
    plt.figure()
    plt.grid(True)
    for i, length in enumerate(unique_lengths):
        idx = np.where(length_meter == length)
        plt.boxplot(mean_error[idx], positions=[length], widths=3, boxprops=dict(color=edge_color))
    
    plt.xlabel('Distance parameter (m)', fontsize=16)
    plt.ylabel(ylabel, fontsize=16)
    plt.ylim(0, y_max if y_max else max(mean_error) * 1.05)
    plt.title(title_label, fontsize=20)
    plt.plot([0, max(length_meter)], [np.mean(mean_error)] * 2, 'r--', linewidth=1)
    plt.text(max(length_meter) * 0.8, np.mean(mean_error) * 1.1, f'Mean error: {np.mean(mean_error):.2f}', color='r', fontsize=16)
    plt.legend(['Mean RMSE'], fontsize=18)
    
    # Save or show the first plot
    if output_plot:
        plt.savefig(f"{output_plot}_boxplot.png")
    else:
        plt.show()
    
    # Figure 2: Scatter plot of RMSE for all lengths
    plt.figure()
    plt.grid(True)
    plt.scatter(length_meter, mean_error, color=edge_color, alpha=0.3)
    plt.xlabel('Distance parameter (m)', fontsize=16)
    plt.ylabel(ylabel, fontsize=16)
    plt.ylim(0, y_max if y_max else max(mean_error) * 1.05)
    plt.title(title_label, fontsize=20)
    plt.plot([0, max(length_meter)], [np.mean(mean_error)] * 2, 'r--', linewidth=1)
    plt.legend(['Mean RMSE'], fontsize=18)
    
    # Save or show the second plot
    if output_plot:
        plt.savefig(f"{output_plot}_scatter.png")
    else:
        plt.show()

def main():
    # Argument parser for CLI
    parser = argparse.ArgumentParser(description='Process BNN prediction loss results and plot RMSE.')
    parser.add_argument('folder_path', type=str, help='Path to the folder containing CSV files.')
    parser.add_argument('--dataset_key', type=str, default='valid', choices=['train', 'valid'], help='Dataset key to specify either "train" or "valid". Default is "valid".')
    parser.add_argument('--y_max', type=float, default=None, help='Optional upper limit for y-axis on the plot.')
    parser.add_argument('--output_plot', type=str, default=None, help='File path to save the plot images. If not provided, plots will be shown directly.')

    args = parser.parse_args()
    
    # Call the function with parsed arguments
    plot_bnn_loss(folder_path=args.folder_path, dataset_key=args.dataset_key, y_max=args.y_max, output_plot=args.output_plot)

if __name__ == '__main__':
    main()
