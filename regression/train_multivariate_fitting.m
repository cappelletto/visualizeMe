% input_file: file containing the input variables X (e.g. latent vector) 
% target_file: file containing the tarte variable y (e.g. slope,
% landability)
% join_key: column key common to input and output tables. Used in innerjoin
% to match rows. Default for our datasets: uuid
function [mdl, y, y_pred] = train_multivariate_fitting (input_file, target_file, target_key, input_key , join_key)

if (isempty(target_key))
    target_key = "hislope";
end
if (isempty(input_key))
    input_key = "latent_";
end
if (isempty(join_key))
    join_key = "uuid";
end

% input_file =  'data/latent/latent_h16_TR_ALL.csv';
% output_file = 'data/target/hislope/direct-r020/A1_direct_r020_TR00-06-36.csv'

latent = readtable (input_file);    % read input table expected to contain the latent vectors
target = readtable (target_file);   % read table containing the expected variable to be predicted (slope, landability)

% Inner join of both table, returning only the rows with matching 'key'
% column
joinedTable = innerjoin(latent, target, 'key', join_key);

% Drop rows containing NaN
joinedTable = rmmissing (joinedTable);

% Extract those columns matching the specified input_key for X

X_table = joinedTable(:,contains (joinedTable.Properties.VariableNames, input_key));
y_table = joinedTable(:,contains (joinedTable.Properties.VariableNames, target_key));

X = table2array (X_table);
y = table2array (y_table);

% Fit model y = A*X + b using linear regression
mdl = fitlm(X,y,"Intercept",true);
plot (mdl)
grid on
hold on
% % Generate text containing the linear equation
mse_str=['MSE = ', num2str(mdl.MSE)]
r2_str =['R2 = ',num2str(mdl.Rsquared.Adjusted)]
% eq_str = sprintf('y = %.3f x + %.3f', c(1), c(2))
xx = -2;
yy = (5/6)*(max(y) - min(y)) + min (y);
% 
text (xx,0.9*yy,mse_str, 'FontSize',18)
text (xx,0.8*yy,r2_str, 'FontSize',18)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Vector with predictions using the linear model
y_pred = mdl.predict();

% Plot predicted vs expected output
figure
scatter (y,y_pred,'r.')
grid on

% 
% % Compare predictions against target 'y' using a 1st order polynomial (line)
c = polyfit(y,y_pred,1);
% Compute 2x2 correlation coefficient matrix
R=corrcoef(y,y_pred);
% R2
R2 = R(2)^2;
% Obtain expected prediction from a linear fit (illustration purposes)
y_exp=polyval(c,y);

hold on
grid on
% Plot the y_exp line
plot (y, y_exp, 'k')
% 
% % Generate text containing the linear equation
% mse_str=['MSE = ', num2str(mdl.MSE)]
r2_str =['R2 = ',num2str(R2)]
eq_str = sprintf('y = %.3f x + %.3f', c(1), c(2))
xx = (4/6)*(max(y)      - min(y)) + min(y);
yy = (5/6)*(max(y_pred) - max(y_pred)) + min (y_pred);
% 
text (xx,1.3*yy,eq_str, 'FontSize',18)
text (xx,0.8*yy,r2_str, 'FontSize',18)
ylabel ("Y predicted")
xlabel ("Y expected")