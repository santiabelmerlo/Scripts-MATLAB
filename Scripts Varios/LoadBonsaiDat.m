%% Objetivo 2.
% Plotear el espectrograma de alguna porción de la señal y luego intentar
% marcar algún evento comportamental de "MisEventos" en ese mismo plot.

%% Seteamos el current folder.
cd 'E:/'

%% 
% Borramos la consola y el workspace
clc
clear all

% Seteamos el Current Folder
cd 'E:\Datos Merlo\Doctorado\Experimentos Electrofisiología\Bonsai_output'

%% Cargamos timestamp.dat
fileinfo = dir('timestamp.dat');
num_samples = fileinfo.bytes/4; % int32 = 4 bytes
fid = fopen('timestamp.dat', 'r');
timestamp = fread(fid, num_samples, 'int32');
fclose(fid);
Fs = 30000;
timestamp = timestamp/Fs; % sample rate from header file

%%
num_channels = 32; % amplifier channel info from header file
fileinfo = dir('amplifier.dat');
num_samples = fileinfo.bytes/(num_channels * 2); % int16 = 2 bytes
fid = fopen('amplifier.dat', 'r');
v = fread(fid, [num_channels, num_samples], 'uint16');
fclose(fid);
v = v * 0.195; % convert to microvolts
plot(timestamp,v(24,:));
%% Cargamos amplifier.dat
num_channels = 32; % amplifier channel info from header file
fileinfo = dir('amplifier.dat');
num_samples = fileinfo.bytes/(num_channels*2); % int16 = 2 bytes
fid = fopen('amplifier.dat', 'r');
amplifier = fread(fid, [num_channels, num_samples], 'uint16');
fclose(fid);
amplifier = (amplifier - 32768) * 0.195; 
ch = 30;
amplifier(ch,:) = amplifier(ch,:) - mean(amplifier(ch,:));
plot(timestamp,amplifier(ch,:));

%% Cargamos ttl.dat
fileinfo = dir('ttl.dat');
num_samples = fileinfo.bytes/2; % uint16 = 2 bytes
fid = fopen('ttl.dat', 'r');
ttl = fread(fid, num_samples, 'uint16');
fclose(fid);
ch = 0; ttl_ch1 = (bitand(ttl, 2^ch) > 0); % ch has a value of 0-15 here
ch = 1; ttl_ch2 = (bitand(ttl, 2^ch) > 0); % ch has a value of 0-15 here
ch = 3; ttl_ch4 = (bitand(ttl, 2^ch) > 0); % ch has a value of 0-15 here
ch = 4; ttl_ch5 = (bitand(ttl, 2^ch) > 0); % ch has a value of 0-15 here
ch = 5; ttl_ch6 = (bitand(ttl, 2^ch) > 0); % ch has a value of 0-15 here
ch = 6; ttl_ch7 = (bitand(ttl, 2^ch) > 0); % ch has a value of 0-15 here
ch = 7; ttl_ch8 = ~(bitand(ttl, 2^ch) > 0); % ch has a value of 0-15 here
% plot(ttl_ch1); hold on;
% plot(ttl_ch2); hold on;
% plot(ttl_ch4); hold on;
% plot(ttl_ch5); hold on;
% plot(ttl_ch6); hold on;
% plot(ttl_ch7); hold on;
% plot(ttl_ch8); hold on;


%%
num_channels = 3; % aux input channel info from header file
fileinfo = dir('accelerometer.dat');
num_samples = fileinfo.bytes/(num_channels * 2); % uint16 = 2 bytes
fid = fopen('accelerometer.dat', 'r');
accelerometer = fread(fid, [num_channels, num_samples], 'uint16');
fclose(fid);
accelerometer = accelerometer * 0.0000374; % Convertimos las unidades a volts.
plot(accelerometer(1,:)); hold on;
plot(accelerometer(2,:)); hold on;
plot(accelerometer(3,:)); hold on;

%% Cargamos la señal continuous.
num_channels = 32; % amplifier channel info from header file
fileinfo = dir('continuous.dat');
num_samples = fileinfo.bytes/(num_channels*2); % int16 = 2 bytes
fid = fopen('continuous.dat', 'r');
amplifier = fread(fid, [num_channels, num_samples], 'int16');
fclose(fid);
amplifier = amplifier * 0.195; 
plot(amplifier(2,:));

%%
time_ttl = [1:2:length(timestamp)];
time_aux = [1:4:length(timestamp)];

%%
plot(time_ttl,ttl_ch4);
hold on;
plot(time_aux,accelerometer(1,:));