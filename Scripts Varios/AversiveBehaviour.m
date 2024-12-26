%% Script que carga los datos de cada sesión apetitiva y me genera la tabla para exportar a graphpad
clc
clear all;
cd('D:\Doctorado\Backup Ordenado');
main = pwd;

extinction1_sessions = ['R11/R11D12';'R12/R12D13';'R13/R13D12';'R17/R17D12';'R18/R18D12';'R19/R19D14';'R20/R20D14'];
extinction2_sessions = ['R11/R11D13';'R12/R12D14';'R13/R13D13';'R17/R17D13';'R18/R18D13';'R19/R19D15';'R20/R20D15'];
reinstatement_sessions = ['R11/R11D14';'R12/R12D15';'R13/R13D14';'R17/R17D14';'R18/R18D14';'R19/R19D16'];

% Creamos la tabla de extinción 1
extinction1_sec = nan(21,21);
extinction1_porc = nan(21,21);
binned_extinction1_sec = nan(11,21);
binned_extinction1_porc = nan(11,21);

for i = 1:size(extinction1_sessions,1);
    cd(strcat(main,'/',extinction1_sessions(i,:)));
    load(strcat(extinction1_sessions(i,end-5:end),'_freezing.mat'),'freezing','freezing_binned','freezing_preCS','freezing_preCS_porc');
    % Copiamos los preCS
    extinction1_sec(1,i) = freezing_preCS;
    extinction1_porc(1,i) = freezing_preCS_porc;
    binned_extinction1_sec(1,i) = freezing_preCS;
    binned_extinction1_porc(1,i) = freezing_preCS_porc;
    % Copiamos los CS1
    extinction1_sec(2:end,i+7) = freezing.freezing_CS1;
    extinction1_porc(2:end,i+7) = freezing.freezing_CS1_porc;
    binned_extinction1_sec(2:end,i+7) = freezing_binned.freezing_CS1_binned;
    binned_extinction1_porc(2:end,i+7) = freezing_binned.freezing_CS1_binned_porc;
    % Copiamos los CS2
    extinction1_sec(2:end,i+14) = freezing.freezing_CS2;
    extinction1_porc(2:end,i+14) = freezing.freezing_CS2_porc;
    binned_extinction1_sec(2:end,i+14) = freezing_binned.freezing_CS2_binned;
    binned_extinction1_porc(2:end,i+14) = freezing_binned.freezing_CS2_binned_porc;
end

% Creamos la tabla de extinción 2
extinction2_sec = nan(21,21);
extinction2_porc = nan(21,21);
binned_extinction2_sec = nan(11,21);
binned_extinction2_porc = nan(11,21);

for i = 1:size(extinction2_sessions,1);
    cd(strcat(main,'/',extinction2_sessions(i,:)));
    load(strcat(extinction2_sessions(i,end-5:end),'_freezing.mat'),'freezing','freezing_binned','freezing_preCS','freezing_preCS_porc');
    % Copiamos los preCS
    extinction2_sec(1,i) = freezing_preCS;
    extinction2_porc(1,i) = freezing_preCS_porc;
    binned_extinction2_sec(1,i) = freezing_preCS;
    binned_extinction2_porc(1,i) = freezing_preCS_porc;
    % Copiamos los CS1
    extinction2_sec(2:end,i+7) = freezing.freezing_CS1;
    extinction2_porc(2:end,i+7) = freezing.freezing_CS1_porc;
    binned_extinction2_sec(2:end,i+7) = freezing_binned.freezing_CS1_binned;
    binned_extinction2_porc(2:end,i+7) = freezing_binned.freezing_CS1_binned_porc;
    % Copiamos los CS2
    extinction2_sec(2:end,i+14) = freezing.freezing_CS2;
    extinction2_porc(2:end,i+14) = freezing.freezing_CS2_porc;
    binned_extinction2_sec(2:end,i+14) = freezing_binned.freezing_CS2_binned;
    binned_extinction2_porc(2:end,i+14) = freezing_binned.freezing_CS2_binned_porc;
end

% Creamos la tabla de reinstatement
reinstatement_sec = nan(11,21);
reinstatement_porc = nan(11,21);
binned_reinstatement_sec = nan(6,21);
binned_reinstatement_porc = nan(6,21);

for i = 1:size(reinstatement_sessions,1);
    cd(strcat(main,'/',reinstatement_sessions(i,:)));
    load(strcat(reinstatement_sessions(i,end-5:end),'_freezing.mat'),'freezing','freezing_binned','freezing_preCS','freezing_preCS_porc');
    % Copiamos los preCS
    reinstatement_sec(1,i) = freezing_preCS;
    reinstatement_porc(1,i) = freezing_preCS_porc;
    binned_reinstatement_sec(1,i) = freezing_preCS;
    binned_reinstatement_porc(1,i) = freezing_preCS_porc;
    % Copiamos los CS1
    reinstatement_sec(2:size(freezing.freezing_CS1,1)+1,i+7) = freezing.freezing_CS1;
    reinstatement_porc(2:size(freezing.freezing_CS1_porc,1)+1,i+7) = freezing.freezing_CS1_porc;
    binned_reinstatement_sec(2:size(freezing_binned.freezing_CS1_binned,1)+1,i+7) = freezing_binned.freezing_CS1_binned;
    binned_reinstatement_porc(2:size(freezing_binned.freezing_CS1_binned_porc,1)+1,i+7) = freezing_binned.freezing_CS1_binned_porc;
    % Copiamos los CS2
    reinstatement_sec(2:size(freezing.freezing_CS2,1)+1,i+14) = freezing.freezing_CS2;
    reinstatement_porc(2:size(freezing.freezing_CS2_porc,1)+1,i+14) = freezing.freezing_CS2_porc;
    binned_reinstatement_sec(2:size(freezing_binned.freezing_CS2_binned,1)+1,i+14) = freezing_binned.freezing_CS2_binned;
    binned_reinstatement_porc(2:size(freezing_binned.freezing_CS2_binned_porc,1)+1,i+14) = freezing_binned.freezing_CS2_binned_porc;
end

clear i freezing freezing_binned freezing_preCS freezing_preCS_porc

cd('D:\Doctorado\Analisis');
save('Behaviour_aversive.mat');
disp('Behaviour_aversive.mat already saved!');