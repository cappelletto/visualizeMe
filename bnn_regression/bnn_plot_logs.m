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

% Retrieve training/validation loss information exported during BNN training information vs epochs
% Input file: log_LXX_KYY.csv. WHere XX is the length(distance) parameter and YY is the replica nmber (if available)
% Old trained models only have one replica (so no suffix is present)
% Last N samples per column are averaged to reduce noise/variation

function data_sorted = bnn_plot_logs(folder_path, N, y_max)

% The data files are in the same folder as the script and have this naming convention:
% - log_<length_meter>.csv
% For example: log_L08m.csv, log_L16m.csv, log_L32m.csv ...
% Expected data/header structure
% train_loss	train_fit_loss	train_kld_loss	valid_loss	valid_fit_loss	valid_kld_loss
% 47469.7849751368	47429.6286512426	40.1563064054495	32010.8387193991	31970.6812443493	40.1576037194679
% 26479.9440729611	26439.7666979147	40.1773126075813	25628.9923244216	25588.7994620213	40.1928679355882

% Check if folder_path is not defined
if ~exist('folder_path', 'var')
    warning ("Path to folder with log CSV files not defined. Using current folder")
    folder_path = './'
end

if ~exist('N','var')
    sprintf ("Using default (N=10) number of last samples to be averaged per column")
    N = 10
    % Retrieve the list of files in the folder
end

files = dir (strcat(folder_path, 'log_*.csv'));
K = length(files)   % Number of files

% Create empty vector to store the mean values of train/validation fit and kld loss functions
mean_train_fit = zeros(K,1);
mean_train_kld = zeros(K,1);
mean_valid_fit = zeros(K,1);
mean_valid_kld = zeros(K,1);
length_meter   = zeros(K,1);

% for each file, we read the data, first row contains the column names
% and the rest of the rows contain the data
for i = 1:K
    data = readtable(strcat(folder_path,files(i).name));
    % Extract the length parameter from the file name
    st_ = strfind (files(i).name, "_L");
    end_ = strfind (files(i).name, "m");
    length_meter(i) = str2double(files(i).name(st_+2 : end_-1)); % it will be in L<length_meter>m.csv format

% The data structure (header) is:
%   train_loss:     total loss in the training dataset
%	train_fit_loss: fitting (MSE) loss in training dataset
%	train_kld_loss: KL-divergence (complexity) loss in training dataset
%	valid_loss:     total loss in the validation dataset
%	valid_fit_loss: fitting (MSE) loss in validation dataset
%	valid_kld_loss: KL-divergence (complexity) loss in validation dataset

    % Calculate the average loss of last N epochs of loss_recon
    mean_train_fit(i) = mean(data.train_fit_loss(end - N:end))/100;
    mean_train_kld(i) = mean(data.train_kld_loss(end - N:end));
    mean_valid_fit(i) = mean(data.valid_fit_loss(end - N:end))/100;
    mean_valid_kld(i) = mean(data.valid_kld_loss(end - N:end));
end

% Pack data for sorting
data_matrix = [length_meter, mean_train_fit, mean_train_kld, mean_valid_fit, mean_valid_kld];
% Sort data by column 1: length_meter
data_sorted = sortrows(data_matrix,1);
% Unpack data
length_meter   = data_sorted(:,1);
mean_train_fit = data_sorted(:,2);
mean_train_kld = data_sorted(:,3);
mean_valid_fit = data_sorted(:,4);
mean_valid_kld = data_sorted(:,5);

% Before plotting, we create an empty figure
figure; hold on; grid on;
% Plot the loss function. X = length_meter, Y = loss
scatter(length_meter, mean_train_fit, 'b', 'LineWidth', 2, 'MarkerEdgeAlpha', 0.3);
%plot(length_meter, mean_train_fit, 'b', 'LineWidth', 2);
scatter(length_meter, mean_train_kld, 'r', 'LineWidth', 2, 'MarkerEdgeAlpha', 0.3);
%plot(length_meter, mean_train_kld, 'r', 'LineWidth', 2);
% plot(length_meter, mean_train_fit + mean_train_kld, 'b', 'LineWidth', 2);
% ylim([0, max(mean_train_kld)+0.02]);
xlabel('Distance parameter (m)', 'FontSize', 16);
ylabel('BNN - Training loss', 'FontSize', 16);
legend ('Fitting loss', 'KL-divergence loss');
%legend ('Fitting loss', 'KL-divergence loss', "Total loss");
if ~exist('y_max','var')
    ylim([0 max(max(mean_train_fit), max(mean_train_kld))])
else
    ylim([0 y_max])
end
title ("BNN training loss vs distance parameter")

% Before plotting, we create an empty figure
figure; hold on; grid on;
% Plot the loss function. X = length_meter, Y = loss
scatter(length_meter, mean_valid_fit, 'b', 'LineWidth', 2, 'MarkerEdgeAlpha', 0.3);
%plot(length_meter, mean_valid_fit, 'b', 'LineWidth', 2);
scatter(length_meter, mean_valid_kld, 'r', 'LineWidth', 2, 'MarkerEdgeAlpha', 0.3);
%plot(length_meter, mean_valid_kld, 'r', 'LineWidth', 2);
% plot(length_meter, mean_valid_fit + mean_valid_kld, 'b', 'LineWidth', 2);
% ylim([0, max(mean_valid_kld)+0.02]);
xlabel('Distance parameter (m)', 'FontSize', 16);
ylabel('BNN - Validation loss', 'FontSize', 16);
legend ('Fitting loss', 'KL-divergence loss');
%legend ('Fitting loss', 'KL-divergence loss', "Total loss");
if ~exist('y_max','var')
    ylim([0 max(max(mean_valid_fit), max(mean_valid_kld))])
else
    ylim([0 y_max])
end
title ("BNN validation loss vs distance parameter")
