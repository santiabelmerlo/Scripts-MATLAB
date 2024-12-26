function clusterinfo = clusterinfo(filename, session, startRow, endRow)
% clusterinfo 
%   Import data from cluster_info.tsv file from Kilosort_ folder from a session.
%   Then adds a new column called cluster_unique_id that has a unique id for each cluster for each session (RRDDCCC)
%   Then adds session_type at the last column
%   Finally saves clusterinfo as cluster_info.txt into the Kilosort folder
%
%   clusterinfo = clusterinfo(FILENAME, SESSION) Reads data from cluster_info.tsv file adding 'SESSION' at the last column
%
%   clusterinfo = clusterinfo(FILENAME, SESSION, STARTROW, ENDROW) Reads data from
%   rows STARTROW through ENDROW of cluster_info.tsv file.
%
% Example:
%   clusterinfo = clusterinfo('cluster_info.tsv', 'ACTR1');
%  

%% Initialize variables.
delimiter = '\t';
if nargin<=2
    startRow = 2;
    endRow = inf;
end

%% Para crear archivo cluster_info.txt sumando los datos de cluster_unique_id y session_type
% path = 'F:\R11\R11D02';
% cd(path);
% fstruct = dir('*Kilosort*');
% cd(fstruct.name);
% 
% clusterinfo = clusterinfo('cluster_info.tsv','ACTR1');

%% Filtramos la tabla clusterinfo según alguna columna
% [tf, column_number] = ismember('type', clusterinfo);
% i = find(strcmp(clusterinfo{:,14}, 'good'));

%% Filtrar la tabla según algun valor o dato
% varnames = clusterinfo.Properties.VariableNames;
% [tf, column_number] = ismember('sh', varnames);
% if ~tf
%     error('Temperature is not one of the table variables')
% end
% index = find(strcmp(clusterinfo{:,column_number}, 5));
% index = find(clusterinfo{:,column_number} == 5);
% filt_clusterinfo = clusterinfo(index,:);

%% Format string for each line of text:
%   column1: double (%f)
%	column2: double (%f)
%   column3: double (%f)
%	column4: text (%s)
%   column5: double (%f)
%	column6: double (%f)
%   column7: double (%f)
%	column8: double (%f)
%   column9: text (%s)
%	column10: double (%f)
%   column11: text (%s)
%	column12: double (%f)
%   column13: text (%s)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%f%f%s%f%f%f%f%s%f%s%f%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Create output variable
clusterinfo = table(dataArray{1:end-1}, 'VariableNames', {'cluster_id','Amplitude','ContamPct','KSLabel','amp','ch','depth','fr','group','meanisi','n_spikes','position','quality','sh','target','type'});

%% Agregamos una primera columna con el cluster_unique_id
% El cluster_unique_id es un número de 7 dígitos compuesto por número de rata, número de día y número de cluster (RRDDCCC)
currentfolder = pwd; %Buscamos el Current Folder en el que estamos parados
foldersplit = regexp(currentfolder,'\','split'); % Dividimos el current folder en las distintas carpetas
cluster_unique_id = foldersplit{end}; % Nos quedamos con el nombre de la anteúltima carpeta que va a corresponder a la información de rata y día (R00D00)
cluster_unique_id = strrep(cluster_unique_id(1,:),'R',''); % Borramos la letra R
cluster_unique_id = strrep(cluster_unique_id(1,:),'D',''); % Borramos la letra D
cluster_unique_id = repmat(cluster_unique_id,[size(clusterinfo,1),1]); % Repetimos ese dato tantas veces como filas de la tabla clusterinfo
cluster_id = num2str(clusterinfo{:,1}); % Pasamos la columna cluster_id a str
for i = 1:size(cluster_id,2); % Reemplazamos espacios vacios con 0
    cluster_id(:,i) = strrep(cluster_id(:,i)',' ','0')';
end
cluster_unique_id = strcat(cluster_unique_id,cluster_id); % Creamos el cluster_unique_id
cluster_unique_id = table(cluster_unique_id); % Lo transformamos a tabla

% Creamos cluster_session
session_type = repmat({session},[size(clusterinfo,1),1]);
session_type = table(session_type);

% Distintos valores que puede tomar session
% ACPRE ? Appetitive conditioning preexposition
% ACHAB ? Appetitive conditioning habituation
% ACTR1 to ACTR5 ? Appetitive conditioning training
% ACEXT1 to ACEXT3 ? Appetitive conditioning extincion
% FCTR ? Fear conditioning training
% FCEXT ? Fear conditioning extinction
% FCTS ? Fear conditioning testing
% FCRE ? Fear conditioning reinstaintment test

clusterinfo = [cluster_unique_id rat_num session_type cluster_info]; % Hacemos una sola tabla uniendo cluster_unique_id y clusterinfo
clear i fstruct foldersplit currentfolder cluster_id cluster_unique_id;

% sortclusterinfo = sortrows(clusterinfo,1); % Función para ordenar la
% tabla en orden ascendente segun el número de columna
% 
writetable(clusterinfo,'cluster_info.txt'); % Guardamos clusterinfo como tabla en .txt
