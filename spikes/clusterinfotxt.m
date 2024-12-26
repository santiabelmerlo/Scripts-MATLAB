function clusterinfotxt = clusterinfotxt(filename)
%% Define the path
path = pwd;
    
% Read the cluster_info.tsv file as a table
cluster_info = readtable(filename,'FileType','text','Delimiter','\t');

% Agregamos una primera columna con el cluster_unique_id
% El cluster_unique_id es un número de 7 dígitos compuesto por número de rata, número de día y número de cluster (RRDDCCC)
currentfolder = pwd; %Buscamos el Current Folder en el que estamos parados
foldersplit = regexp(currentfolder,'\','split'); % Dividimos el current folder en las distintas carpetas
cluster_unique_id = foldersplit{end-1}; % Nos quedamos con el nombre de la anteúltima carpeta que va a corresponder a la información de rata y día (R00D00)
cluster_unique_id = strrep(cluster_unique_id(1,:),'R',''); % Borramos la letra R
cluster_unique_id = strrep(cluster_unique_id(1,:),'D',''); % Borramos la letra D
cluster_unique_id = cluster_unique_id(1:4);
rat = cluster_unique_id(1:2);
session = cluster_unique_id(3:4);
cluster_unique_id = repmat(cluster_unique_id,[size(cluster_info,1),1]); % Repetimos ese dato tantas veces como filas de la tabla clusterinfo
cluster_id = num2str(cluster_info{:,1}); % Pasamos la columna cluster_id a str
for i = 1:size(cluster_id,2); % Reemplazamos espacios vacios con 0
    cluster_id(:,i) = strrep(cluster_id(:,i)',' ','0')';
end
cluster_unique_id = strcat(cluster_unique_id,cluster_id); % Creamos el cluster_unique_id
cluster_unique_id = table(cluster_unique_id); % Lo transformamos a tabla

% Creamos cluster_session
session_id = repmat(session,[size(cluster_info,1),1]);
session_id = table(session_id);

% Creamos cluster_rat
rat_id = repmat(rat,[size(cluster_info,1),1]);
rat_id = table(rat_id);

clusterinfo = [cluster_unique_id rat_id session_id cluster_info]; % Hacemos una sola tabla uniendo cluster_unique_id y clusterinfo
clusterinfotxt = clusterinfo;
clear i fstruct foldersplit currentfolder cluster_id cluster_unique_id;

% sortclusterinfo = sortrows(clusterinfo,1); % Función para ordenar la
% tabla en orden ascendente segun el número de columna
writetable(clusterinfotxt,'cluster_info.csv'); % Guardamos clusterinfo como tabla en .txt
