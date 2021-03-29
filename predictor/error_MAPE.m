% MAE: Mean Absolute Percentage Error
% MAE = 1/N sum |(x - y) / x|

function [error] = error_MAPE(x,y)
    error= mean(abs(x-y) / abs(x+eps));
    
   % to mitigate the problem of having ZERO vales in the denominator, we
   % add EPS to it's absolute value
   % Problem: still is very sensitive to near-zero condition
   % WAPE: it uses the mean x-value as a weighted version of MAE
   