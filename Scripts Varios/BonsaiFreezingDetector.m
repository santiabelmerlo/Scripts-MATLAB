clc;
clear all;
path = pwd;
cd(path);
[~,name,~] = fileparts(pwd);
name = name(1:6);

video_freezing = csvread(strcat(name,'_bonsai_freezing.csv'));
video_CS1 = csvread(strcat(name,'_bonsai_CS1.csv'));
video_CS2 = csvread(strcat(name,'_bonsai_CS2.csv'));

% Corregimos los tiempos a partir del pulso CS1
video_CS1_zscore = zscore(video_CS1);
video_CS1_zscore = video_CS1_zscore - min(video_CS1_zscore);
video_CS1_on = video_CS1_zscore >= 1;
CS1_on = find(diff(video_CS1_on) == 1);
CS1_off = find(diff(video_CS1_on) == -1);
CS1_duration = CS1_off - CS1_on;
CS1_on = CS1_on(find(CS1_duration > 1000));
CS1_off = CS1_on + 1500;
CS1_duration = CS1_off - CS1_on;

% Corregimos los tiempos a partir del pulso CS2
video_CS2_zscore = zscore(video_CS2);
video_CS2_zscore = video_CS2_zscore - min(video_CS2_zscore);
video_CS2_on = video_CS2_zscore >= 1;
CS2_on = find(diff(video_CS2_on) == 1);
CS2_off = find(diff(video_CS2_on) == -1);
CS2_duration = CS2_off - CS2_on;
CS2_on = CS2_on(find(CS2_duration > 1000));
CS2_off = CS2_on + 1500;
CS2_duration = CS2_off - CS2_on;

figure()
ax1 = subplot(221);
plot(video_CS1_zscore);
hold on
stem(CS1_on,repmat(1,1,3));
hold on
stem(CS1_off,repmat(1,1,3));
hold on
plot(video_CS2_zscore);
hold on
stem(CS2_on,repmat(1,1,3));
hold on
stem(CS2_off,repmat(1,1,3));
xlabel('Time (frames)')
ylabel('Movement (zscored)')
title('Bonsai video movement and CS detection')

video_freezing_zscore = zscore(video_freezing);
video_freezing_zscore = video_freezing_zscore - min(video_freezing_zscore);
% Detectamos el freezing
th = 0.02;
freezing = video_freezing_zscore < th;
inicio_freezing = find(diff(freezing) == 1);
fin_freezing = find(diff(freezing) == -1);

% Borramos inicio y fin tienen distintas dimensiones
if inicio_freezing(1) >= fin_freezing(1);
    if size(inicio_freezing,1) > size(fin_freezing,1); 
        inicio_freezing(end) = [];
    elseif size(inicio_freezing,1) < size(fin_freezing,1);
        fin_freezing(1) = [];
    elseif size(inicio_freezing,1) == size(fin_freezing,1);
        inicio_freezing(end) = [];
        fin_freezing(1) = [];
    end
elseif fin_freezing(end) <= inicio_freezing(end);
    inicio_freezing(end) = [];
end
duracion_freezing = fin_freezing - inicio_freezing;

ax2 = subplot(222)
hist(duracion_freezing/25,100);
xlim([0 30]);
xlabel('Freezing length (sec.)')
ylabel('Frequency')
title('Freezing length before > 1 sec filter')

% Calculamos la duración del freezing
freezing = duracion_freezing >= 25; % Mayor a 1 seg o 25 frames
freezing_indices = find(freezing == 1);
inicio_freezing = inicio_freezing(freezing_indices);
fin_freezing = fin_freezing(freezing_indices);
duracion_freezing = duracion_freezing(freezing_indices);

ax3 = subplot(223);
hist(duracion_freezing/25,100);
xlim([0 30]);
xlabel('Freezing length (sec.)')
ylabel('Frequency')
title('Freezing length after > 1 sec filter')

% Creamos un vector que tenga la duración del video en frames y que sea 1
% cuando el animal freeza y 0 cuando no freeza
video_freezing_on = zeros(size(video_freezing));
for i = 1:size(inicio_freezing,1)
    video_freezing_on(inicio_freezing(i):fin_freezing(i)) = 1;
end

% Cuantificamos freezing en cada tono
for i = 1:size(CS1_on,1)
    CS_freezing(i,1) = sum(video_freezing_on(CS1_on(i):CS1_off(i)))/25;
    CS_freezing(i,2) = sum(video_freezing_on(CS2_on(i):CS2_off(i)))/25;
end

% Calculamos en porcentaje
CS_freezing_porc = (CS_freezing/60)*100;

% Calculamos el preCS
preCS = sum(video_freezing_on(CS1_on(1)-1500:CS1_on(1)))/25;
preCS_porc = (preCS/60)*100;

clear i 

cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
cs2_color = [96 96 96]/255; % Seteo el color para el CS-

ax4 = subplot(224);
scatter(1,preCS_porc); hold on;
plot(2:4,CS_freezing(:,1),'color',cs1_color,'Linewidth',3); hold on;
plot(2:4,CS_freezing(:,2),'color',cs2_color,'Linewidth',3); hold on;
xlim([0.5 4.5]);
ylim([0 60]);
xlabel('Trial');
ylabel('Freezing (%)');
title('Freezing during training');

% save([strcat(name,'_freezing.mat')]);
disp('Ready!')

%% Cargamos los archivos de freezing
clc
clear all
R11 = load('D:\Doctorado\Backup Ordenado\R11\R11D11\R11D11_freezing.mat');
R12 = load('D:\Doctorado\Backup Ordenado\R12\R12D12\R12D12_freezing.mat');
R13 = load('D:\Doctorado\Backup Ordenado\R13\R13D11\R13D11_freezing.mat');
R17 = load('D:\Doctorado\Backup Ordenado\R17\R17D11\R17D11_freezing.mat');
R18 = load('D:\Doctorado\Backup Ordenado\R18\R18D11\R18D11_freezing.mat');
R19 = load('D:\Doctorado\Backup Ordenado\R19\R19D13\R19D13_freezing.mat');
R20 = load('D:\Doctorado\Backup Ordenado\R20\R20D13\R20D13_freezing.mat');
