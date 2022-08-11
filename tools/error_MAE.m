% MAE: Mean Absolute Error
% MAE = 1/N sum |x - y|

function [error] = error_MAE(x,y)
    error= mean(abs(x-y));