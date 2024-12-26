%% Script para guardar los eventos a ser leidos por Neuroscope
clc;
clear all;

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Iterate through each 'Rxx' folder
for r = 1:length(R_folders)
    current_R_folder = fullfile(parentFolder, R_folders(r).name);
    disp(['Processing folder: ' current_R_folder]);
    
    % List all subfolders inside the 'Rxx' folder
    D_folders = dir(fullfile(current_R_folder, 'R*D*'));
    D_folders = D_folders([D_folders.isdir]);
    
    % Iterate through each 'RxDy' folder
    for d = 1:length(D_folders)
        current_D_folder = fullfile(current_R_folder, D_folders(d).name);
        disp(['  Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        % Buscamos el directorio y armamos el path en el disco H:
        currentDir = pwd;
        parts = strsplit(currentDir, '\');
        lastTwoParts = fullfile(parts{end-1}, parts{end});
        newPath = fullfile('H:\', lastTwoParts);
        
        file_1 = strcat(name, '_TTL_channel_states.npy');
        file_2 = strcat(name, '_TTL_timestamps.npy');
        file_3 = strcat(name, '_TTL_channels.npy');

        if exist(file_1, 'file') && exist(file_2, 'file') && exist(file_3, 'file') == 2
            % Cargamos los datos de los TTL y los timestamps.
            TTL_states = readNPY(strcat(name(1:6),'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
            TTL_timestamps = readNPY(strcat(name(1:6),'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
            TTL_channels = readNPY(strcat(name(1:6),'_TTL_channels.npy')); % Cargamos los estados de los canales.

            if ~isempty(TTL_timestamps)
                
                TTL_start = TTL_timestamps(1); % Seteamos el primer timestamp 
                TTL_end = TTL_timestamps(end); % Seteamos el último timestamp
                TTL_timestamps = TTL_timestamps - TTL_start; % Restamos el primer timestamp para que inicie en 0.
                
                % Buscamos los tiempos asociados a cada evento.
                % Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
                CS1.start = TTL_timestamps(find(TTL_states == 1));
                CS1.end = TTL_timestamps(find(TTL_states == -1));
                % Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
                CS2.start = TTL_timestamps(find(TTL_states == 2));
                CS2.end = TTL_timestamps(find(TTL_states == -2));
                % Inicio y fin de los nosepokes en el target. Entrada #6 del IO board.
                % IR3.start = TTL_timestamps(find(TTL_states == 6));
                % IR3.end = TTL_timestamps(find(TTL_states == -6));

                Overwrite = 1;
                SampleRate = 30000;

                % CS1.start
                Labels = 'CS1_on';
                Input = double(CS1.start);
                OutFileName = [strcat(name,'_events.c1s.evt')];
                Overwrite = 1;
                cd(currentDir);
                MakeEvtFile(Input,OutFileName,Labels,SampleRate,Overwrite);
                cd(newPath);
                MakeEvtFile(Input,OutFileName,Labels,SampleRate,Overwrite);
                cd(currentDir);

                % CS1.end
                Labels = 'CS1_off';
                Input = double(CS1.end);
                OutFileName = [strcat(name,'_events.c1e.evt')];
                Overwrite = 1;
                cd(currentDir);
                MakeEvtFile(Input,OutFileName,Labels,SampleRate,Overwrite);
                cd(newPath);
                MakeEvtFile(Input,OutFileName,Labels,SampleRate,Overwrite);
                cd(currentDir);

                % CS2.start
                Labels = 'CS2_on';
                Input = double(CS2.start);
                OutFileName = [strcat(name,'_events.c2s.evt')];
                Overwrite = 1;
                cd(currentDir);
                MakeEvtFile(Input,OutFileName,Labels,SampleRate,Overwrite);
                cd(newPath);
                MakeEvtFile(Input,OutFileName,Labels,SampleRate,Overwrite);
                cd(currentDir);

                % CS2.end
                Labels = 'CS2_off';
                Input = double(CS2.end);
                OutFileName = [strcat(name,'_events.c2e.evt')];
                Overwrite = 1;
                cd(currentDir);
                MakeEvtFile(Input,OutFileName,Labels,SampleRate,Overwrite);
                cd(newPath);
                MakeEvtFile(Input,OutFileName,Labels,SampleRate,Overwrite);
                cd(currentDir);

                disp(strcat('Saving events from session: ', name,'...'));
                
            else
                disp('Timestamps is empty...');
            end
  
        else
            disp(strcat('Events from session ',name,' do not exist...'));
        end
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end
disp('----- Ready -----');
cd(parentFolder);