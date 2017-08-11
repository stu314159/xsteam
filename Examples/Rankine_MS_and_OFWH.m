% Written by: Stu Blair
% Date: 8/11/2017
% Purpose: test XSteam functionality with slightly more complex Rankine
% cycle.

%%
clear
clc
close 'all'
%%
addpath('../'); % add XSteam to path (modify as necessary)
%%
%% Problem Description
% 
%  A Pressurized Water Reactor transfers heat to a Rankine cycle with the
%  following properties:  
% 
% * Steam Generator Outlet Pressure: 820 psia, quality = 100%
% * High Pressure turbine: outlet pressure 164 psia, isentropic efficiency
% of 94%.
% * Moisture separator draining to OFWH
% * Flow extraction downstream of M/S set to make OFWH outlet temperature
% equal to saturation temp at its pressure
%  * LP Turbine with outlet pressure of 3 psia, isentropic efficiency of
%  94%.
%  * Condenser outlet quality = 0.0
%  * Main condensate pump (efficiency = 84%) outlet pressure 164 psia
%  * Main Feed pump (efficiency = 84%) outlet pressure 820 psia
% 
% 
%% State point data tables
% we will not necessarily fill in all of these values
P = nan(9,1);
T = nan(9,1);
h = nan(9,1);
h_s = nan(9,1);
s = nan(9,1);
s_s = nan(9,1);
x = nan(9,1);

% Calculations
%% state point 1 - condenser outlet
P(1) = 3; % psia - given
x(1) = 0.0; % quality - given
h(1) = XSteamUS('hL_p',P(1));
T(1) = XSteamUS('Tsat_p',P(1));
s(1) = XSteamUS('sL_p',P(1));

%% state point 2
% compression in main condensate pump
eta_mcp = 0.84; % pump isentropic efficiency - given
s_s(2) = s(1); % isentropic
P(2) = 164; % psia - given
h_s(2) = XSteamUS('h_ps',P(2),s_s(2));
h(2) = h(1) - (h(1) - h_s(2))/eta_mcp;

%% state point 3 OFWH exit
P(3) = P(2); % constant pressure in OFWH
x(3) = 0.;
h(3) = XSteamUS('hL_p',P(3));
s(3) = XSteamUS('sL_p',P(3));

%% State point 4 MFP exit
eta_mfp = 0.84;
P(4) = 820; % psia - given
s_s(4) = s(3);
h_s(4) = XSteamUS('h_ps',P(4),s_s(4));
h(4) = h(3) - (h(3) - h_s(4))/eta_mfp;

%% State point 5 S/G Exit
P(5) = P(4); % assume isobaric in S/G
x(5) = 1.0; % saturated steam; given
h(5) = XSteamUS('hV_p',P(5));
s(5) = XSteamUS('sV_p',P(5));

%% State point 6 HP Turbine Exhaust
eta_hpt = 0.94; % hp turbine isentropic efficiency; given
P(6) = 164; % psia - given
s_s(6) = s(5);
h_s(6) = XSteamUS('h_ps',P(6),s_s(6));
h(6) = h(5) - eta_hpt*(h(5) - h_s(6));
x(6) = XSteamUS('x_ph',P(6),h(6));

%% State point 7 Moisture Separator vapor exit
x(7) = 1.0; % quality - given
P(7) = P(6); % assume isobaric process in M/S
h(7) = XSteamUS('hV_p',P(7));
s(7) = XSteamUS('sV_p',P(7));

%% State point 8 LP Turbine exhaust
eta_lpt = 0.94; % lp turbine isentropic efficiency; given
P(8) = P(1); % 3 psia - same as P(1) -- given
s_s(8) = s(7);
h_s(8) = XSteamUS('h_ps',P(8),s_s(8));
h(8) = h(7) - eta_lpt*(h(7) - h_s(8));
x(8) = XSteamUS('x_ph',P(8),h(8)); % just so we know...

%% State point 9 Moisture Separator liquid drain to OFWH
P(9) = P(6); % same pressure as HP Turbine exhaust
h(9) = XSteamUS('hL_p',P(9));

%% Energy balance on OFWH to find flow fraction f1 at extraction point
OFWH_Ebal = @(f1) x(6)*(1-f1)*h(2)+x(6)*f1*h(7)+(1-x(6))*h(9) - h(3);
f1 = fzero(OFWH_Ebal,0.05);

%% Specific Work and Energy Balance
w_mcp = (h(1) - h(2))*f1*x(6);
w_mfp = (h(3) - h(4));
w_hpt = h(5) - h(6);
w_lpt = (h(7) - h(8))*(1-f1)*x(6);

w_net = w_mcp + w_mfp + w_hpt + w_lpt;

q_cond = (h(1) - h(8))*(1-f1)*x(6);
q_sg = h(5) - h(4);

q_net = q_cond + q_sg;
eta_th = w_net/q_sg;

fprintf('Net Work = %g BTU/lbm; Net Heat = %g BTU/lbm \n',w_net,q_net);
fprintf('Cycle Thermal Efficienc = %4.1f percent. \n',eta_th*100);

