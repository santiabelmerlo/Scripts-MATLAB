%% SessionInfo
% Establece algunos parámetros e información sobra la sesión y los guarda
% en un archivo "R00D00_sessioninfo.mat"

clc; clear all;

path = pwd;
[~,D,X] = fileparts(path); name = D([1:6]);
clear X D;

Fs_raw = 30000; % Frecuencia de sampleo del archivo ".dat"
Fs_lfp = 1250; % Frecuencia de sampleo del archivo "_lfp.dat"
ch_total = 35; % Número de canales totales que tiene el .dat

paradigm = 'aversive'; % Paradigma correspondiente: 'appetitive' o 'aversive'
session = 'TEST'; % Sesión correspondiente: 'PRE', 'HAB1', 'TR1', 'EXT1', 'RST', 'TEST', 'HC'

% Seteamos los canales de los tetrodos

t1 = [5:8];   % tetrodo 1
t2 = [9:12];    % tetrodo 2
t3 = [13:16];   % tetrodo 3
t4 = [17:20];   % tetrodo 4
t5 = [21:24];   % tetrodo 5
t6 = [25:28];   % tetrodo 6
t7 = [29:32];   % tetrodo 7

% t1 = [19,20,29,30];   % tetrodo 1
% t2 = [21:24];    % tetrodo 2
% t3 = [25:28];   % tetrodo 3
% t4 = [13:16];   % tetrodo 4
% t5 = [9:12];   % tetrodo 5
% t6 = [1:4];   % tetrodo 6
% t7 = [5:8];   % tetrodo 7

% t1 = [9:12];    % tetrodo 1
% t2 = [13:16];   % tetrodo 2
% t3 = [17:20];   % tetrodo 3
% t4 = [21:24];   % tetrodo 4
% t5 = [25:28];   % tetrodo 5
% t6 = [29:32];   % tetrodo 6
% t7 = [33:36];   % tetrodo 7
% t8 = [37:40];   % tetrodo 8
% t9 = [41:44];   % tetrodo 9
% t10 = [45:48];   % tetrodo 10
% t11 = [49:52];   % tetrodo 11
% t12 = [53:56];   % tetrodo 12
% t13 = [57:60];   % tetrodo 13
% t14 = [61:64];   % tetrodo 14

PL_channels = [2]; % Canales que tienen información de PL en esa sesión
PL_mainchannel = [2]; % Canal representativo de PL en esa sesión
IL_channels = [1]; % Canales que tienen información de IL en esa sesión
IL_mainchannel = [1]; % Canal representativo de IL en esa sesión
BLA_channels = [t2,t3,t6,t7]; % Canales que tienen información de BLA en esa sesión
BLA_mainchannel = [30]; % Canal representativo de BLA en esa sesión

EO_channels = []; % Canales que contienen información de epitelio olfatorio
ACC_channels = [33,34,35]; % Canales que contienen información del acelerómetro
% ACC_channels = [65,66,67]; % Canales que contienen información del acelerómetro

% Guardamos todo el workspace en el archivo 'R00D00_sessioninfo.mat'
save(strcat(name,'_sessioninfo.mat'));