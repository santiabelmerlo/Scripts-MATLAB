%% Crear una función que me reorganice la carpeta que me genera open ephys en una carpeta bien organizada y renombrada

% Primero hay que renombrar las carpetas que me da OpenEphys y ponerle de
% nombre "R00D00" con el número de rata correspondiente y el número de día
% Todo eso meterlo adentro de una carpeta con el nombre "R00"

clc;
clear all;
path = 'D:\Vol 12\';
cd(path);

dirinfo = dir(cd);
dirinfo(ismember({dirinfo.name}, {'.', '..'})) = [];  %remove current and parent directory.}

files = dirinfo(~[dirinfo.isdir]);
folders = dirinfo([dirinfo.isdir]);

% dirinfo(~[dirinfo.isdir]) = [];  %remove non-directories
%%

rootdir = 'F:\R11\R11D02';
filelist = dir(fullfile(rootdir, '**\*.*'));  %get list of files and folders in any subfolder
filelist = filelist(~[filelist.isdir]);  %remove folders from list

%%
clc
clear all
D = 'F:\R11\R11D02';
S = dir(fullfile(D,'*'));
N = setdiff({S([S.isdir]).name},{'.','..'}); % list of subfolders of D.
for ii = 1:numel(N)
    T = dir(fullfile(D,N{ii},'*')); % improve by specifying the file extension.
    C = {T(~[T.isdir]).name}; % files in subfolder.
    for jj = 1:numel(C)
        F = fullfile(D,N{ii},C{jj})
        % do whatever with file F.
    end
end

%%

movefile('F:\spike_unique_clusters_database.mat','F:\Carpeta\R1102_spike_unique_clusters_database.mat')