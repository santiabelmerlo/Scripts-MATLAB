%% BLA Lowband
% Power Spectrum durante el primer segundo del freezing
% Este script requiere de correr primero el script "SpectrogramHighLowFreq.m"

cs1_color = [255 67 66]/255; % Seteo el color para el CS1
cs2_color = [70 171 215]/255; % Seteo el color para el CS2
freezing_color = [255 67 66]/255; % Seteo el color para el freezing
locomotion_color = [255 67 66]/255; % Seteo el color para locomotion

clear T1 T2;

% Calculamos los momentos del espectrograma en los cuales inicia el freezing y calculamos el espectro de potencias del primer segundo del comportamiento
for i = 1:length(inicio_freezing)-1;
    t_positions_start = find(abs(t_lowband_BLA - inicio_freezing(i)) == min(abs(t_lowband_BLA - inicio_freezing(i)))); % Buscamos los timestamps del espectrograma donde inicia el freezing
    paso = mean(unique(diff(t_lowband_BLA))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*2; % Analizamos el espectro de potencias hasta 1 seg lugo del onset del freezing
    S = S_lowband_BLA(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T1(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum1 = mean(T1,1);
sem2 = std(T1,1)/sqrt(size(T1,1));
SEM(1,:) = powerspectrum1 + sem2;
SEM(2,:) = powerspectrum1 - sem2;
plot_vector(powerspectrum1,f_lowband_BLA,'l',SEM,'m');
xlabel(['Frequency (Hz)']); ylabel(['Power (a.u.,10*log10)']); title(['BLA Low Freq Power Spectrum']);
clear S sem2 SEM t_positions_start t_positions_end paso i;
hold on

% Calculamos los momentos del espectrograma en los cuales hay movilidad y calculamos el espectro de potencias del primer segundo del comportamiento
for i = 1:length(fin_freezing)-1;
    paso = mean(unique(diff(t_lowband_BLA))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = randi((length(t_lowband_BLA)-(int64(1/paso))*2),1,1); % Calculamos tiempos random
    t_positions_end = t_positions_start + (int64(1/paso))*2; % Analizamos el espectro de potencias hasta 1 seg lugo del onset del freezing
    S = S_lowband_BLA(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T2(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end paso % Borramos las variables que no me sirven
end
powerspectrum2 = mean(T2,1);
sem2 = std(T2,1)/sqrt(size(T2,1));
SEM(1,:) = powerspectrum2 + sem2;
SEM(2,:) = powerspectrum2 - sem2;
plot_vector(powerspectrum2,f_lowband_BLA,'l',SEM,'g');
xlabel(['Frequency (Hz)']); ylabel(['Log Power (a.u.)']); 
clear S powerspectrum sem2 SEM t_positions_start t_positions_end paso i;

% Graficamos en el inset la cuantificación de un rango de potencias
freq1 = find(abs(f_lowband_BLA - 1) == min(abs(f_lowband_BLA - 1)));
freq2 = find(abs(f_lowband_BLA - 4) == min(abs(f_lowband_BLA - 4)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.68 .64 .2 .2])
box on

plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'm', 'MarkerFaceColor', 'm');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'g', 'MarkerFaceColor', 'g');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','m','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','g','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('1-4 Hz Mean Power', 'FontSize', 4);
Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'Freezing'; 'Random'})
set(gca,'FontSize',8);
hold on
[p] = ranksum(pwr1,pwr2);
if p >= 0.05;
    p_value_res = 'ns';
elseif p < 0.05 && p >= 0.01;
    p_value_res = '*';
elseif p < 0.01 && p >= 0.001 ;
    p_value_res = '**';
elseif p < 0.001 && p >= 0.0001  ;
    p_value_res = '***';
elseif p < 0.0001 && p >= 0.00001 ;
    p_value_res = '****';
else
    p_value_res = '*****';
end
text(1.5,60,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);

%% BLA Highband
% Power Spectrum durante el primer segundo del freezing
% Este script requiere de correr primero el script "SpectrogramHighHighFreq.m"

cs1_color = [255 67 66]/255; % Seteo el color para el CS1
cs2_color = [70 171 215]/255; % Seteo el color para el CS2
freezing_color = [255 67 66]/255; % Seteo el color para el freezing
locomotion_color = [255 67 66]/255; % Seteo el color para locomotion

clear T1 T2;

% Calculamos los momentos del espectrograma en los cuales inicia el freezing y calculamos el espectro de potencias del primer segundo del comportamiento
for i = 1:length(inicio_freezing)-1;
    t_positions_start = find(abs(t_highband_BLA - inicio_freezing(i)) == min(abs(t_highband_BLA - inicio_freezing(i)))); % Buscamos los timestamps del espectrograma donde inicia el freezing
    paso = mean(unique(diff(t_highband_BLA))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*2; % Analizamos el espectro de potencias hasta 1 seg lugo del onset del freezing
    S = S_highband_BLA(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T1(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum1 = mean(T1,1);
sem2 = std(T1,1)/sqrt(size(T1,1));
SEM(1,:) = powerspectrum1 + sem2;
SEM(2,:) = powerspectrum1 - sem2;
plot_vector(powerspectrum1,f_highband_BLA,'l',SEM,'m');
xlabel(['Frequency (Hz)']); ylabel(['Power (a.u.)']); title(['BLA High Freq Power Spectrum']);
clear S sem2 SEM t_positions_start t_positions_end paso i;
hold on

% Calculamos los momentos del espectrograma en los cuales hay movilidad y calculamos el espectro de potencias del primer segundo del comportamiento
for i = 1:length(fin_freezing)-1;
    paso = mean(unique(diff(t_highband_BLA))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = randi((length(t_highband_BLA)-(int64(1/paso))*2),1,1); % Calculamos tiempos random
    t_positions_end = t_positions_start + (int64(1/paso))*2; % Analizamos el espectro de potencias hasta 1 seg lugo del onset del freezing
    S = S_highband_BLA(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T2(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end paso % Borramos las variables que no me sirven
end
powerspectrum2 = mean(T2,1);
sem2 = std(T2,1)/sqrt(size(T2,1));
SEM(1,:) = powerspectrum2 + sem2;
SEM(2,:) = powerspectrum2 - sem2;
plot_vector(powerspectrum2,f_highband_BLA,'l',SEM,'g');
xlabel(['Frequency (Hz)']); ylabel(['Log Power (a.u.)']); 
clear S powerspectrum sem2 SEM t_positions_start t_positions_end paso i;

% Graficamos en el inset la cuantificación de un rango de potencias
freq1 = find(abs(f_highband_BLA - 60) == min(abs(f_highband_BLA - 60)));
freq2 = find(abs(f_highband_BLA - 120) == min(abs(f_highband_BLA - 120)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.68 .64 .2 .2])
box on

plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'm', 'MarkerFaceColor', 'm');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'g', 'MarkerFaceColor', 'g');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','m','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','g','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('60-120 Hz Mean Power', 'FontSize', 4);
set(gca,'xtick',[1:2],'xticklabel',{'Freezing'; 'Random'})
set(gca,'FontSize',8);
hold on
[p] = ranksum(pwr1,pwr2);
if p >= 0.05;
    p_value_res = 'ns';
elseif p < 0.05 && p >= 0.01;
    p_value_res = '*';
elseif p < 0.01 && p >= 0.001 ;
    p_value_res = '**';
elseif p < 0.001 && p >= 0.0001  ;
    p_value_res = '***';
elseif p < 0.0001 && p >= 0.00001 ;
    p_value_res = '****';
else
    p_value_res = '*****';
end
text(1.5,40,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);

%% PFC Lowband
% Power Spectrum durante el primer segundo del freezing
% Este script requiere de correr primero el script "SpectrogramHighLowFreq.m"

cs1_color = [255 67 66]/255; % Seteo el color para el CS1
cs2_color = [70 171 215]/255; % Seteo el color para el CS2
freezing_color = [255 67 66]/255; % Seteo el color para el freezing
locomotion_color = [255 67 66]/255; % Seteo el color para locomotion

clear T1 T2;

% Calculamos los momentos del espectrograma en los cuales inicia el freezing y calculamos el espectro de potencias del primer segundo del comportamiento
for i = 1:length(inicio_freezing)-1;
    t_positions_start = find(abs(t_lowband_PFC - inicio_freezing(i)) == min(abs(t_lowband_PFC - inicio_freezing(i)))); % Buscamos los timestamps del espectrograma donde inicia el freezing
    paso = mean(unique(diff(t_lowband_PFC))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*2; % Analizamos el espectro de potencias hasta 1 seg lugo del onset del freezing
    S = S_lowband_PFC(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T1(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum1 = mean(T1,1);
sem2 = std(T1,1)/sqrt(size(T1,1));
SEM(1,:) = powerspectrum1 + sem2;
SEM(2,:) = powerspectrum1 - sem2;
plot_vector(powerspectrum1,f_lowband_PFC,'l',SEM,'m');
xlabel(['Frequency (Hz)']); ylabel(['Log Power (a.u.)']); title(['PFC Low Freq Power Spectrum']);
clear S sem2 SEM t_positions_start t_positions_end paso i;
hold on

% Calculamos los momentos del espectrograma en los cuales hay movilidad y calculamos el espectro de potencias del primer segundo del comportamiento
for i = 1:length(fin_freezing)-1;
    paso = mean(unique(diff(t_lowband_PFC))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = randi((length(t_lowband_PFC)-(int64(1/paso))*2),1,1); % Calculamos tiempos random
    t_positions_end = t_positions_start + (int64(1/paso))*2; % Analizamos el espectro de potencias hasta 1 seg lugo del onset del freezing
    S = S_lowband_PFC(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T2(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end paso % Borramos las variables que no me sirven
end
powerspectrum2 = mean(T2,1);
sem2 = std(T2,1)/sqrt(size(T2,1));
SEM(1,:) = powerspectrum2 + sem2;
SEM(2,:) = powerspectrum2 - sem2;
plot_vector(powerspectrum2,f_lowband_PFC,'l',SEM,'g');
xlabel(['Frequency (Hz)']); ylabel(['Log Power (a.u.)']); 
clear S powerspectrum sem2 SEM t_positions_start t_positions_end paso i;

% Graficamos en el inset la cuantificación de un rango de potencias
freq1 = find(abs(f_lowband_PFC - 1) == min(abs(f_lowband_PFC - 1)));
freq2 = find(abs(f_lowband_PFC - 4) == min(abs(f_lowband_PFC - 4)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.68 .64 .2 .2])
box on

plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'm', 'MarkerFaceColor', 'm');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'g', 'MarkerFaceColor', 'g');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','m','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','g','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('1-4 Hz Mean Power', 'FontSize', 4);
Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'Freezing'; 'Random'})
set(gca,'FontSize',8);
hold on
[p] = ranksum(pwr1,pwr2);
if p >= 0.05;
    p_value_res = 'ns';
elseif p < 0.05 && p >= 0.01;
    p_value_res = '*';
elseif p < 0.01 && p >= 0.001 ;
    p_value_res = '**';
elseif p < 0.001 && p >= 0.0001  ;
    p_value_res = '***';
elseif p < 0.0001 && p >= 0.00001 ;
    p_value_res = '****';
else
    p_value_res = '*****';
end
text(1.5,60,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);

%% PFC Highband 
%Power Spectrum durante el primer segundo del freezing
% Este script requiere de correr primero el script "SpectrogramHighHighFreq.m"

cs1_color = [255 67 66]/255; % Seteo el color para el CS1
cs2_color = [70 171 215]/255; % Seteo el color para el CS2
freezing_color = [255 67 66]/255; % Seteo el color para el freezing
locomotion_color = [255 67 66]/255; % Seteo el color para locomotion

clear T1 T2;

% Calculamos los momentos del espectrograma en los cuales inicia el freezing y calculamos el espectro de potencias del primer segundo del comportamiento
for i = 1:length(inicio_freezing)-1;
    t_positions_start = find(abs(t_highband_PFC - inicio_freezing(i)) == min(abs(t_highband_PFC - inicio_freezing(i)))); % Buscamos los timestamps del espectrograma donde inicia el freezing
    paso = mean(unique(diff(t_highband_PFC))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*2; % Analizamos el espectro de potencias hasta 1 seg lugo del onset del freezing
    S = S_highband_PFC(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T1(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum1 = mean(T1,1);
sem2 = std(T1,1)/sqrt(size(T1,1));
SEM(1,:) = powerspectrum1 + sem2;
SEM(2,:) = powerspectrum1 - sem2;
plot_vector(powerspectrum1,f_highband_PFC,'l',SEM,'m');
xlabel(['Frequency (Hz)']); ylabel(['Power (a.u.)']); title(['PFC High Freq Power Spectrum']);
clear S sem2 SEM t_positions_start t_positions_end paso i;
hold on

% Calculamos los momentos del espectrograma en los cuales hay movilidad y calculamos el espectro de potencias del primer segundo del comportamiento
for i = 1:length(fin_freezing)-1;
    paso = mean(unique(diff(t_highband_PFC))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = randi((length(t_highband_PFC)-(int64(1/paso))*2),1,1); % Calculamos tiempos random
    t_positions_end = t_positions_start + (int64(1/paso))*2; % Analizamos el espectro de potencias hasta 1 seg lugo del onset del freezing
    S = S_highband_PFC(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T2(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end paso % Borramos las variables que no me sirven
end
powerspectrum2 = mean(T2,1);
sem2 = std(T2,1)/sqrt(size(T2,1));
SEM(1,:) = powerspectrum2 + sem2;
SEM(2,:) = powerspectrum2 - sem2;
plot_vector(powerspectrum2,f_highband_PFC,'l',SEM,'g');
xlabel(['Frequency (Hz)']); ylabel(['Log Power (a.u.)']); 
clear S powerspectrum sem2 SEM t_positions_start t_positions_end paso i;

% Graficamos en el inset la cuantificación de un rango de potencias
freq1 = find(abs(f_highband_PFC - 60) == min(abs(f_highband_PFC - 60)));
freq2 = find(abs(f_highband_PFC - 120) == min(abs(f_highband_PFC - 120)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.68 .64 .2 .2])
box on

plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'm', 'MarkerFaceColor', 'm');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'g', 'MarkerFaceColor', 'g');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','m','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','g','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('60-120 Hz Mean Power', 'FontSize', 4);
set(gca,'xtick',[1:2],'xticklabel',{'Freezing'; 'Random'})
set(gca,'FontSize',8);
hold on
[p] = ranksum(pwr1,pwr2);
if p >= 0.05;
    p_value_res = 'ns';
elseif p < 0.05 && p >= 0.01;
    p_value_res = '*';
elseif p < 0.01 && p >= 0.001 ;
    p_value_res = '**';
elseif p < 0.001 && p >= 0.0001  ;
    p_value_res = '***';
elseif p < 0.0001 && p >= 0.00001 ;
    p_value_res = '****';
else
    p_value_res = '*****';
end
text(1.5,40,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);