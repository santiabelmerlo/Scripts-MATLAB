%% Coherence quantification y Cross-spectrum para cada uno de los eventos de EventsSheet.csv
% Me guarda una planilla llamada Coherence_Sheet.csv con la cuantificación de
% la coherencia para cada una de las frecuencias y regiones. Tambien me
% guarda el Cross-Spectrum en un archivo Xpower_Sheet.csv con las potencias cruzadas.

clc
clear all

rats = 10:20;
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones

% Calculamos algunas variables que son constantes
BLA_S1 = {};
BLA_S2 = {};
PL_S1 = {};
PL_S2 = {};
IL_S1 = {};
IL_S2 = {};
BLA_C = {};
PL_C = {};
IL_C = {};
ID = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
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
    
    % Iterate through each 'RxDy' folder
    for d = 1:length(D_folders)
        current_D_folder = fullfile(current_R_folder, D_folders(d).name);
        disp(['Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            session_end = [];
            load(strcat(name,'_sessioninfo.mat'));
            if  strcmp(paradigm,paradigm_toinclude) && ...
                any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude));
                disp(['  All required files exists. Performing action...']);
                
                % Filtramos la tabla para quedarme con los IDs, y los timestamps de inicio y fin.
                filteredTable = EventsSheet(EventsSheet.Rat == r, :);
                filteredTable = filteredTable(strcmp(filteredTable.Name, name), :);
                event_ID = filteredTable.ID;
                event_inicio = filteredTable.Inicio;
                event_fin = filteredTable.Fin;

                % Analizamos Power solo si tenemos el espectrograma BLA
                region = 'BLAPL';
                if exist(strcat(name,'_Coherence_',region,'.mat')) == 2 & ...
                        size(event_ID,1) >= 1;
                    
                    % Cargamos el espectrograma
                    load(strcat(name,'_Coherence_',region,'.mat')); 
                    S = S12;
                    
                    % Interpolamos la franja de 100 Hz que es ruidosa
                    fmin = find(abs(f-98) == min(abs(f-98)));
                    fmax = find(abs(f-102) == min(abs(f-102)));
                    for i = 1:fmax-fmin;
                        S(:,fmin+i) = S(:,fmin) + i*((S(:,fmax+1)-S(:,fmin-1))/(fmax-fmin));
                        C(:,fmin+i) = C(:,fmin) + i*((C(:,fmax+1)-C(:,fmin-1))/(fmax-fmin));
                    end
                    % Interpolamos la franja de 50 Hz que es ruidosa
                    fmin = find(abs(f-48) == min(abs(f-48)));
                    fmax = find(abs(f-52) == min(abs(f-52)));
                    for i = 1:fmax-fmin;
                        S(:,fmin+i) = S(:,fmin) + i*((S(:,fmax+1)-S(:,fmin-1))/(fmax-fmin));
                        C(:,fmin+i) = C(:,fmin) + i*((C(:,fmax+1)-C(:,fmin-1))/(fmax-fmin));
                    end
                    
                    % Normalizamos para el PSD y para el Power
                    % S1 es para calcular PSD y S2 es para Power
                    S1 = bsxfun(@times, S, f);
                    S1 = bsxfun(@rdivide, S1, median(median(S1,1)));
                    S2 = zscorem(S,1); % Si queremos normalizar con zscore en vez de divividr por la mediana
                    
                    % Busco las posiciones en S donde inician y finalizan los eventos
                    j = 1;
                    for i = 1:size(event_inicio,1);
                        event_inicioenS(j) = min(find(abs(t-event_inicio(i)) == min(abs(t-event_inicio(i)))));
                        event_finenS(j) = min(find(abs(t-event_fin(i)) == min(abs(t-event_fin(i)))));
                        j = j + 1;
                    end
                    
                    % Recorremos cada evento y calculamos PSD y Power
                    for i = 1:size(event_inicio,1);
                        event_BLA_S1{i,1} = nanmedian(S1(event_inicioenS(1,i):event_finenS(1,i),:),1);
                        event_BLA_S2{i,1} = nanmedian(S2(event_inicioenS(1,i):event_finenS(1,i),:),1);
                        event_BLA_C{i,1} = nanmedian(C(event_inicioenS(1,i):event_finenS(1,i),:),1);
                    end
               else
                    event_BLA_S1 = num2cell(NaN(size(event_inicio,1),1));
                    event_BLA_S2 = num2cell(NaN(size(event_inicio,1),1));
                    event_BLA_C = num2cell(NaN(size(event_inicio,1),1));
                end
                
                % Guardamos los eventos
                BLA_S1 = cat(1,BLA_S1,event_BLA_S1);
                BLA_S2 = cat(1,BLA_S2,event_BLA_S2);
                BLA_C = cat(1,BLA_C,event_BLA_C);

                clear event_inicioenS event_finenS S12 t phi C S;
                
                % Analizamos Power solo si tenemos el espectrograma PL
                region = 'BLAIL';
                if exist(strcat(name,'_Coherence_',region,'.mat')) == 2 & ...
                        size(event_ID,1) >= 1;
                    
                    % Cargamos el espectrograma
                    load(strcat(name,'_Coherence_',region,'.mat')); 
                    S = S12;
                    
                    % Interpolamos la franja de 100 Hz que es ruidosa
                    fmin = find(abs(f-98) == min(abs(f-98)));
                    fmax = find(abs(f-102) == min(abs(f-102)));
                    for i = 1:fmax-fmin;
                        S(:,fmin+i) = S(:,fmin) + i*((S(:,fmax+1)-S(:,fmin-1))/(fmax-fmin));
                        C(:,fmin+i) = C(:,fmin) + i*((C(:,fmax+1)-C(:,fmin-1))/(fmax-fmin));
                    end
                    % Interpolamos la franja de 50 Hz que es ruidosa
                    fmin = find(abs(f-48) == min(abs(f-48)));
                    fmax = find(abs(f-52) == min(abs(f-52)));
                    for i = 1:fmax-fmin;
                        S(:,fmin+i) = S(:,fmin) + i*((S(:,fmax+1)-S(:,fmin-1))/(fmax-fmin));
                        C(:,fmin+i) = C(:,fmin) + i*((C(:,fmax+1)-C(:,fmin-1))/(fmax-fmin));
                    end
                    
                    % Normalizamos para el PSD y para el Power
                    % S1 es para calcular PSD y S2 es para Power
                    S1 = bsxfun(@times, S, f);
                    S1 = bsxfun(@rdivide, S1, median(median(S1,1)));
                    S2 = zscorem(S,1); % Si queremos normalizar con zscore en vez de divividr por la mediana
                    
                    % Busco las posiciones en S donde inician y finalizan los eventos
                    j = 1;
                    for i = 1:size(event_inicio,1);
                        event_inicioenS(j) = min(find(abs(t-event_inicio(i)) == min(abs(t-event_inicio(i)))));
                        event_finenS(j) = min(find(abs(t-event_fin(i)) == min(abs(t-event_fin(i)))));
                        j = j + 1;
                    end
                    
                    % Recorremos cada evento y calculamos PSD y Power
                    for i = 1:size(event_inicio,1);
                        event_PL_S1{i,1} = nanmedian(S1(event_inicioenS(1,i):event_finenS(1,i),:),1);
                        event_PL_S2{i,1} = nanmedian(S2(event_inicioenS(1,i):event_finenS(1,i),:),1);
                        event_PL_C{i,1} = nanmedian(C(event_inicioenS(1,i):event_finenS(1,i),:),1);
                    end
                    
                else
                    event_PL_S1 = num2cell(NaN(size(event_inicio,1),1));
                    event_PL_S2 = num2cell(NaN(size(event_inicio,1),1));
                    event_PL_C = num2cell(NaN(size(event_inicio,1),1));
                end
                
                % Guardamos los eventos
                PL_S1 = cat(1,PL_S1,event_PL_S1);
                PL_S2 = cat(1,PL_S2,event_PL_S2);
                PL_C = cat(1,PL_C,event_PL_C);

                clear event_inicioenS event_finenS S12 t phi C S;
                
                % Analizamos Power solo si tenemos el espectrograma IL
                region = 'PLIL';
                if exist(strcat(name,'_Coherence_',region,'.mat')) == 2 & ...
                        size(event_ID,1) >= 1;
                    
                    % Cargamos el espectrograma
                    load(strcat(name,'_Coherence_',region,'.mat')); 
                    S = S12;
                    
                    % Interpolamos la franja de 100 Hz que es ruidosa
                    fmin = find(abs(f-98) == min(abs(f-98)));
                    fmax = find(abs(f-102) == min(abs(f-102)));
                    for i = 1:fmax-fmin;
                        S(:,fmin+i) = S(:,fmin) + i*((S(:,fmax+1)-S(:,fmin-1))/(fmax-fmin));
                        C(:,fmin+i) = C(:,fmin) + i*((C(:,fmax+1)-C(:,fmin-1))/(fmax-fmin));
                    end
                    % Interpolamos la franja de 50 Hz que es ruidosa
                    fmin = find(abs(f-48) == min(abs(f-48)));
                    fmax = find(abs(f-52) == min(abs(f-52)));
                    for i = 1:fmax-fmin;
                        S(:,fmin+i) = S(:,fmin) + i*((S(:,fmax+1)-S(:,fmin-1))/(fmax-fmin));
                        C(:,fmin+i) = C(:,fmin) + i*((C(:,fmax+1)-C(:,fmin-1))/(fmax-fmin));
                    end
                    
                    % Normalizamos para el PSD y para el Power
                    % S1 es para calcular PSD y S2 es para Power
                    S1 = bsxfun(@times, S, f);
                    S1 = bsxfun(@rdivide, S1, median(median(S1,1)));
                    S2 = zscorem(S,1); % Si queremos normalizar con zscore en vez de divividr por la mediana                    
                    
                    % Busco las posiciones en S donde inician y finalizan los eventos
                    j = 1;
                    for i = 1:size(event_inicio,1);
                        event_inicioenS(j) = min(find(abs(t-event_inicio(i)) == min(abs(t-event_inicio(i)))));
                        event_finenS(j) = min(find(abs(t-event_fin(i)) == min(abs(t-event_fin(i)))));
                        j = j + 1;
                    end
                    
                    % Recorremos cada evento y calculamos PSD y Power
                    for i = 1:size(event_inicio,1);
                        event_IL_S1{i,1} = nanmedian(S1(event_inicioenS(1,i):event_finenS(1,i),:),1);
                        event_IL_S2{i,1} = nanmedian(S2(event_inicioenS(1,i):event_finenS(1,i),:),1);
                        event_IL_C{i,1} = nanmedian(C(event_inicioenS(1,i):event_finenS(1,i),:),1);
                    end
                    
                else
                    event_IL_S1 = num2cell(NaN(size(event_inicio,1),1));
                    event_IL_S2 = num2cell(NaN(size(event_inicio,1),1));
                    event_IL_C = num2cell(NaN(size(event_inicio,1),1));
                end
                
                % Guardamos los eventos
                IL_S1 = cat(1,IL_S1,event_IL_S1);
                IL_S2 = cat(1,IL_S2,event_IL_S2);
                IL_C = cat(1,IL_C,event_IL_C);

                clear event_inicioenS event_finenS S12 t phi C S;
                        
                if size(event_ID,1) >= 1;
                    ID = vertcat(ID,event_ID);
                end

                clear event_BLA_S1 event_BLA_S2 event_ID event_PL_S1 event_PL_S2 event_IL_S1 event_IL_S2; 
                
            else
                disp(['  Some required file do not exist.']);
                disp(['  Skipping action...']);
            end
        end
    end
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end

cd(parentFolder);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cuantificamos algunas cosas y guardamos los datos

clearvars -except f ID BLA_S1 BLA_S2 PL_S1 PL_S2 IL_S1 IL_S2 BLA_C PL_C IL_C;

% Chequeamos que tengan la dimensión 1x1967
expected_size = [1, 1967];
nan_vector = nan(1, 1967);

% Creamos los datos para guardar los PSD
ID_cell = num2cell(ID);
PSD_Sheet = [ID_cell, BLA_S1, PL_S1, IL_S1];
column_names = {'ID', 'BLA', 'PL', 'IL'};

% Comprobar y reemplazar en la columna BLA_S1 (columna 2)
for i = 1:size(PSD_Sheet, 1)
    if ~isequal(size(PSD_Sheet{i, 2}), expected_size)
        PSD_Sheet{i, 2} = nan_vector; % Reemplazar con NaN
    end
end
% Comprobar y reemplazar en la columna PL_S1 (columna 3)
for i = 1:size(PSD_Sheet, 1)
    if ~isequal(size(PSD_Sheet{i, 3}), expected_size)
        PSD_Sheet{i, 3} = nan_vector; % Reemplazar con NaN
    end
end
% Comprobar y reemplazar en la columna IL_S2 (columna 4)
for i = 1:size(PSD_Sheet, 1)
    if ~isequal(size(PSD_Sheet{i, 4}), expected_size)
        PSD_Sheet{i, 4} = nan_vector; % Reemplazar con NaN
    end
end

PSD_Sheet = sortrows(PSD_Sheet, 1);

% Comprobar y reemplazar en BLA_S1
for i = 1:length(BLA_S1)
    if ~isequal(size(BLA_S1{i}), expected_size)
        BLA_S1{i} = nan_vector; % Reemplazar con NaN
    end
end

% Comprobar y reemplazar en BLA_S2
for i = 1:length(BLA_S2)
    if ~isequal(size(BLA_S2{i}), expected_size)
        BLA_S2{i} = nan_vector; % Reemplazar con NaN
    end
end

% Comprobar y reemplazar en PL_S1
for i = 1:length(PL_S1)
    if ~isequal(size(PL_S1{i}), expected_size)
        PL_S1{i} = nan_vector; % Reemplazar con NaN
    end
end

% Comprobar y reemplazar en PL_S2
for i = 1:length(PL_S2)
    if ~isequal(size(PL_S2{i}), expected_size)
        PL_S2{i} = nan_vector; % Reemplazar con NaN
    end
end

% Comprobar y reemplazar en IL_S1
for i = 1:length(IL_S1)
    if ~isequal(size(IL_S1{i}), expected_size)
        IL_S1{i} = nan_vector; % Reemplazar con NaN
    end
end

% Comprobar y reemplazar en IL_S2
for i = 1:length(IL_S2)
    if ~isequal(size(IL_S2{i}), expected_size)
        IL_S2{i} = nan_vector; % Reemplazar con NaN
    end
end

% Comprobar y reemplazar en BLA_C
for i = 1:length(BLA_C)
    if ~isequal(size(BLA_C{i}), expected_size)
        BLA_C{i} = nan_vector; % Reemplazar con NaN
    end
end

% Comprobar y reemplazar en PL_C
for i = 1:length(PL_C)
    if ~isequal(size(PL_C{i}), expected_size)
        PL_C{i} = nan_vector; % Reemplazar con NaN
    end
end

% Comprobar y reemplazar en IL_C
for i = 1:length(IL_C)
    if ~isequal(size(IL_C{i}), expected_size)
        IL_C{i} = nan_vector; % Reemplazar con NaN
    end
end

% Creamo tabla para fuardar los Power
% Frequency bands
FourHz_idx = f >= 2 & f <= 5.3;
Theta_idx = f >= 5.3 & f <= 9.6;
Beta_idx = f >= 13 & f <= 30;
sGamma_idx = f >= 43 & f <= 60;
fGamma_idx = f >= 60 & f <= 98;

% Initialize cell arrays to store results
FourHz_BLAPL = nan(numel(ID), 1);
Theta_BLAPL = nan(numel(ID), 1);
Beta_BLAPL = nan(numel(ID), 1);
sGamma_BLAPL = nan(numel(ID), 1);
fGamma_BLAPL = nan(numel(ID), 1);

FourHz_BLAIL = nan(numel(ID), 1);
Theta_BLAIL = nan(numel(ID), 1);
Beta_BLAIL = nan(numel(ID), 1);
sGamma_BLAIL = nan(numel(ID), 1);
fGamma_BLAIL = nan(numel(ID), 1);

FourHz_PLIL = nan(numel(ID), 1);
Theta_PLIL = nan(numel(ID), 1);
Beta_PLIL = nan(numel(ID), 1);
sGamma_PLIL = nan(numel(ID), 1);
fGamma_PLIL = nan(numel(ID), 1);

FourHz_BLAPL_C = nan(numel(ID), 1);
Theta_BLAPL_C = nan(numel(ID), 1);
Beta_BLAPL_C = nan(numel(ID), 1);
sGamma_BLAPL_C = nan(numel(ID), 1);
fGamma_BLAPL_C = nan(numel(ID), 1);

FourHz_BLAIL_C = nan(numel(ID), 1);
Theta_BLAIL_C = nan(numel(ID), 1);
Beta_BLAIL_C = nan(numel(ID), 1);
sGamma_BLAIL_C = nan(numel(ID), 1);
fGamma_BLAIL_C = nan(numel(ID), 1);

FourHz_PLIL_C = nan(numel(ID), 1);
Theta_PLIL_C = nan(numel(ID), 1);
Beta_PLIL_C = nan(numel(ID), 1);
sGamma_PLIL_C = nan(numel(ID), 1);
fGamma_PLIL_C = nan(numel(ID), 1);

% Compute the nanmedian for each frequency band in BLA_S2, PL_S2, IL_S2
for i = 1:numel(ID)
    % BLAPL_S2
    FourHz_BLAPL(i) = nanmedian(BLA_S2{i}(FourHz_idx));
    Theta_BLAPL(i) = nanmedian(BLA_S2{i}(Theta_idx));
    Beta_BLAPL(i) = nanmedian(BLA_S2{i}(Beta_idx));
    sGamma_BLAPL(i) = nanmedian(BLA_S2{i}(sGamma_idx));
    fGamma_BLAPL(i) = nanmedian(BLA_S2{i}(fGamma_idx));
    
    % BLAIL_S2
    FourHz_BLAIL(i) = nanmedian(PL_S2{i}(FourHz_idx));
    Theta_BLAIL(i) = nanmedian(PL_S2{i}(Theta_idx));
    Beta_BLAIL(i) = nanmedian(PL_S2{i}(Beta_idx));
    sGamma_BLAIL(i) = nanmedian(PL_S2{i}(sGamma_idx));
    fGamma_BLAIL(i) = nanmedian(PL_S2{i}(fGamma_idx));
    
    % PLIL_S2
    FourHz_PLIL(i) = nanmedian(IL_S2{i}(FourHz_idx));
    Theta_PLIL(i) = nanmedian(IL_S2{i}(Theta_idx));
    Beta_PLIL(i) = nanmedian(IL_S2{i}(Beta_idx));
    sGamma_PLIL(i) = nanmedian(IL_S2{i}(sGamma_idx));
    fGamma_PLIL(i) = nanmedian(IL_S2{i}(fGamma_idx));
    
    % BLAPL_C
    FourHz_BLAPL_C(i) = nanmedian(BLA_C{i}(FourHz_idx));
    Theta_BLAPL_C(i) = nanmedian(BLA_C{i}(Theta_idx));
    Beta_BLAPL_C(i) = nanmedian(BLA_C{i}(Beta_idx));
    sGamma_BLAPL_C(i) = nanmedian(BLA_C{i}(sGamma_idx));
    fGamma_BLAPL_C(i) = nanmedian(BLA_C{i}(fGamma_idx));
    
    % BLAIL_C
    FourHz_BLAIL_C(i) = nanmedian(PL_C{i}(FourHz_idx));
    Theta_BLAIL_C(i) = nanmedian(PL_C{i}(Theta_idx));
    Beta_BLAIL_C(i) = nanmedian(PL_C{i}(Beta_idx));
    sGamma_BLAIL_C(i) = nanmedian(PL_C{i}(sGamma_idx));
    fGamma_BLAIL_C(i) = nanmedian(PL_C{i}(fGamma_idx));
    
    % PLIL_C
    FourHz_PLIL_C(i) = nanmedian(IL_C{i}(FourHz_idx));
    Theta_PLIL_C(i) = nanmedian(IL_C{i}(Theta_idx));
    Beta_PLIL_C(i) = nanmedian(IL_C{i}(Beta_idx));
    sGamma_PLIL_C(i) = nanmedian(IL_C{i}(sGamma_idx));
    fGamma_PLIL_C(i) = nanmedian(IL_C{i}(fGamma_idx));
end

% Create the Power_Sheet table
Xpower_Sheet = table(ID, ...
    FourHz_BLAPL, Theta_BLAPL, Beta_BLAPL, sGamma_BLAPL, fGamma_BLAPL, ...
    FourHz_BLAIL, Theta_BLAIL, Beta_BLAIL, sGamma_BLAIL, fGamma_BLAIL, ...
    FourHz_PLIL, Theta_PLIL, Beta_PLIL, sGamma_PLIL, fGamma_PLIL);

Xpower_Sheet = sortrows(Xpower_Sheet, 'ID');

% Create the Power_Sheet table
Coherence_Sheet = table(ID, ...
    FourHz_BLAPL_C, Theta_BLAPL_C, Beta_BLAPL_C, sGamma_BLAPL_C, fGamma_BLAPL_C, ...
    FourHz_BLAIL_C, Theta_BLAIL_C, Beta_BLAIL_C, sGamma_BLAIL_C, fGamma_BLAIL_C, ...
    FourHz_PLIL_C, Theta_PLIL_C, Beta_PLIL_C, sGamma_PLIL_C, fGamma_PLIL_C);

Coherence_Sheet = sortrows(Coherence_Sheet, 'ID');

% Guardamos ambos datos
cd('D:\Doctorado\Analisis\Sheets');
writetable(Xpower_Sheet, 'Xpower_Sheet.csv');
writetable(Coherence_Sheet, 'Coherence_Sheet.csv');

disp('Ready!');