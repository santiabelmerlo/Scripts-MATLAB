%% Script para calcular el porcentaje del evento que está enriquecido en 4Hz y el porcentaje del evento enriquecido en Theta
clc
clear all

rats = 10:20;
paradigm_toinclude = 'aversive';
session_toinclude = {'EXT1','EXT2','TEST'};

% Variables para almacenar resultados
ID = [];
FourHz_Enrich = [];
Theta_Enrich = [];
FourHz_Time = [];
Theta_Time = [];
EnrichSeries = {};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Cargamos la tabla de EventsSheet
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

for r = rats % Iterate through each 'Rxx' folder
    current_R_folder = fullfile(parentFolder, R_folders(r).name);
    disp(['Processing folder: ' current_R_folder]);
    
    % List all subfolders inside the 'Rxx' folder
    D_folders = dir(fullfile(current_R_folder, 'R*D*'));
    D_folders = D_folders([D_folders.isdir]);
    
    for d = 1:length(D_folders)
        current_D_folder = fullfile(current_R_folder, D_folders(d).name);
        disp(['Processing subfolder: ' current_D_folder]);
        
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            session_end = [];
            load(strcat(name,'_sessioninfo.mat'));
            if  strcmp(paradigm,paradigm_toinclude) && ...
                any(strcmp(session, session_toinclude)) || any(strcmp(session_end, session_toinclude));
                disp(['  All required files exists. Performing action...']);
                
                % Filtramos la tabla para quedarme con los IDs, y los timestamps de inicio y fin.
                filteredTable = EventsSheet(EventsSheet.Rat == r, :);
                filteredTable = filteredTable(strcmp(filteredTable.Name, name), :);
                event_ID = filteredTable.ID;
                event_inicio = filteredTable.Inicio;
                event_fin = filteredTable.Fin;

                % Espectrogramas de BLA, PL e IL
                regiones = {'BLA', 'PL', 'IL'};
                relation_vectors = cell(1, 3); % Almacenamos las relaciones por región
                
                for reg_idx = 1:length(regiones)
                    region = regiones{reg_idx};
                    if exist(strcat(name, '_specgram_', region, 'LowFreq.mat')) == 2 && ...
                            size(event_ID, 1) >= 1;
                        
                        % Cargamos el espectrograma
                        load(strcat(name, '_specgram_', region, 'LowFreq.mat'));
                        
                        % Interpolamos ruidos
                        for freq = [50, 100]
                            fmin = find(abs(f - (freq - 2)) == min(abs(f - (freq - 2))));
                            fmax = find(abs(f - (freq + 2)) == min(abs(f - (freq + 2))));
                            for i = 1:fmax - fmin
                                S(:, fmin + i) = S(:, fmin) + i * ((S(:, fmax + 1) - S(:, fmin - 1)) / (fmax - fmin));
                            end
                        end
                        
                        % Normalizamos para el cálculo de potencia
                        S2 = bsxfun(@rdivide, S, median(S, 1));
                        
                        % Índices de frecuencia
                        FourHz_idx = f >= 2 & f <= 5.3;
                        Theta_idx = f >= 5.3 & f <= 9.6;

                        % Iteramos por eventos
                        relation_vectors{reg_idx} = cell(size(event_inicio));
                        for i = 1:size(event_inicio, 1)
                            event_inicio_idx = min(find(abs(t - event_inicio(i)) == min(abs(t - event_inicio(i)))));
                            event_fin_idx = min(find(abs(t - event_fin(i)) == min(abs(t - event_fin(i)))));
                            
                            % Relación FourHz/Theta tiempo a tiempo
                            fourHz_power = mean(S2(event_inicio_idx:event_fin_idx, FourHz_idx), 2);
                            theta_power = mean(S2(event_inicio_idx:event_fin_idx, Theta_idx), 2);
                            relation_vectors{reg_idx}{i} = fourHz_power ./ theta_power;
                        end
                    else
                        relation_vectors{reg_idx} = repmat({NaN}, size(event_inicio));
                    end
                end
                
                clear rel_BLA rel_PL rel_IL
                % Promediamos las relaciones de las tres regiones y calculamos porcentajes
                for i = 1:size(event_ID, 1)
                    if length(relation_vectors{1}{1}) == length(relation_vectors{2}{1}) && length(relation_vectors{1}{1}) == length(relation_vectors{3}{1})
                        rel_BLA = relation_vectors{1}{i};
                        rel_PL = relation_vectors{2}{i};
                        rel_IL = relation_vectors{3}{i};

                        % Promedio de las relaciones
                        combined_relation = nanmean([rel_BLA, rel_PL, rel_IL], 2);

                        % Porcentajes enriquecidos
                        FourHz_percentage = sum(combined_relation > 1) / numel(combined_relation) * 100;
                        Theta_percentage = sum(combined_relation <= 1) / numel(combined_relation) * 100;

                        % Tiempos enriquecidos
                        FourHz_time = sum(combined_relation > 1) * (t(2) - t(1));
                        Theta_time = sum(combined_relation <= 1) * (t(2) - t(1));

                        % Guardamos los resultados
                        ID = cat(1, ID, event_ID(i));
                        FourHz_Enrich = cat(1, FourHz_Enrich, FourHz_percentage);
                        Theta_Enrich = cat(1, Theta_Enrich, Theta_percentage);
                        FourHz_Time = cat(1, FourHz_Time, FourHz_time);
                        Theta_Time = cat(1, Theta_Time, Theta_time);
                        EnrichSeries = cat(1,EnrichSeries, {combined_relation});
                    end
                end
            end
        end
    end
end

% Crear la tabla final y guardar
Power_Enrich_Sheet = table(ID, FourHz_Enrich, Theta_Enrich, FourHz_Time, Theta_Time);
cd('D:\Doctorado\Analisis\Sheets');
writetable(Power_Enrich_Sheet, 'PorcEnrich_Sheet.csv');
save('PowerEnrich_Sheet.mat','EnrichSeries','ID','Power_Enrich_Sheet');

disp('Ready!');
