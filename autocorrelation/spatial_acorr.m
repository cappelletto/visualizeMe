% Author: Jose Cappelletto
% email:  j.cappelletto@soton.ac.uk / cappelletto@gmail.com
% Function that computes the spatial autocorrelation for K-transects of
% predefined length L with a spatial resolution deltaX
% Spatial resolution and total length is inferred from the input data

function [data, y_transects, acorr_transects, x_threshold] = spatial_acorr (input_file, id_var, distance_var, target_var, corr_threshold)
% User-defined input (mandatory) variables are:
% id: UUID used to group transects. All transects with the same UUID will
% share the same 'id'
% distance: (relative) position of each point along the transect, starting
% from '0'
% target: name of the target variable (column) we want to analyze

opts = detectImportOptions(input_file);
opts.SelectedVariableNames = [id_var, distance_var, target_var];

% Need to check the variables exist in the input file
if sum(contains(opts.VariableNames, id_var)) < 1
    error ("ID field not found in file header")
    return
end
if sum(contains(opts.VariableNames, distance_var)) < 1
    error ("distance_var field not found in file header")
    return
end
if sum(contains(opts.VariableNames, target_var)) < 1
    error ("target_var field not found in file header")
    return
end
% Expected columns (variables) are:
% NT15-03: id,distance,HR0_SLO,HR0_DEM,HR1_SLO,HR1_DEM,HR2_SLO,HR2_DEM,HR3_SLO,HR3_DEM,vertex_ind

data = readtable(input_file, opts);   % import data as a table
% All transects are expected to be equally sampled along hteir length
% Compute the sampling distance as the mean of the difference of distance
ydiff = diff(data{:,distance_var});
deltaX = mean (ydiff(ydiff>0)); % monotonically increasing. Remove negative values that appear when switching transects
fprintf ("Mean transect resolution,\tdeltaX = %f\n", deltaX)

% Now we need to determine how many transects we have. Each transect has an
% unique 'id'.
uuid = unique(data{:,id_var}); % list of UUID
K = length(uuid);   % total of transects
fprintf ("Total transects detected,\tK = %d\n", K)
c = zeros(1,K);
for i=1:K
    idx = (data{:,id_var} == uuid(i));
    c(i) = height(data(idx, id_var));
end

% To guarantee consistent transect lengths, we use the minimum
P = min(c(i));
% The effective length (in map units) of the transects can be calculated
% using the deltaX and the length (height) of each vector. We use P as it
% guarantess the existence of data
L = (P-1) * deltaX;
fprintf("Using transect length,\tL = %f\n", L)

% Extract and organize the target variable (y) per transect
y = zeros(P,K); % preallocate space for K transects with P points
for i=1:K
    idx = (data{:,id_var} == uuid(i));  % create mask by transect id
    yt = data{idx, target_var};
    y(:,i) = yt(1:P);
end
y_transects = y;

% Compute autocorrelation for each transect, which is half the length of
% the transect, max
Q = floor (P/2);
y = zeros(Q,K); % preallocate space for K transects with P points
x_threshold = zeros(1,K); % store the first index on threshold crossing per transect
threshold = corr_threshold;
% For each transect, let's compute the spatial autocorrelation
for i=1:K
    y(:,i) = autocorr (y_transects(:,i), 'NumLags', Q-1);
    x_threshold(i) = find(y(:,i)<threshold, 1); % use only first incidence
end
acorr_transects = y;
x_threshold = x_threshold * deltaX;
%%%%%%%%%%%%%%%  Results visualization
figure; hold on;
% Create X-axis with correct length scale
x = deltaX * [0:Q-1];
h = plot (x, acorr_transects, 'LineWidth',2.0);
ylim([-0.5, 1.2])
yticks('manual')
% Add vertical lines located at intersection with threshold
for i=1:K
    h(i).Color(4)=0.15;
    xt = (x_threshold(i)-deltaX);
%    line ([xt,xt],[-0.5, acorr_transects(x_threshold(i),i)], 'LineWidth', 8, 'Color', [0.2, 0.2, 0.2, 0.1]);
    line ([xt,xt],[-0.5, threshold], 'LineWidth', 9, 'Color', [0.3, 0.2, 0.2, 0.06]);
    % plot dots at "interesection"
end
set (get(gca(), 'XAxis'), 'FontSize', 16)
xlabel ("Spatial lag [m]", 'FontSize',18)
label_str = sprintf ("Transect autocorrelation.\nVariable: %s", target_var);
set (get(gca(), 'YAxis'), 'FontSize', 16)
ylabel(label_str, 'Interpreter', 'none', 'FontSize',18)
% disable latex interpreter for title
% disable bold font for title
title (sprintf ("Spatial autocorrelation of K=%d transects L=%.0f m long vs lag distance\nDataset: %s", K, L, input_file), 'Interpreter', 'none', 'FontSize',18, 'FontWeight', 'normal')

% Scale the index by the mean value of delta X
% x_threshold = deltaX * x_threshold; % returns first incidence

% Draw horizontal line at threshold level
line ([min(x),max(x)], [threshold,threshold], 'Color',[0.8,0.12,0.12], 'LineStyle','--')
line ([min(x),max(x)], [0,0], 'Color',[0.1,0.1,0.2], 'LineStyle','-')

% Boxplot with summary of stats for lag distances of K transects
boxplot(x_threshold-deltaX, 'Orientation', 'horizontal')
text (mean(x_threshold), 1.2, sprintf("Mean lag\n%.2fm", mean(x_threshold)), 'FontSize',14)

grid on;
% plot (scatter) points at the intersections with the horizontal axis (threshold)3
scatter (x_threshold-deltaX, threshold*ones(1,K), 8, [0.5, 0.3, 0.3], 'filled')
yticks([-0.5:0.5:1.0]); % fix ticks after boxplot readjust (forcing manual didn't work)
yticklabels([-0.5:0.5:1.0])

