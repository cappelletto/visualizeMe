%% Pipeline structure
%% TODO: use Matlab parser for optional/positional arguments
function [retval] = prediction_analyze(filename, num_bins)

% Input argumets:
% CSV filename [required]
% Number of histogram bins [optional]
% Colourmap [optional]

% Assign default value to input argument cmap (colourmap)
if ~exist('filename', 'var')
    print ("Missing input CSV file")
    exit
end

% Assign default value to input argument cmap (colourmap)
if ~exist('num_bins', 'var')
    num_bins = 100;
end



data = dlmread ('koyo-lad.csv',',',1,0);
% 1st column, expected value
% 2nd column, measured value
% 3rd column, predicted value
close all
% First rule: always plot the data
figure
scatter (data(:,1), data(:,2), 'r');
hold on
grid on
scatter (data(:,1), data(:,3), 'b');

K = 100; % number of bins for the approximate probability function
% making life easier by renaming variables
a  = data (:,1);   % ground-truth
b  = data (:,2);   % measured from remote priors
c  = data (:,3);   % predicted using LGA+BNN

hmin = min(min(data))
hmax = max(max(data))


% Now, some histograms
P = histcounts(a, 100, 'BinLimits',[hmin,hmax]);
Q = histcounts(b, 100, 'BinLimits',[hmin,hmax]);
R = histcounts(c, 100, 'BinLimits',[hmin,hmax]);

% Normalize each PDF (they should have the same number of entries)
P = P/sum(P); % also it should match the length of the input data (number of rows)
Q = Q/sum(Q); % also it should match the length of the input data (number of rows)
R = R/sum(R); % also it should match the length of the input data (number of rows)

EPS = 0.00001;
% to avoid singularities (log(0)), we add a small value to each entry (EPS)
P = P + 2*EPS;
Q = Q + 2*EPS;
R = R + 2*EPS;  % this shouldn't affect the numerical convergence

figure
bar (P,'g')
hold on 
bar (Q,'r')
bar (R,'b')

acum = 0;
% Now, we compute the KL-divergence
for x=1:K
    acum = acum + P(x) * log(P(x)/Q(x));
end
kld_Q = acum

acum = 0;
% Now, we compute the KL-divergence
for x=1:K
    acum = acum + P(x) * log(P(x)/R(x));
end
kld_R = acum