%--------------------------------------------------------------------------
% Portfolio Optimiser main script
%--------------------------------------------------------------------------
clear all, close all

%% Libraries
addpath('functions');
addpath('functions/Heuristic_test_sub_functions')

%% Crawler
dates2csv('01/01/2016', '01/01/2018') %Sending the start and finish dates to the crawler for data aquisition
system('python functions/Crawler/Data_Gatherer.py')

%% Your Q matrix is your own view of the market, I use an estimate of 
% compound returns for each security, I found the 12 month estimated price 
% on Bloomberg (I couldn't find anything shrter than this) then each week 
% I used the last price and this estimated price to calculate compound
% return --> log(estimatedprice/recentprice) * 100

Q = [3.85 10.85 5.68 6.34 5.8 1.11]' ;

%% P and views matrix, 
% your P matrix will be an identity matrix of 1's or -1's,
% depending on whether you expect your returns to increase or
%%decrease, P's are in order or the security no. 

P = [ 1, 1, 1, 1, 1, 1];

%% Data
[Market, Compound, WeeklyCompound, OutstandingShares] = DB_Loader();

%https://uk.mathworks.com/help/matlab/matlab_prog/access-data-in-a-table.html
%to learn how to access data 
Companies = Compound.Properties.VariableNames; %creates a vector of cells with companies tickers
size = length(Companies); %counts the number of columns (it includes date and index columns)

%we decide now what we want to plot
plotAutocorr = false;
doHistogramFit = false;
plotFatTails = false;
plotHeuristicTest = false;
plotFront = true;

%% ************************   SAVE PORTFOLIO   **************************** 
savePortfolio = true;
% savePortfolio should be true only when we run the program to definitely 
% update our portfolio, so just at the beginning/end of the week in order
% to update for the next week.
% ******** savePortfolio is FALSE during the week *********

%% Market Analysis
[iid, Rho, nu, marginals, GARCHprop] = MarketAnalysis(Compound, plotAutocorr, doHistogramFit, plotFatTails, plotHeuristicTest);

%% Projection
NDaysProjection = 5;
NCompanies = size - 2;
lastPrices = Market{1,3:end};
projectedPrices = Projection(NDaysProjection, NCompanies, Rho, nu, marginals, lastPrices); 

[exp_lin_return, var_lin_return] = priceToLinear(projectedPrices, lastPrices);

[exp_com_returnBL, var_com_returnBL] = priceToCompoundBL(WeeklyCompound, Market, OutstandingShares, NCompanies, Q, P);

%% Optimisation
%first calculates expected vector and covariance matrix for total returns
%matlab Portfolio object uses Markowitz model for portfolio optimisation
%computations
[sharp_ratio, SR_pwgt] = Optimisation(exp_lin_return, var_lin_return, Companies(3:end), NCompanies, plotFront, 'Max Sharp Ratio Portfolio MV');
[sharp_ratioBL, SR_pwgtBL] = Optimisation(exp_com_returnBL, var_com_returnBL, Companies(3:end), NCompanies, plotFront, 'Max Sharp Ratio Portfolio BL');

if (savePortfolio == true) 
    date = {datestr(table2array(Market(1,1)), 'dd/mm/yyyy')};
    SavePortfolio(Companies(3:end),num2cell(SR_pwgt), date, 'NP', sharp_ratio);
    SavePortfolio(Companies(3:end),num2cell(SR_pwgtBL'), date, 'BL', sharp_ratioBL);
end

%Once you run "PerformanceAnalysis" should be run
