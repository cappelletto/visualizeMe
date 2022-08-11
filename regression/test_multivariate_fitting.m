% train_file, validation_file: files containing the input variables X
% (e.g. latent vector) used during training and for validation (so we can
% compare their performance)
% target_file: file containing the target variable (label) 'y' (e.g. slope,
% landability)
% input_key: common column key for both train and validation files,
% identifying which columns correspond to the input vector X (e.g.
% 'latent')
% target_key: column key corresponding to the target (label) name in the
% output file
% join_key: column key common to input and output tables. Used in innerjoin
% to match rows. Default for our datasets: uuid
function [train_table, valid_table, target_table] = test_multivariate_fitting (model, train_file, validation_file, target_file, input_key, target_key, join_key)

if (isempty(target_key))
    target_key = "hislope";
end
if (isempty(input_key))
    input_key = "latent_";
end
if (isempty(join_key))
    join_key = "uuid";
end

% Read training and validation tables, dropping rows with missing data
train_table = readtable(train_file, "MissingRule","omitrow");
valid_table = readtable(validation_file, "MissingRule","omitrow");

% Clean unnamed columns from table. This can be caused because the way
% numpy dataframes were exported from the oplab / lga pipeline (anon.
% columns)
pattern = {'Var', 'altitude', 'roll_', 'pitch_', 'heading_', 'timestamp_', 'valid_ratio'};
train_table = removevars(train_table, contains(train_table.Properties.VariableNames, pattern));
valid_table = removevars(valid_table, contains(valid_table.Properties.VariableNames, pattern));

n_valid = height(valid_table)
% Remove common entries from validation
mask = ismember(valid_table.(join_key), train_table.(join_key));
valid_table = valid_table(~mask,:);

% Print information about number of succesfully parsed rows per table
n_train = height(train_table)
n_valid_unique = height(valid_table)

% Use the pretrained model to calculate the predictions over the training
% and the validation datasets

% Extract columns with the specified 'input_key' for 'X'
train_latent = train_table (:, contains(train_table.Properties.VariableNames, input_key));
valid_latent = valid_table (:, contains(valid_table.Properties.VariableNames, input_key));
n_latent = width(valid_latent);

% Convert to array
train_X = table2array (train_latent);
valid_X = table2array (valid_latent);

% Calculate predictions by evaluating the model with the provided inputs
train_Y = model.feval(train_X);
valid_Y = model.feval(valid_X);

% Add predicted output to the corresponding table of each dataset
train_table.predicted = train_Y;
valid_table.predicted = valid_Y;

% Load the target (ground-truth) file
target_table = readtable(target_file, "MissingRule","omitrow");
pattern = {'Var', 'northing', 'easting'};   % Remove unnamed column and duplicated location info before joining tables
target_table = removevars(target_table, contains(target_table.Properties.VariableNames, pattern));

% Join target_table by 'join_key' to append the target_key to each
% train|validation dataset
% We can drop no-longer used input_key from train/valid_tables
pattern = {input_key};
train_table = removevars(train_table, contains (train_table.Properties.VariableNames, pattern));
valid_table = removevars(valid_table, contains (valid_table.Properties.VariableNames, pattern));

% Join table (innerjoin) with target_table to append the expected (target)
% value for each row
train_table = innerjoin (train_table, target_table, "Keys",join_key);
valid_table = innerjoin (valid_table, target_table, "Keys",join_key);

% Scatter plot for training dataset
figure;
scatter (valid_table.(target_key), valid_table.predicted, 'r.');
grid on
hold on
scatter (train_table.(target_key), train_table.predicted, 'b.');
legend (["Validation", "Training"])
title_str = ['Predicted vs expected hislope for LinearModel with latent dimension h = ', num2str(n_latent), 'Red: validation dataset | Blue: training dataset'];
title (title_str, "FontSize", 14)

rmse_train = sqrt(mean((train_table.predicted - train_table.(target_key)).^2))
rmse_valid = sqrt(mean((valid_table.predicted - valid_table.(target_key)).^2))

r2_str =['R2 = ',num2str(model.Rsquared.Adjusted)]
rmse_str_train = ['RMSE-train = ',num2str(rmse_train)];
rmse_str_valid = ['RMSE-valid = ',num2str(rmse_valid)];

text (60,5,r2_str, 'FontSize',18)
text (70,22,rmse_str_train, 'FontSize',16)
text (70,25,rmse_str_valid, 'FontSize',16)

xlabel ({"Ground truth ", target_key});
ylabel ({"Predicted ", target_key});
% % 
% % % Compare predictions against target 'y' using a 1st order polynomial (line)
% c = polyfit(y,y_pred,1);
% % Compute 2x2 correlation coefficient matrix
% R=corrcoef(y,y_pred);
% % R2
% R2 = R(2)^2;
% % Obtain expected prediction from a linear fit (illustration purposes)
% y_exp=polyval(c,y);
% 
% hold on
% grid on
% % Plot the y_exp line
% plot (y, y_exp, 'k')
% % 
% % % Generate text containing the linear equation
% % mse_str=['MSE = ', num2str(mdl.MSE)]
% r2_str =['R2 = ',num2str(R2)]
% eq_str = sprintf('y = %.3f x + %.3f', c(1), c(2))
% xx = (4/6)*(max(y)      - min(y)) + min(y);
% yy = (5/6)*(max(y_pred) - max(y_pred)) + min (y_pred);
% % 
% text (xx,1.3*yy,eq_str, 'FontSize',18)
% text (xx,0.8*yy,r2_str, 'FontSize',18)
% ylabel ("Y predicted")
% xlabel ("Y expected")