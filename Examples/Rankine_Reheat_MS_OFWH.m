% Written by: Stu Blair
% Date: 8/11/2017
% Purpose: use fminsearch

clear
clc
close 'all'

%%
addpath('../');

%% Problem Description
% (a picture would be better....)

%% Variable initailization
numSP = 12; % number of state points
P = nan(numSP,1);
T = nan(numSP,1);
h = nan(numSP,1);
h_s = nan(numSP,1);
s = nan(numSP,1);
s_s = nan(numSP,1);
x = nan(numSP,1);
%% Calculations

%% State point 1 - condenser exit
P(1) = 1.5; % psia
h(1) = XSteamUS('hL_p',P(1));
s(1) = XSteamUS('sL_p',P(1));

%% State point 1 -> 2, main condensate pump
P(2) = 164; % psia
eta_mcp = 0.84;
s_s(2) = s(1);
h_s(2) = XSteamUS('h_ps',P(2),s_s(2));
h(2) = h(1) - (h(1) - h_s(2))/eta_mcp;

%% State point 3, OFWH exit, saturated liquid
P(3) = P(2);
h(3) = XSteamUS('hL_p',P(3));
s(3) = XSteamUS('sL_p',P(3));

%% State point 3 -> 4, main feed pump
P(4) = 820; % psia
eta_mfp = 0.84;
s_s(4) = s(3);
h_s(4) = XSteamUS('h_ps',P(4),s_s(4));
h(4) = h(3) - (h(3) - h_s(4))/eta_mfp;

%% State point 5 - Steam generator exit
P(5) = P(4);
h(5) = XSteamUS('hV_p',P(5));
s(5) = XSteamUS('sV_p',P(5));

%% State point 6 - HP Turbine Exhaust
P(6) = 164; % psia
eta_hpt = 0.94;
s_s(6) = s(5);
h_s(6) = XSteamUS('h_ps',P(6),s_s(6));
h(6) = h(5) - eta_hpt*(h(5) - h_s(6));
x(6) = XSteamUS('x_ph',P(6),h(6));

%% State point 7 - Moisture Separator Exit
P(7) = P(6);
h(7) = XSteamUS('hV_p',P(7));
s(7) = XSteamUS('sV_p',P(7));

%% State point 8 - Reheater Mid-Pressure Steam exit
P(8) = P(7);
T(8) = 490; % degrees F
h(8) = XSteamUS('h_pT',P(8),T(8));
s(8) = XSteamUS('s_pT',P(8),T(8));

%% State point 9 - LP Turbine Exhaust
P(9) = P(1);
eta_lpt = 0.94;
s_s(9) = s(8);
h_s(9) = XSteamUS('h_ps',P(9),s_s(9));
h(9) = h(8) - eta_lpt*(h(8)-h_s(9));

%% State point 10 - Reheater HP Steam exit
P(10) = P(5);
h(10) = XSteamUS('hL_p',P(10)); % assume steam exits as a saturated liquid.


%% State point 11 - pressure trap exit to OFWH
P(11) = P(2);
h(11) = h(10); % assume isenthalpic expansion in the trap.

%% State point 12 - Moisture Separator liquid drain to OFWH
P(12) = P(6);
h(12) = XSteamUS('hL_p',P(12));

%% Heat Balance - find the flow fractions
RH_heatBalance = @(f) (f(1)*h(5) + (1-f(1))*x(6)*(1-f(2))*h(7)) - ...
    ( f(1)*h(10) + (1-f(1))*x(6)*(1-f(2))*h(8));

OFWH_heatBalance = @(f) ... 
    ((1-f(1))*(1-f(2))*x(6)*h(2) + f(1)*h(11) + (1-f(1))*x(6)*f(2)*h(7) + ...
    (1-f(1))*(1-x(6))*h(12)) - h(3);

totalFunctional = @(f) abs(RH_heatBalance(f))+...
    abs(OFWH_heatBalance(f));

% the strategy is to minimize the total functional.  The minimum value is
% when they are both equal to zero.
initialGuess = [0.1,0.1];
f = fminsearch(totalFunctional,initialGuess);

%% calculate heat and energy balances
w_mcp = (h(1) - h(2))*(1-f(1))*(1-f(2))*x(6);
w_mfp = (h(3) - h(4));
w_hpt = (h(5) - h(6))*(1-f(1));
w_lpt = (h(8) - h(9))*(1-f(1))*(1-f(2))*x(6);

w_net = w_mcp + w_mfp + w_hpt + w_lpt;

q_cond = (h(1) - h(9))*(1-f(1))*(1-f(2))*x(6);
q_sg = (h(5) - h(4));

q_net = q_cond + q_sg;

eta_th = w_net/q_sg;

%% report the results:
fprintf('Net work = %g BTU/lbm; Net heat = %g BTU/lbm \n',w_net,q_net);
fprintf('Thermal efficiency = %4.1f percent.\n',eta_th*100);

