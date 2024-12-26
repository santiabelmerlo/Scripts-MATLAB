%% A partir de una planilla, con los ID_cluster, rata, sesion, etc, busca los NPY
% necesarios y levanta los datos de tiempos, tipo cluster, y num de cluster y los guarda
% en una base de datos unica para los clusters.
%
% Dependencies: https://github.com/cortex-lab/spikes
% 
% tiene que tener el directorio de experimentos donde buscar.
% directorio de donde leer los clusters a meter en la DB (planilla excel)
% el directorio donde hacer el backup 
% el directorio donde guardar la DB
% el directorio donde guardar la DB para subir a la nube
% opcion si hace backup o no
% 
% tiene que leer la base de datos, y obtener las ratas, sesiones y clusters de cada una que hay en la DB
% 
% leer la planilla, leer las ratas, ssiones y numeros de clusters
% 
% comparar amabas y ver si hay que actualizarla.
% 
% tiene la forma:
% ID_general, rata, sesion, cluster_ID, cluster_ID_waveform, tetrodo,
% type(SU/MUA), estructura,t_spike(seg)
% 
% en el caso de levantas las waveform, primero lee el xml para saber de que canales levantar


function DB_clusters_generator(varargin)
%Paths
exp_path = 'D:\experimentos'; % path of data experiments
table_path = 'D:\experimentos\neuronas.xlsx'; %path and filename of the clusters table
backup_path = 'C:\Users\Marcos\Dropbox\lab - nuevo\0_BasesDeDatos'; %path to upload backup of the DB
DB_path = 'D:\experimentos'; %path to save the DB
DB_name = 'BaseDatos_neuronas'; %name of the DataBase. It will be a .mat (Matlab File)
path_scripts = 'C:\Users\Marcos\Dropbox\scripts_matlab\scripts_marcos\spikes\spikes-master'; %folder containing the dependencies scripts (spikes-master)


% p = inputParser;
% addParameter(p,'exp_path',default_exp_path,@ischar)         % path to the folder containing the data
% addParameter(p,'rata','',@ischar)                             % name of the rat to be processed
% 
% 
% parse(p,varargin{:})
% 
% experimentos_path = p.Results.exp_path;
% rata              = p.Results.rata;

% flags
flag_update = 0; %indicate if the DB must be updated
flag_save = 0; %indicate if the DB must be saved in a file
flag_existia_BD = 0; %check if the DB was already created
backup_cloud = 1; %save the DB in specific folder to be backuped on the cloud

% creation of LOG file
diary(fullfile(exp_path,'log_DB_cluster_Generator.txt'));
warning('off','all');

fprintf('\n****************************************************************\n');
fprintf('----------------- Running Cluster-DB Generator -----------------');
fprintf('\n****************************************************************\n');
t_total = tic;

%checking for necessary dependencies
if ~exist('loadKSdir.m','file')
    fprintf('Adding necessary dependencies to the path...\n\n');
    addpath(genpath(path_scripts))
end


% Warning: Notify of the default paths to be used
fprintf('\nRunning with the defaults paths. If you want to change them, specify they in the script.\n\n');
fprintf('Path to load clusters data: %s\n',exp_path);
fprintf('Path to load the table of cluster: %s\n',table_path);
fprintf('Path to save de Database: %s\n',DB_path);
fprintf('Path to save de backup on the cloud Database: %s\n',backup_path);
fprintf('----------------------------------------------------------------\n\n');

%% Loading table and DB
%-----Loading table-------
fprintf('Loading table...\n');
try
    data_table = readtable(table_path);
    fprintf('Table with clusters information loaded successfully\n');
catch
    aborting(strcat('Error while trying to load the table from file: ',table_path))
   % fprintf(2,'Error while trying to load the table from file: %s\n',table_path);
   % fprintf('Aborting...\n\n');
   % return
end
fprintf('Table loaded in %d\n\n',toc(t_total));

%-----Loading DB----------
fprintf('Ckecking for DB existance in: %s\n', DB_path);
DB_full_path = fullfile(DB_path,[DB_name,'.mat']);
if isfile(DB_full_path)
	flag_existia_BD = 1;
	fprintf('The Database: %s.mat exists in the specified path. Loading it...\n',DB_name);
else	
	flag_existia_BD = 0;
	fprintf('The Database: %s.mat does not exist in the specified path. It will be generated.\n',DB_name);
end

%Loading the data in DB
if flag_existia_BD
	try
		load(DB_full_path);
    catch
        aborting(strcat('Error loading Database file ',DB_name,'.mat in ',DB_path));
        %fprintf(2,'Error loading Database file %s.mat in %s.\n',DB_name,DB_path);
		%fprintf('Aborting...\n\n');
        %diary off
        %return
    end
    fprintf('Database loaded in %d\n\n',toc(t_total));
end


%% checking if the database is updated
%creating the DB    
if ~flag_existia_BD %creating the DB
	flag_save = 1;
	sz = [1 9];
	varTypes = ["double","double","double","double","double","double","string","string","double"];
	varNames = ["ID_neurona","rata","sesion","cluster_ID","clu_ID_wf","tetrodo","type","estructura","t_spk"];
	DB_clusters = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    DB_clusters(1,:) = [];
end

fprintf('--- Checking if the Database is updated according the table %s ---\n',table_path);
data_update = struct([]); %structure to save the data to be updated
%check if the rats in the table are already in the DB
%NOTE: if a cluster for a rat sesion in table is not present in DB, all the clusters for that sesions will be updated
n_rata_table = unique(data_table.rata); % rats in the table (sorted order)
n_rata_db = unique(DB_clusters.rata); % rats in the DB

cont_rata_update = 0; %count the number of rats to be updated

%check for rats in DB which are not longer avilable in the table and that should be deleted from DB
rat_delete = unique(setdiff(n_rata_db, n_rata_table));
if ~isempty(rat_delete)
    flag_update = 1;
    for i = 1:length(rat_delete)
        cont_rata_update = cont_rata_update + 1;
        data_update(cont_rata_update).rata = rat_delete(i);
        data_update(cont_rata_update).sesion.number = 'delete';
        data_update(cont_rata_update).sesion.clu = 'delete';
    end
end

%iterate over the rats in the table
for r = 1:length(n_rata_table)
    if ismember(n_rata_table(r),n_rata_db) %the rat is in the DB, check for the sessions
        cont_session_db = 0; %count the number of session of rat r in the table found in th DB
        cont_session_update = 0; %count the number of sessions of the rat to be updated
        
        %check if the sesions of the rat in the table are already in the DB
        n_sesion_table = unique(data_table.sesion(data_table.rata == n_rata_table(r)));
        n_sesion_db = unique(DB_clusters.sesion(DB_clusters.rata == n_rata_db(r)));
        
        %check for sessions in DB which are not longer available in the table
        session_delete = setdiff(n_sesion_db, n_sesion_table);
        if ~isempty(session_delete)
            flag_update = 1;
            cont_rata_update = cont_rata_update + 1;
            for x = 1:length(session_delete)
                cont_session_update = cont_session_update + 1;
                data_update(cont_rata_update).rata = n_rata_table(r);
                data_update(cont_rata_update).sesion(conte_session_update).number = session_delete(x);
                data_update(cont_rata_update).sesion(conte_session_update).clu = 'delete';
            end
        end
        
        %iterate over sessions in rat
        for s = 1:length(n_sesion_table)
            if any(ismember(n_sesion_table(s),n_sesion_db))
                %check if the clusters in the sesion in the table are in the DB
                %clu_db = database.ID_cluster(database.rata == n_rata_table(r) & database.sesion == n_sesion_table(s));
                %clu_table = data_table.ID_cluster(data_table.rata == n_rata_table(r) & data_table.sesion == n_sesion_table(s));
                
                %check for clusters in DB which are not longer available in the table
                %in this case remove all the cluster of the session in the DB
                n_clu_table = unique(data_table.cluster_ID(data_table.rata == n_rata_table(r) & data_table.sesion == n_sesion_table(s)));
                n_clu_db = unique(DB_clusters.cluster_ID(DB_clusters.rata == n_rata_table(r) & DB_clusters.sesion == n_sesion_table(s)));
                
                clu_delete = setdiff(n_clu_db, n_clu_table);
                if ~isempty(clu_delete)
                    flag_update = 1;
                    if isempty(session_delete)
                        cont_rata_update = cont_rata_update + 1; %increase the rat counter if it was not incremented before
                    end
                    cont_session_update = cont_session_update + 1;
                    data_update(cont_rata_update).rata = n_rata_table(r);
                    data_update(cont_rata_update).sesion(cont_session_update).number = n_sesion_table(s);
                    data_update(cont_rata_update).sesion(cont_session_update).clu = 'delete';
                end
                
                %check if cluster in the table are yet in the DB
                clu_changed = setdiff(n_clu_table, n_clu_db);
                if ~isempty(clu_changed)
                    flag_update = 1;
                    if (isempty(session_delete) || isempty(clu_changed))
                        cont_rata_update = cont_rata_update + 1; %increase the rat counter if it was not incremented before
                    end
                    cont_session_update = cont_session_update + 1;
                    
                    data_update(cont_rata_update).rata = n_rata_table(r);
                    data_update(cont_rata_update).sesion(cont_session_update).number = n_sesion_table(s);
                    data_update(cont_rata_update).sesion(cont_session_update).clu = 'changed'; %update all the cluster due a changed on them respect the sabed on the DB
                end
            else
                %if the sesion is not in the DB, update all the clusters of it
                flag_update = 1;
                if isempty(session_delete)
                    cont_rata_update = cont_rata_update + 1; %increase the rat counter if it was not incremented before
                end
                cont_session_update = cont_session_update + 1;
                
                data_update(cont_rata_update).rata = n_rata_table(r);
                data_update(cont_rata_update).sesion(cont_session_update).number = n_sesion_table(s);
                data_update(cont_rata_update).sesion(cont_session_update).clu = 'all'; %add the clusters in the DB
            end
        end %end of iterarion over sessions
    else %the rat is not in the DB, update all the clusters of it
        flag_update = 1;
        cont_rata_update = cont_rata_update + 1;
        data_update(cont_rata_update).rata = n_rata_table(r);
        data_update(cont_rata_update).sesion.number = 'all';
        data_update(cont_rata_update).sesion.clu = 'all';
    end
end %end of iteration over rats

fprintf('Finished checking for changes in the table in %d\n',toc(t_total));
clear cont_* r s n_sesion* clu_db clu_table n_rata_* rat_delete

%% Updating the database
if flag_update
    flag_save = 1;
    fprintf('The DataBase must be updated\n\n');
    fprintf('--------------------Updating the database...--------------------\n\n');
    for r = 1:size(data_update,2)
		rata_num = data_update(r).rata; %number of rats to update in DB
  		
        %generate the folder to search the rat data
        if numel(num2str(rata_num)) == 1
        	rata_name = strcat('R0',num2str(rata_num));
    	else
        	rata_name = strcat('R',num2str(rata_num));
        end
    	listing_rata = dir(fullfile(exp_path,strcat(rata_name,'*'))); %name of the folder for the rat_num

        if listing_rata.isdir && size(listing_rata,1)==1 %exist a directory with the rat name and is it unique?
        	rata_path = fullfile(exp_path,listing_rata.name,'datos');

            sesions_update = data_update(r).sesion.number; %update only the sessions specified in data_update
            idx_table_rata = find(data_table.rata == rata_num);
            
            flag_update_all = 0;
            if ischar(sesions_update) && contains(sesions_update,'all')  %update all the sessions
                sesions_update = unique(data_table.sesion(idx_table_rata)); %update all the sessions of the rat
                flag_update_all = 1;
                s_print = ['Updating all the sessions: (', repmat('%g, ', 1, numel(sesions_update)-1), '%g) for the rat: %s...\n'];
                fprintf(s_print, sesions_update,rata_name);clear s_print
            elseif ischar(sesions_update) && contains(sesions_update,'delete') %delete all the sessions of the rat
                idx_delete_database = DB_clusters.rata == rata_num;
                fprintf(2,'Warning: Removing all the sessions from the DataBase for the rat: %s. They are no longer specified in the table',rata_name);
                DB_clusters(idx_delete_database,:) = [];
                sesions_update = [];
                clear idx_delete
            end

            if ~isempty(sesions_update)
                for s = 1:length(sesions_update) %iterate over the sessions to update
                    sesion_num = sesions_update(s);
                    if numel(num2str(sesion_num))== 1
                        sesion_name = strcat('S0',num2str(sesion_num));
                    else
                        sesion_name = strcat('S',num2str(sesion_num));
                    end
                                 
                    %specifying the name of the folder for the session 
                    try
                        listing_sesion = dir(fullfile(rata_path,strcat(rata_name,'*',sesion_name)));
                        if size(listing_sesion,2) == 1 %contains only one folder for that session name
                            temp_name_sesion = listing_sesion.name;
                        else
                           aborting(strcat(': More than a folder found for the session: ',sesion_name,' for the rat: ',rata_name)); 
                        end
                        sesion_path = fullfile(rata_path,temp_name_sesion); clear temp_name_sesion
                    catch
                        %the folder was unable to be found
                        sesion_path = 'nan';
                    end
                    if isfolder(sesion_path) %exist a directory with the rat and sesion number?
                                                
                        %---check if the clu are "all", "delete" or "changed"---
                        if flag_update_all%all the sessions will be updated
                            type_clu = data_update(r).sesion.clu;
                        else
                            type_clu = data_update(r).sesion(s).clu;
                        end
                        
                        switch type_clu
                            case 'all' %load all the cluster from table and update them in DB
                                idx_table_sesion = find(data_table.rata == rata_num & (data_table.sesion == sesion_num)); %idx of session to load from table
                                update_clu = data_table.cluster_ID(idx_table_sesion); %obtain the ID_clusters to update
                                s_print = ['Updating the clusters: (', repmat('%g, ', 1, numel(update_clu)-1), '%g) for the rat: %s and session: %s...\n'];
                                fprintf(s_print, update_clu,rata_name,sesion_name);
                            case 'delete' %remove al the cluster from the DB, read the new one from table and update them in DB
                                idx_delete_database = (DB_clusters.rata == rata_num & DB_clusters.sesion == sesion_num);
                                fprintf(2,'Warning: Removing all the clusters from the DataBase for rat: %s, session: %s. They are no longer specified in the table\n',rata_name,sesion_name);
                                DB_clusters(idx_delete_database,:) = [];
                                clear idx_delete
                                
                                idx_table_sesion = find(data_table.rata == rata_num & (data_table.sesion == sesion_num)); %idx of session to load from table
                                update_clu = data_table.cluster_ID(idx_table_sesion); %obtain the ID_clusters to update
                                s_print = ['Updating the clusters: (', repmat('%g, ', 1, numel(update_clu)-1), '%g) for the rat: %s and session: %s...\n'];
                                fprintf(s_print, update_clu,rata_name,sesion_name);
                            case 'changed'%remove al the cluster from the DB, read the new one from table and update them in DB
                                idx_delete_database = (DB_clusters.rata == rata_num & DB_clusters.sesion == sesion_num);
                                fprintf(2,'Warning: Removing all the clusters from the DataBase for rat: %s, session: %s. Some of them have been changed in the table\n',rata_name,sesion_name);
                                DB_clusters(idx_delete_database,:) = [];
                                clear idx_delete
                                
                                idx_table_sesion = find(data_table.rata == rata_num & (data_table.sesion == sesion_num)); %idx of session to load from table
                                update_clu = data_table.cluster_ID(idx_table_sesion); %obtain the ID_clusters to update
                                s_print = ['Updating the clusters: (', repmat('%g, ', 1, numel(update_clu)-1), '%g) for the rat: %s and session: %s...\n'];
                                fprintf(s_print, update_clu,rata_name,sesion_name);
                                
                            otherwise
                                aborting(': the classification of cluster to update in data_update.');
                        end
                        
                        %---generating KS path-------
                        listing_ks = dir(fullfile(sesion_path,'Kilosort_*')); %searching for KS directory
                        if size(listing_ks,1)>1 %exist more than one kilosort clustered data
                           fprintf(2,'Warning: More than one Kilosort directory found for rat: %s, sesion: %s. Please select one:\n',rata_name,sesion_name);
                           loop = 1;
                           while loop
                                for i = 1:size(listing_ks)
                                    fprintf(2,'[%d] %s\n',i,listing_ks(i).name);
                                end
                                fprintf('[c] To cancel and abort\n\n');
                                option = input('Option:','s');
                                
                                if contains(option,'c')
                                    aborting(':Cancel option selected.')
                                elseif str2double(option)<=size(listing_ks,1)
                                    fprintf('Selected the Kilosort directory: %s\n\n',listing_ks(str2double(option)).name);
                                    ks_name = listing_ks(str2double(option)).name;
                                    loop = 0;
                                else
                                    fprintf('Please select a correct option!\n');
                                    loop = 1;
                                end
                            end %end of the while
                        elseif size(listing_ks,1)==1 %only one KS folder found
                            ks_name = listing_ks.name;
                        else
                            ks_name = 'nan';
                        end %end selecting KS_dir
                        ks_path = fullfile(sesion_path,ks_name);                    
                       
                        %----loading cluster info from KS_path-----
                        if isfolder(ks_path)
                            %loading the NPY and TSV files
                            try
                                sp = loadKSdir(ks_path);
                            catch
                                aborting('loading Kilosort files in specified path.');
                            end
                            if isfile(fullfile(ks_path,'cluster_type.tsv'))
                                fid = fopen(fullfile(ks_path,'cluster_type.tsv'));
                                C = textscan(fid, '%s%s');
                                fclose(fid);
                                sp.clu_id = cellfun(@str2num,C{1}(2:end,1)); %identity of cluster
                                sp.clu_type = string(C{2}(2:end,1)); %type of cluster (MUA/SU) for clu_id
                                clear C
                            else
                                aborting(strcat(':The file "cluster_type.tsv" was not found for rat: ',rata_name,', session: ',sesion_name));
                            end
                                                        
                            %---iterating over the clusters---
                            for c = 1:length(update_clu)
                                clu_ID = update_clu(c);
                                if any(ismember(sp.clu_id,clu_ID)) %is the cluster in the table inside the Phy files?
                                    %loading information of cluster to update from table
                                    %ID_general, rata, sesion, cluster_ID, cluster_ID_wf, tetrodo, type(SU/MUA), estructura,
                                    idx_clu_table = find(data_table.rata == rata_num & (data_table.sesion == sesion_num) & (data_table.cluster_ID == clu_ID)); %idx of cluster to update in table
                                    clu_ID_general = data_table.ID_general(idx_clu_table);
                                    clu_ID_wf = data_table.cluster_ID_wf(idx_clu_table);
                                    clu_tetrodo = data_table.tetrodo(idx_clu_table);
                                    clu_estructura = data_table.estructura(idx_clu_table);
                                    clu_type = data_table.type(idx_clu_table);
                                    
                                    idx = size(DB_clusters,1); %idx to start concatenatenation data in the DB
                                                              
                                    %generating the index range to concatenate the data in the DB
                                    idx_clu = find(sp.clu == clu_ID);
                                    idx_range = (idx + 1:1:(idx + length(idx_clu)));
                                                                        
                                    %adding cluster in the DB
                                    %["ID_neurona","rata","sesion","clu_ID","clu_ID_wf","tetrodo","estructura",'t_spk'];
                                    DB_clusters.ID_neurona(idx_range) = clu_ID_general;
                                    DB_clusters.rata(idx_range) = rata_num;
                                    DB_clusters.sesion(idx_range) = sesion_num;
                                    DB_clusters.cluster_ID(idx_range) = clu_ID;
                                    DB_clusters.clu_ID_wf(idx_range) = clu_ID_wf;
                                    DB_clusters.tetrodo(idx_range) = clu_tetrodo;
                                    DB_clusters.type(idx_range) = clu_type;
                                    DB_clusters.estructura(idx_range) = clu_estructura;
                                    DB_clusters.t_spk(idx_range) = sp.st(idx_clu);
                                    
                                else %the cluster to be updated from table is not presente in the PHY files
                                    fprintf(2,'Warning: The cluster %d was not found in the Kilosort folder for rat: %s, session: %s\n\n',clu_ID,rata_name,sesion_name);
                                end
                            end %end iteration over clusters
                            
                        else %KS directory not found
                            aborting(strcat('The Kilosort folder was not found for rat: ',rata_name,', session: ',sesion_name));
                        end %end checking KS_dir
                    else
                        fprintf(2,'Warning: The folder for session: %s for rat: %s was not found.\n\n',sesion_name,rata_name);
                    end %end checking if the session folder exist
                end %end iterating over sesions to be updated form data_update
            end %end if checks sessions_update is empty
        end %end checking rat directory
    end
else
    fprintf('\nThe database is updated. No changes were made.\n');
    fprintf('----------------------------------------------------------------\n\n');
end %end flag update


%% Save and backup the DB
if flag_save 
	if flag_existia_BD
        temp_dir = dir(DB_full_path);
        DB_full_path_backup = fullfile(DB_path,[DB_name,'_backup.mat']);
        fprintf('Generating a backup of the existing DataBase with date %s\n',temp_dir.date); clear temp_dir
        status_backup = movefile(DB_full_path,DB_full_path_backup);
        if status_backup == 1
            fprintf('The DataBase was successfully backuped: %s \n\n',[DB_name,'_backup.mat']);
        else
            fprintf(2,'Warning: failed to backup the existing DataBase\n\n');
        end
	end
	save(DB_full_path,'DB_clusters','-v7.3');
    fprintf('\nThe DataBase was successfully saved as %s !!!\n\n',[DB_name,'.mat']);

    if backup_cloud
        status_cloud = copyfile(DB_full_path,fullfile(backup_path,[DB_name,'.mat']));
        if status_cloud == 1
            fprintf('The DataBase was copied to be backuped in the cloud to the folder: %s \n\n',backup_path);
        else
            fprintf(2,'Warning: failed to copy the DataBase to be backup on the cloud to folder: %s\n\n',backup_path);
        end
    end
    fprintf('----------------------------------------------------------------\n\n');
end
% Close LOG file and any file opened
warning('on','all');
fclose('all');
diary off
end %end function

function aborting(msg)
%Exit the main script/function closing all the open files and closing the diary
% msg: must be a string to show in the error output message
    diary off
    fclose('all');
    
    testerr.message = 'Aborting...';
    testerr.identifier = '';
    testerr.stack.file = '';
    testerr.stack.name = strcat(':',msg);
    testerr.stack.line = 1;
    error(testerr)
end