% # -*- coding: utf-8 -*-
% """
% Copyright (c) 2022, Ocean Perception Lab, Univ. of Southampton
% All rights reserved.
% Licensed under GNU General Public License v3.0
% See LICENSE file in the project root for full license information.
% """
% Author: Jose Cappelletto (j.cappelletto@soton.ac.uk) 
% Version: 0.2-alpha
% Date: 31/12/2021

% List containing all the data files (CSV)
% The data files are in the same folder as the script and have this naming convention:
% - loss_<length_meter>.csv
% For example: loss_L08m.csv, loss_L16m.csv, loss_L32m.csv ...

% Create a function lga_loss_distance with one parameter (path to folder)
function [results] = geo_loss_distance(folder_path, N)

% Check if folder_path is not defined
if ~exist('folder_path', 'var')
    warning ("Path to folder with loss CSV files not defined. Using current directory")
    folder_path = './'
end

% Retrieve the list of files in the folder
files = dir(strcat(folder_path, 'loss_*.csv'));

K = length(files);   % Number of files
if ~exist('N', 'var')
    warning ("N last samples to average per training run set to default N=10")
    folder_path = './'
    N=10; % Number of last epochs to use for calculating the mean loss for each loss function
end

% Create empty vector to store the mean loss for each loss function
mean_loss      = zeros(K,1);
length_meter       = zeros(K,1);

% for each file, we read the data, first row contains the column names
% and the rest of the rows contain the data
for i = 1:K
    data = readtable(strcat(folder_path,files(i).name));
    % Extract the length parameter from the file name
    % Each filename is expected to be named "loss_*L<lenght_in_meter>m.csv"
    length_meter(i) = str2double(files(i).name(7:end-5)); % it will be in L<length_meter>m.csv format

    % geoCLR training only exports the loss funcion, single column
    % Calculate the average loss of last N epochs of loss_all
    mean_loss(i) = mean (data.loss(end-N:end));
end

% for geoCLR feature extraction there is only one loss function
% Before plotting, we create an empty figure
figure; hold on; grid on;
% Plot the loss function. X = length_meter, Y = loss
scatter(length_meter, mean_loss, 'LineWidth', 2, 'MarkerEdgeColor', 'b');
ylim([0, max(mean_loss).*1.05]);
xlabel('Distance parameter [m]', 'FontSize', 18);
ylabel('geoCLR loss', 'FontSize', 18);
title('geoCLR loss vs. distance parameter', 'FontSize', 21);

% Let's plot the reciprocal of the loss function.
% This will make it easier to see the trend
reciprocal = log(1./mean_loss);
% Plot the reciprocal of the loss function. X = length_meter, Y = reciprocal
figure; hold on; grid on;
scatter(length_meter, reciprocal, 'LineWidth', 2, 'MarkerEdgeColor', [0.8500 0.3250 0.0980]);
ylim([min(reciprocal), max(reciprocal)*1.05]);
xlabel('Distance parameter [m]', 'FontSize', 18);
ylabel('Reciprocal of geoCLR loss', 'FontSize', 18);
title('Reciprocal of geoCLR loss vs. distance parameter', 'FontSize', 21);