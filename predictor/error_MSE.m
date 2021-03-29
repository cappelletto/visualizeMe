% MAE: Mean Squared Error
% MAE = 1/N sum |x - y|

function [error] = error_MSE(x,y)
    d = (x-y);
    error= mean(d.*d);