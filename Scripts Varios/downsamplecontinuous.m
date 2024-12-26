%% downsamplecontinuous.m
% Downsamples filename.dat from 30 KHz to 1250 Hz and saves into the same folder as filename_lfp.dat
% Uses ResampleBinary.m function from FMAToolbox.

clc;
clear all;

nChannels = 35;  % numero de canales en el archivo .dat - 35 para R09 a R14 o 70 para R15 en adelante.
up = 1;          % upsampling integer factor: 1 to downsample to 1250 Hz
down = 24;       % downsampling integer factor: 24 to downsample to 1250 Hz

fstruct = dir('*_lfp*.dat'); % Buscamos el nombre del archivo _lfp.dat si es que existe.
if exist(fstruct.name,'file') == 2;
    fprintf(strcat(fstruct.name,' file already exists in the folder. Downsampling process has been stopped'));
else
    fstruct = dir('*.dat');
    [pathstr,name,ext] = fileparts(fstruct.name);
    inputName = fstruct.name; % binary input file
    outputName = strcat(name, '_lfp.dat'); % binary output file
    fprintf(strcat('Downsampling',' ',inputName,'...'));
    ResampleBinary(inputName,outputName,nChannels,up,down); % Hacemos el downsampling
    fprintf(strcat(outputName,' has been created and saved in the current folder'));
end

clear all;