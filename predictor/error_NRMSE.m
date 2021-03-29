% MAE: Normalized Root Mean Squared Error
% MAE = sqrt(MSE)

function [error] = error_NRMSE(x,y)
    d = (x-y);
    error= sqrt(mean(d.*d))/mean(y);
    
    
   % we could normalize by other factors:
   % range, standard deviation, IQR (Q1 - Q3)