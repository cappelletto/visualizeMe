% # -*- coding: utf-8 -*-
% """
% Copyright (c) 2022, Ocean Perception Lab, Univ. of Southampton
% All rights reserved.
% Licensed under GNU General Public License v3.0
% See LICENSE file in the project root for full license information.
% """
% Author: Jose Cappelletto (j.cappelletto@soton.ac.uk) 
% Version: 0.3-alpha
% Date: 31/12/2021

% Retrieve and process training / validation results from trained BNN predictor

function plot_bnn_loss(folder_path, dataset_key, y_max)

% Check if folder_path is not defined
if ~exist('folder_path', 'var')
    warning ("Path to folder with training/validation CSV files not defined.")
    folder_path = './'
end

% Check if dataset = train/valid option defined. Default analyze validation
if ~exist ('dataset_key', 'var') 
    warning ("Using default dataset subset: validation")
    dataset_key = 'valid'
else % it as defined by user, let's validate it
    if (strcmp (dataset_key, 'train'))
        sprintf ("Processing a Training dataset")
    elseif (strcmp (dataset_key, 'valid'))
        sprintf ("Processing a Validation dataset")
    else
        sprintf (strcat("Error, unknown dataset_key provided: ", dataset_key))
        return
    end
end

folder_path = strcat ( folder_path, "/", dataset_key, "/")
% Retrieve the list of files in the folder that correspond to the subset
files = dir (strcat(folder_path, dataset_key, '_*.csv'));

K = length(files)   % Number of files
% Use all the rows in the train/validation output for the last exported training epoch
% Create empty vector to store the mean values of train/validation fit (RMSE)
mean_error = zeros(K,1);
length_meter   = zeros(K,1);
% for each file, we read the data, first row contains the column names
% and the rest of the rows contain the data
for i = 1:K
    data = readtable(strcat(folder_path,files(i).name));
    % Extract the length parameter from the file name
    % name sample: train_output_L64m_K01
    fln = files(i).name(15:end-9);
    length_meter(i) = str2double(fln); % it will be in L<length_meter>m.csv format

    % TODO: Use variable name to determine which column is target/pred
    target    = data{:,1};  % First column is the target value
    predicted = data{:,2};  % Second column is the predicted value

    % If the column name (table.Properties.VariablesNames) contains 'log' then data needs to be converted back
    % Enable /disable depending if we are using logNormal or no transformation at all
    
    % Retrieve the table VariableNames (in properties)
    if (strfind (data.Properties.VariableNames{1}, 'log') > 0)
        sprintf ("Log transform detected in variable names") 
        target    = 10.^target;
        predicted = 10.^predicted;
    end

    if (strfind (data.Properties.VariableNames{1}, 'exp') > 0)
        sprintf ("Exp transform detected in variable names") 
        target    = 10.*log(target);     % Original data was transformed using E^(x/10)
        predicted = 10.*log(predicted);
    end

    % Compute the RMSE of our predictions
    error = rms(target - predicted);
    mean_error(i) = error;
end

% Pack data for sorting
data_matrix = [length_meter, mean_error];
% Sort data by column 1: length_meter
data_sorted = sortrows(data_matrix,1);
% Unpack data
length_meter   = data_sorted(:,1);
mean_error = data_sorted(:,2);

% Show the min, mean and the max value of the error
min_error = min(mean_error)
mean_error_total = mean(mean_error)
max_error = max(mean_error)

% Find unique entries in length_meter
length_meter_unique = unique(length_meter);
% Create empty vector to store the mean values of train/validation fit (RMSE)
mean_error_unique = zeros(length(length_meter_unique),1);
% Create empty vector to store the standard deviation of train/validation fit (RMSE)
std_error_unique = zeros(length(length_meter_unique),1);

% For each unique length parameter, aggregate all replicas
for i = 1:length(length_meter_unique)
    % Find all replicas of the same length parameter
    idx = find(length_meter == length_meter_unique(i));
    % Aggregate the mean values of the last N epochs of loss_recon
    mean_error_unique(i) = mean(mean_error(idx));
    std_error_unique(i) = std(mean_error(idx));
end

if (strfind(dataset_key, 'train') > 0)
    edgeColor = [0 0.4470 0.7410]; % Blue-ish
    YLabelString = 'RMSE - Prediction error for Trainng dataset';
    titleLabelString = 'BNN - Training loss vs distance parameter';
else % we should check it is 'valid' otherwise is an error (invalid key defined)
    edgeColor = [0.8500 0.3250 0.0980]; % Red-ish
    YLabelString = 'RMSE - Prediction error for Validation dataset';
    titleLabelString = 'BNN - Validation loss vs distance parameter';
end


% Before plotting, we create an empty figure
figure; hold on; grid on;
% Plot the loss function. X = length_meter, Y = loss
% scatter(length_meter_unique, mean_error_unique, 'b', 'LineWidth', 2, 'MarkerEdgeAlpha', 0.2);
%plot (length_meter_unique, mean_train_fit_unique, 'Color', [0, 0, 1, 0.2], 'LineWidth', 1.5);

% We can plot the boxplot of each loss function using the unique index of the length parameter
% For each unique length parameter, show the box plot of the loss functions for training dataset
for i = 1:length(length_meter_unique)
    % Find all replicas of the same length parameter
    idx = find(length_meter == length_meter_unique(i));
    % Aggregate the mean values of the last N epochs of loss_recon
    boxplot(mean_error(idx), 'positions', length_meter_unique(i), 'widths', 3, 'colors', edgeColor);

    % show the mean error when i=1
    if (i == 1)
        mean_none = mean(mean_error(idx))
    end
end
% Set gca  xtick labels and positions to a regular grid that divides the x axis into N equal intervals
xgrid = linspace(0, max(length_meter), 11);
set(gca, 'XTick', xgrid, 'XTickLabel', xgrid);
xlabel('Distance parameter (m)', 'FontSize', 16);
ylabel( YLabelString, 'FontSize', 16);
if ~exist('y_max','var') % User defined ylimits (for figure comparison)
    ylim([0 max(mean_error)*1.05])
else
    ylim([0 y_max])
end
% Add a line to the plot with the mean error
plot([0 max(length_meter)], [mean_error_total mean_error_total], 'r--', 'LineWidth', 1);
% Add floating text on top of the line with the mean error
text(max(length_meter)*0.8, mean_error_total*1.1, sprintf('Mean error: %.2f', mean_error_total), 'Color', 'r', 'FontSize', 16);
legend ('RMSE of predictions',  FontSize=16);
title (titleLabelString, FontSize = 18);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Before plotting, we create an empty figure
figure; hold on; grid on;
% Plot the loss function. X = length_meter, Y = loss
scatter(length_meter, mean_error, 'b', 'LineWidth', 2, 'MarkerEdgeAlpha', 0.3, 'MarkerEdgeColor', edgeColor);
xlabel('Distance parameter (m)', 'FontSize', 16);
ylabel( YLabelString, 'FontSize', 16);
if ~exist('y_max','var') % User defined ylimits (for figure comparison)
    ylim([0 max(mean_error)*1.05])
else
    ylim([0 y_max])
end

title (titleLabelString, FontSize = 18);
% Add a line to the plot with the mean error
plot([0 max(length_meter)], [mean_error_total mean_error_total], 'r--', 'LineWidth', 1);
legend ('RMSE of predictions', "Mean error: " + num2str(mean_error_total), FontSize=16);

% TODO: Replace scatter plot with violin or boxplots (compute mean/stdv)