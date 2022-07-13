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

function bnn_loss_test(folder_path, dataset_key)

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
        print ("Processing a Training dataset")
    elseif (strcmp (dataset_key, 'valid'))
        print ("Processing a Validation dataset")
    else
        print (strcat("Error, unknown dataset_key provided: ", dataset_key))
        return
    end
end

% Retrieve the list of files in the folder that correspond to the subset
files = dir (strcat(folder_path, strcat (dataset_key, '_*.csv')));

K = length(files)   % Number of files
% Use all the rows in the train/validation output for the last exported training epoch
% Create empty vector to store the mean values of train/validation fit (RMSE)
mean_train_fit = zeros(K,1);
mean_valid_fit = zeros(K,1);
length_meter   = zeros(K,1);

% for each file, we read the data, first row contains the column names
% and the rest of the rows contain the data
for i = 1:K
    data = readtable(strcat(folder,files(i).name));
    % Extract the length parameter from the file name
    % name sample: train_output_L64m_K01
    fln = files(i).name(15:end-9);
    length_meter(i) = str2double(fln); % it will be in L<length_meter>m.csv format

    % TODO: Use variable name to determine which column is target/pred
    target    = data(:,1);  % First column is the target value
    predicted = data(:,2);  % Second column is the predicted value

    % If the column name (table.Properties.VariablesNames) contains 'log' then data needs to be converted back
    % Enable /disable depending if we are using logNormal or no transformation at all

    % Retrieve the table VariableNames (in properties)
    if (strfind (data.Properties.VariableNames{1}, 'log') > 0)
        print ("Log transform deteced in variable names") 
        target    = 10.^target;
        predicted = 10.^predicted;
    end

    % Compute the RMSE of our predictions
    error = rms(target - predicted);
    mean_train_fit(i) = error;
    mean_valid_fit(i) = error;
end

% Pack data for sorting
data_matrix = [length_meter, mean_train_fit, mean_valid_fit];
% Sort data by column 1: length_meter
data_sorted = sortrows(data_matrix,1);
% Unpack data
length_meter   = data_sorted(:,1);
mean_train_fit = data_sorted(:,2);
mean_valid_fit = data_sorted(:,3);

% TODO: Extract the folder path name with the experiment ID and add it to the Title string

if (strfind(dataset_key, 'train') > 0)
    edgeColor = [0 0.4470 0.7410]; % Blue-ish
    YLabelString = 'BNN - Prediction error (RMSE) for Trainng dataset'
    titleLabelString = 'BNN - Training loss vs distance parameter'
else % we should check it is 'valid' otherwise is an error (invalid key defined)
    edgeColor = [0.8500 0.3250 0.0980]; % Red-ish
    YLabelString = 'BNN - Prediction error (RMSE) for Validation dataset'
    titleLabelString = 'BNN - Validation loss vs distance parameter'
end

% Before plotting, we create an empty figure
figure; hold on; grid on;
% Plot the loss function. X = length_meter, Y = loss
scatter(length_meter, mean_train_fit, 'b', 'LineWidth', 2, 'MarkerEdgeAlpha', 0.3, MarkerEdgeColor, edgeColor);
xlabel('Distance parameter (m)', 'FontSize', 16);
ylabel( YLabelString, 'FontSize', 16);
legend ('Fitting loss', "", 'KL-divergence loss', "");
%legend ('Fitting loss', 'KL-divergence loss', "Total loss");
ylim([0 max(mean_train_fit)*1.05])
title (titleLabelString)

% Before plotting, we create an empty figure
figure; hold on; grid on;
% Plot the loss function. X = length_meter, Y = loss
scatter(length_meter, mean_valid_fit, 'b', 'LineWidth', 2, 'MarkerEdgeAlpha', 0.3);
%plot(length_meter, mean_valid_fit, 'b', 'LineWidth', 2);
% scatter(length_meter, mean_valid_kld, 'r', 'LineWidth', 2, 'MarkerEdgeAlpha', 0.3);
%plot(length_meter, mean_valid_kld, 'r', 'LineWidth', 2);
% plot(length_meter, mean_valid_fit + mean_valid_kld, 'b', 'LineWidth', 2);
% ylim([0, max(mean_valid_kld)+0.02]);
xlabel('Distance parameter (m)', 'FontSize', 16);
ylabel('BNN - Validation loss', 'FontSize', 16);
legend ('Fitting loss', "", 'KL-divergence loss', "");
%legend ('Fitting loss', 'KL-divergence loss', "Total loss");
ylim([0 max(mean_valid_fit)*1.05])
title ("BNN valid loss vs sigma parameter. h16 - 1E6 - MID Network. ELBO = 10.0")


% TODO: Replace scatter plot with violin or boxplots (compute mean/stdv)