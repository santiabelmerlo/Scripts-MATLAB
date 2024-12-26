%% FiltSessionInfo.m
% Este script FiltSessionInfo.m filtra la información de Rall_sessioninfo.mat de acuerdo a distintas condiciones
% En este caso por ejemplo filtra por paradigma aversivo y sesión TR1 y
% extrae los paths

clc;
clear all;

% Load Rall_sessioninfo Rall_sessioninfo
load('Rall_sessioninfo.mat');

% Extract headers from the first row
headers = Rall_sessioninfo(1, :);

% Define the index of the paradigm and session columns
paradigmIndex = find(strcmp(headers, 'paradigm'));
sessionIndex = find(strcmp(headers, 'session'));
pathIndex = find(strcmp(headers, 'path'));

% Initialize an empty cell array to store filter data
filtCell = {};

% Loop through each row in Rall_sessioninfo
for i = 2:size(Rall_sessioninfo, 1) % Start from 2 to skip header row
    % Check if the row corresponds to the aversive paradigm and TR1 session
    if strcmp(Rall_sessioninfo{i, paradigmIndex}, 'aversive') && strcmp(Rall_sessioninfo{i, sessionIndex}, 'TR1')
        % If so, extract the path value and add it to the list
        filtCell = [filtCell, Rall_sessioninfo{i, pathIndex}];
    end
end

% Now, 'filtCell' contains all paths for rows with the 'aversive' paradigm and 'TR1' session.

% Clear all variables except 'filtCell' and 'Rall_sessioninfo'
clearvars -except filtCell Rall_sessioninfo;
