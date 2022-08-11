% ME: Mean Error
% ME = 1/N sum (x - y)

function [error] = error_ME(x,y)
    error= mean(x-y);