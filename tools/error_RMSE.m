% MAE: Mean Squared Error
% MAE = 1/N sum |x - y|

function [error] = error_RMSE(x,y)
    d = (x-y);
    error= sqrt(mean(d.*d));