% Este script RallSessionInfo.m recorre cada folder R00 y cada subfolder R00D00, carga el
% archivo R00D00_sessioninfo.mat y crea un dataCell donde cada fila es una
% sesión y cada columna es una variable

clc; 
clear all;

% Define the main directory where your R folders are located
mainDir = pwd; % Replace with your actual path

% Initialize an empty cell array to store the data
dataCell = {};

% Define headers
headers = {'ACC_channels', 'BLA_channels', 'BLA_mainchannel', 'EO_channels', ...
           'Fs_lfp', 'Fs_raw', 'IL_channels', 'IL_mainchannel', 'PL_channels', ...
           'PL_mainchannel', 'ch_total', 'name', 'paradigm', 'path', 'session', ...
           't1', 't2', 't3', 't4', 't5', 't6', 't7', 't8', 't9', 't10', 't11', 't12', 't13', 't14'};

% List all folders (R01, R02, ...)
R_folders = dir(fullfile(mainDir, 'R*'));

for i = 1:length(R_folders)
    R_folder = R_folders(i).name;
    
    % List all subfolders (R01D00, R01D01, ...)
    D_folders = dir(fullfile(mainDir, R_folder, 'R*D*'));

    for j = 1:length(D_folders)
        D_folder = D_folders(j).name;

        % List all sessioninfo files
        sessioninfo_files = dir(fullfile(mainDir, R_folder, D_folder, 'R*D*_sessioninfo.mat'));

        for k = 1:length(sessioninfo_files)
            file = sessioninfo_files(k).name;
            filePath = fullfile(mainDir, R_folder, D_folder, file);

            % Load the .mat file
            loadedData = load(filePath);

            % Extract the variables
            ACC_channels = loadedData.ACC_channels;
            BLA_channels = loadedData.BLA_channels;
            BLA_mainchannel = loadedData.BLA_mainchannel;
            EO_channels = loadedData.EO_channels;
            Fs_lfp = loadedData.Fs_lfp;
            Fs_raw = loadedData.Fs_raw;
            IL_channels = loadedData.IL_channels;
            IL_mainchannel = loadedData.IL_mainchannel;
            PL_channels = loadedData.PL_channels;
            PL_mainchannel = loadedData.PL_mainchannel;
            ch_total = loadedData.ch_total;
            name = loadedData.name;
            paradigm = loadedData.paradigm;
            path = loadedData.path;
            session = loadedData.session;
            
            % Define t1 to t14 as empty arrays
            t1 = [];
            t2 = [];
            t3 = [];
            t4 = [];
            t5 = [];
            t6 = [];
            t7 = [];
            t8 = [];
            t9 = [];
            t10 = [];
            t11 = [];
            t12 = [];
            t13 = [];
            t14 = [];
            
            % Check if variables t1 to t14 exist, and assign them if they do
            if isfield(loadedData, 't1'), t1 = loadedData.t1; end
            if isfield(loadedData, 't2'), t2 = loadedData.t2; end
            if isfield(loadedData, 't3'), t3 = loadedData.t3; end
            if isfield(loadedData, 't4'), t4 = loadedData.t4; end
            if isfield(loadedData, 't5'), t5 = loadedData.t5; end
            if isfield(loadedData, 't6'), t6 = loadedData.t6; end
            if isfield(loadedData, 't7'), t7 = loadedData.t7; end
            if isfield(loadedData, 't8'), t8 = loadedData.t8; end
            if isfield(loadedData, 't9'), t9 = loadedData.t9; end
            if isfield(loadedData, 't10'), t10 = loadedData.t10; end
            if isfield(loadedData, 't11'), t11 = loadedData.t11; end
            if isfield(loadedData, 't12'), t12 = loadedData.t12; end
            if isfield(loadedData, 't13'), t13 = loadedData.t13; end
            if isfield(loadedData, 't14'), t14 = loadedData.t14; end

            % Create a row for the cell array
            newRow = {ACC_channels, BLA_channels, BLA_mainchannel, EO_channels, Fs_lfp, Fs_raw, ...
                IL_channels, IL_mainchannel, PL_channels, PL_mainchannel, ch_total, name, paradigm, ...
                path, session, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14};

            % Append the row to the cell array
            dataCell = [dataCell; newRow];
        end
    end
end

% Add headers as the first row in the cell array
dataCell = [headers; dataCell];

% Save the cell array as a .mat file
Rall_sessioninfo = dataCell;
save('sessioninfo_database.mat', 'Rall_sessioninfo');
