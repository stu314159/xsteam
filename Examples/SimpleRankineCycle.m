% Written by: Stu Blair
% Date: 8/11/2017
% Purpose: test xsteam functionality for simpl Rankine Cycle

%%
clear
clc
close 'all'

%% Add the path to the XSteam functions
addpath('../');

%% Problem Description:
%%
% 
%  Advanced Boiling Water Reactor (ABWR) produces saturated steam at 7.17
%  MPa (71.7 bar) to a set of turbine generators.  The turbines exhaust to
%  condensers maintained at 8 kPa (0.08 bar).  Assume the turbines and
%  pumps have isentropic efficiencies of 100%; assume fluid leaving the
%  condenser is saturated liquid.  Calculate enthalpy, entropy, and temperature
%  for all state points.  Calculate net work and  thermal efficiency for this cycle
%
% 
%% Initialize state-point variables

numSP = 4;

% state point 1: condenser outlet / feed pump inlet
% state point 2: feed pump discharge / Reactor core inlet
% state point 3: reactor core outlet / turbine inlet
% state point 4: turbine exhaust / condenser inlet

P = nan(4,1); % bar
T = nan(4,1); % degrees C
h = nan(4,1); % kJ/kg
s = nan(4,1); % kJ/kg-K
x = nan(4,1); % no units

%% State Point 1
P(1) = 0.08; % bar - given
x(1) = 0.0; % given

T(1) = XSteam('Tsat_p',P(1));
h(1) = XSteam('hL_p',P(1));
s(1) = XSteam('sL_p',P(1));

%% State Point 2
% process: isentropic compression
s(2) = s(1);
P(2) = 71.1; % bar - given
h(2) = XSteam('h_ps',P(2),s(2));
T(2) = XSteam('T_ph',P(2),h(2));

pump_work = h(1) - h(2);

%% State Point 3
% process: isobaric heat addition
P(3) = P(2);
x(3) = 1.0; % given
T(3) = XSteam('Tsat_p',P(3));
h(3) = XSteam('hV_p',P(3));
s(3) = XSteam('sV_p',P(3));

heat_in = h(3) - h(2);

%% State Point 4
% process: isentropic expansion
s(4) = s(3);
P(4) = P(1); % for isobaric heat rejection in next step
h(4) = XSteam('h_ps',P(4),s(4));
x(4) = XSteam('x_ph',P(4),h(4));

turbine_work = h(3) - h(4);

%% State Point 1
% process: isobaric heat rejection

heat_out = h(1) - h(4);

%% Energy Balance
net_heat = heat_in + heat_out;
net_work = turbine_work + pump_work;

eta_th = net_work/heat_in;

fprintf('Net heat = %g, Net work = %g. \n',net_heat,net_work);
fprintf('Thermal efficiency = %4.1f percent.\n',eta_th*100);



