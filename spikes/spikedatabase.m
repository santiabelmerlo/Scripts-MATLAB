%% Generar un script que me haga database de todos los animales y sesiones pero de los archivos spike_clusters, templates, times y amplitudes
% spike_times_database.mat tiene los tiempos de todos los spikes de todas las neuronas en samples. Para pasar a segundos dividir por Fs que es 30000
% spike_clusters_database.mat tiene el número de cluster de cada neurona, pero el cluster que le asigna en cada sesión
% spike_unique_clusters_database.mat tiene los id únicos de los clusters en el formato RRDDCCC


clc; % Borro el command window
clear all; % Limpio todas las variables del workspace
path = 'D:\Doctorado\Backup Ordenado\'; % Seteo el path donde estan las carpetas de los distintos animales (R01, R02, etc)
cd(path); % Entro a ese path

e = dir(cd); % Busco cuales son todos los archivos que tiene ese path
efolders = e([e(:).isdir]);
efolders = efolders(~ismember({efolders(:).name},{'.','..'})); % Me quedo solo con los que son folders

if exist('spike_clusters_database.mat','file'); % Si ese archivo ya existe, lo cargo en el workspace junto con otros
    load('spike_clusters_database.mat');
    load('spike_templates_database.mat');
    load('spike_times_database.mat');
    load('amplitudes_database.mat');
    load('spike_unique_clusters_database.mat')
else % Si no existe creo las variables vacias, que luego voy a usar para guardarle datos
    spike_clusters_database = [];
    spike_templates_database = {};
    spike_times_database = [];
    amplitudes_database = [];
    spike_unique_clusters_database = [];
end

for i = 1:size(efolders,1); % Recorro las carpetas dentro del path
    
    if efolders(i).name(1) == 'R'; % Si la carpeta comienza con la letra R
        cd(efolders(i).name); % Entro a esa carpeta
        disp(['Processing Rat: ' efolders(i).name]);
        [filpath,name,ext] = fileparts(cd); clear ext; clear filpath;
        d = dir(cd); % Busco que archivos tiene ese directorio
        dfolders = d([d(:).isdir]); 
        dfolders = dfolders(~ismember({dfolders(:).name},{'.','..'})); % Me quedo solo con los que son folders 
        
        for j = 1:size(dfolders,1); % Recorro todos los folders
            if dfolders(j).name(1) == 'R'; % Si el folder comienza con la letra R
                cd(dfolders(j).name); % Entro a ese folder
                disp(['  Processing Session: ' dfolders(j).name]);
                
                fstruct = dir('*Kilosort*'); % Busco la ruta completa de la carpeta Kilosort
                if size(fstruct,1) == 1; % Si existe la ruta a la carpeta kilosort    
                    cd(fstruct.name); % Entro a la carpeta Kilosort                  
                    if exist('spike_clusters.npy','file') && exist('cluster_info.csv','file'); % Si existen estos dos files cargo los files que se listan a continuacion
                        spike_clusters = double(readNPY('spike_clusters.npy'));
                        spike_templates = readNPY('templates.npy');
                        spike_times = double(readNPY('spike_times.npy'));
                        amplitudes = readNPY('amplitudes.npy');
                        table = readtable('cluster_info.csv');
                        cluster_unique_id = table{:,1}; % Guardo la columna 1 de la tabla como un double
                        cluster_id = table{:,4}; % Guardo la columna 2 de la tabla como un double
                        
                        for k = 1:size(spike_clusters,1);
                            spike_unique_clusters(k,1) = cluster_unique_id(find(cluster_id == spike_clusters(k))); % Creo la variable que contiene a que id unico corresponde cada spike     
                        end
                       
                        if any(spike_unique_clusters_database == cluster_unique_id(1)); % Si se cumple que un id unico esta en el database, no agrego esos datos.
                            % Do nothing
                        else % Si no se cumple, quiere decir que faltan agregar estos datos entonces los concateno al final
                            spike_clusters_database = vertcat(spike_clusters_database,spike_clusters);
                            spike_templates_database = vertcat(spike_templates_database,spike_templates);
                            spike_times_database = vertcat(spike_times_database,spike_times);
                            amplitudes_database = vertcat(amplitudes_database,amplitudes);
                            spike_unique_clusters_database = vertcat(spike_unique_clusters_database,spike_unique_clusters);
                        end
                        % Borro algunas variables que ya use ya que necesito cargar una nueva con el mismo nombre
                        clear spike_clusters spike_templates spike_times amplitudes cluster_unique_id cluster_id spike_unique_clusters table k;
                    else
                        % Do nothing    
                    end                                       
                end
            end
            cd([path efolders(i).name]); % Vuelvo al path donde estan las distintas sesiones de un mismo animal
        end
    end
    cd(path); % Vuelvo al path donde estan las carpetas de los animales
end

clear d dfolders e efolders fstruct i j name; % Borro algunas variables que estan de más

% En el path original donde estaban las distintas carpetas de los animales, guardo las variables de interes como .mat
cd(path)
save('spike_clusters_database.mat','spike_clusters_database');
save('spike_templates_database.mat','spike_templates_database');
save('spike_times_database.mat','spike_times_database');
save('amplitudes_database.mat','amplitudes_database');
save('spike_unique_clusters_database.mat','spike_unique_clusters_database');

clear path; % Borro el path que esta de más
