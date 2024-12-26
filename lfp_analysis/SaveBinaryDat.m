%% Guardamos la señal de las 3 regiones como un .dat

% Animales a guardar: 11,12,13,17,18,19,20
clc
clear all

% Obtenemos el name de la carpeta
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Cargamos la info de la sesión
load(strcat(name,'_sessioninfo.mat'));

% Cargamos para BLA
if ~isempty(BLA_mainchannel)
    lfp_BLA = LoadBinary(strcat(name,'_lfp.dat'), BLA_mainchannel, ch_total);
end
% Cargamos para PL
if ~isempty(PL_mainchannel)
    lfp_PL = LoadBinary(strcat(name,'_lfp.dat'), PL_mainchannel, ch_total);
end
% Catgamos para IL
if ~isempty(IL_mainchannel)
    lfp_IL = LoadBinary(strcat(name,'_lfp.dat'), IL_mainchannel, ch_total);
end

% Obtenemos el tamaño del registro
if exist('lfp_BLA')
    siz = size(lfp_BLA,2);
elseif exist('lfp_PL')
    siz = size(lfp_PL,2);
elseif exist('lfp_IL')
    siz = size(lfp_IL,2);
end

% Si alguna señal no existe la creamos con ceros
if ~exist('lfp_BLA')
    lfp_BLA = zeros(1,siz);
elseif ~exist('lfp_PL')
    lfp_BLA = zeros(1,siz);
elseif ~exist('lfp_IL')
    lfp_BLA = zeros(1,siz);
end

signals = [lfp_BLA; lfp_PL; lfp_IL];
signals = int16(signals);
signals = signals';

% Guardamos el archivo .dat en el folder DataLFP
cd('C:\Users\santi\Desktop\DataLFP');
SaveBinary(strcat(name,'_lfp.dat'), signals, 'mode', 'new');

cd('D:\Doctorado\Backup Ordenado');
