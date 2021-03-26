%% Pipeline structure
%% TODO: use Matlab parser for optional/positional arguments
function [retval] = prediction_analyze(filename, num_bins)

% Input argumets:
% CSV filename [required]
% Number of histogram bins [optional]
% Colourmap [optional]

% Assign default value to input argument cmap (colourmap)
if ~exist('filename', 'var')
    warning ("Missing input CSV file")
    return
end

% Assign default value to input argument cmap (colourmap)
if ~exist('num_bins', 'var')
    num_bins = 100;
end

%data = dlmread (filename,',',1,0);
data = readtable(filename); % this will automatically parse the first row as header

% 1st column, expected value
% 2nd column, measured value
% 3rd column, predicted value

K = num_bins; % number of bins for the approximate probability function
% making life easier by renaming variables
a  = data {:,1};   % ground-truth
b  = data {:,2};   % measured from remote priors
c  = data {:,3};   % predicted using LGA+BNN

close all
% First rule: always plot the data
figure
scatter (a, b, 'r');
hold on
grid on
scatter (a, c, 'b');

figure
subplot (1,3,1);
boxplot (a);
subplot (1,3,2);
boxplot (b);
subplot (1,3,3);
boxplot (c);

hmin = min(min(data{:,:}))
hmax = max(max(data{:,:}))


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