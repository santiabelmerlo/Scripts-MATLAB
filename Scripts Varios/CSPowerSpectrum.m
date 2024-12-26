%% BLA Lowband
% Power Spectrum durante el CS+ vs CS-
% Este script requiere de correr primero el script "SpectrogramHighLowFreq.m"

clear T1 T2;

% Calculamos los momentos del espectrograma en los cuales inicia el CS+ y calculamos el espectro de potencias de ese segmento
for i = 1:length(TTL_CS1_inicio);
    t_positions_start = find(abs(t_lowband_BLA - TTL_CS1_inicio(i)) == min(abs(t_lowband_BLA - TTL_CS1_inicio(i)))); % Buscamos los timestamps del espectrograma donde inicia el CS+
    paso = mean(unique(diff(t_lowband_BLA))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*60; % Analizamos el espectro de potencias durante los 60 seg
    S = S_lowband_BLA(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T1(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum1 = mean(T1,1);
sem2 = std(T1,1)/sqrt(size(T1,1));
SEM(1,:) = powerspectrum1 + sem2;
SEM(2,:) = powerspectrum1 - sem2;
plot_vector(powerspectrum1,f_lowband_BLA,'l',SEM,'r');
xlabel(['Frequency (Hz)']); ylabel(['Power (a.u.,10*log10)']); title(['BLA Low Freq Power Spectrum']);
clear S sem2 SEM t_positions_start t_positions_end paso i;
hold on

% Calculamos los momentos del espectrograma en los cuales inicia el CS- y calculamos el espectro de potencias de ese segmento
for i = 1:length(TTL_CS2_inicio);
    t_positions_start = find(abs(t_lowband_BLA - TTL_CS2_inicio(i)) == min(abs(t_lowband_BLA - TTL_CS2_inicio(i)))); % Buscamos los timestamps del espectrograma donde inicia el CS-
    paso = mean(unique(diff(t_lowband_BLA))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*60; % Analizamos el espectro de potencias durante los 60 seg
    S = S_lowband_BLA(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T2(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum2 = mean(T2,1);
sem2 = std(T2,1)/sqrt(size(T2,1));
SEM(1,:) = powerspectrum2 + sem2;
SEM(2,:) = powerspectrum2 - sem2;
plot_vector(powerspectrum2,f_lowband_BLA,'l',SEM,'b');
xlabel(['Frequency (Hz)']); ylabel(['Log Power (a.u.)']); 
clear S powerspectrum sem2 SEM t_positions_start t_positions_end paso i;

% Graficamos en el inset la cuantificación de un rango de potencias
% Primer Inset
freq1 = find(abs(f_lowband_BLA - 2) == min(abs(f_lowband_BLA - 2)));
freq2 = find(abs(f_lowband_BLA - 6) == min(abs(f_lowband_BLA - 6)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.72 .68 .15 .15])
box on
plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'r', 'MarkerFaceColor', 'r');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'b', 'MarkerFaceColor', 'b');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','r','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','b','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
ylim([30 50]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('4 Hz Mean Power', 'FontSize', 4);
Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
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
text(1.5,50,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);
hold on

% Segundo Inset
freq1 = find(abs(f_lowband_BLA - 6) == min(abs(f_lowband_BLA - 6)));
freq2 = find(abs(f_lowband_BLA - 12) == min(abs(f_lowband_BLA - 12)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.72 .42 .15 .15])
box on
plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'r', 'MarkerFaceColor', 'r');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'b', 'MarkerFaceColor', 'b');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','r','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','b','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
ylim([30 40]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('8 Hz Mean Power', 'FontSize', 4);
Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
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
% Power Spectrum durante el CS+ vs CS-
% Este script requiere de correr primero el script "SpectrogramHighLowFreq.m"

clear T1 T2;

% Calculamos los momentos del espectrograma en los cuales inicia el CS+ y calculamos el espectro de potencias de ese segmento
for i = 1:length(TTL_CS1_inicio);
    t_positions_start = find(abs(t_lowband_PFC - TTL_CS1_inicio(i)) == min(abs(t_lowband_PFC - TTL_CS1_inicio(i)))); % Buscamos los timestamps del espectrograma donde inicia el CS+
    paso = mean(unique(diff(t_lowband_PFC))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*60; % Analizamos el espectro de potencias durante los 60 seg
    S = S_lowband_PFC(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T1(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum1 = mean(T1,1);
sem2 = std(T1,1)/sqrt(size(T1,1));
SEM(1,:) = powerspectrum1 + sem2;
SEM(2,:) = powerspectrum1 - sem2;
plot_vector(powerspectrum1,f_lowband_PFC,'l',SEM,'r');
xlabel(['Frequency (Hz)']); ylabel(['Power (a.u.,10*log10)']); title(['PFC Low Freq Power Spectrum']);
clear S sem2 SEM t_positions_start t_positions_end paso i;
hold on

% Calculamos los momentos del espectrograma en los cuales inicia el CS- y calculamos el espectro de potencias de ese segmento
for i = 1:length(TTL_CS2_inicio);
    t_positions_start = find(abs(t_lowband_PFC - TTL_CS2_inicio(i)) == min(abs(t_lowband_PFC - TTL_CS2_inicio(i)))); % Buscamos los timestamps del espectrograma donde inicia el CS-
    paso = mean(unique(diff(t_lowband_PFC))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*60; % Analizamos el espectro de potencias durante los 60 seg
    S = S_lowband_PFC(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T2(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum2 = mean(T2,1);
sem2 = std(T2,1)/sqrt(size(T2,1));
SEM(1,:) = powerspectrum2 + sem2;
SEM(2,:) = powerspectrum2 - sem2;
plot_vector(powerspectrum2,f_lowband_PFC,'l',SEM,'b');
xlabel(['Frequency (Hz)']); ylabel(['Log Power (a.u.)']); 
clear S powerspectrum sem2 SEM t_positions_start t_positions_end paso i;

% Graficamos en el inset la cuantificación de un rango de potencias
% Primer Inset
freq1 = find(abs(f_lowband_PFC - 2) == min(abs(f_lowband_PFC - 2)));
freq2 = find(abs(f_lowband_PFC - 6) == min(abs(f_lowband_PFC - 6)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.72 .68 .15 .15])
box on
plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'r', 'MarkerFaceColor', 'r');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'b', 'MarkerFaceColor', 'b');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','r','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','b','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
ylim([30 50]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('4 Hz Mean Power', 'FontSize', 4);
Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
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
text(1.5,50,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);
hold on

% Segundo Inset
freq1 = find(abs(f_lowband_PFC - 6) == min(abs(f_lowband_PFC - 6)));
freq2 = find(abs(f_lowband_PFC - 12) == min(abs(f_lowband_PFC - 12)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.72 .42 .15 .15])
box on
plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'r', 'MarkerFaceColor', 'r');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'b', 'MarkerFaceColor', 'b');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','r','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','b','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
ylim([30 40]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('8 Hz Mean Power', 'FontSize', 4);
Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
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

%% BLA highband
% Power Spectrum durante el CS+ vs CS-
% Este script requiere de correr primero el script "SpectrogramHighHighFreq.m"

clear T1 T2;

% Calculamos los momentos del espectrograma en los cuales inicia el CS+ y calculamos el espectro de potencias de ese segmento
for i = 1:length(TTL_CS1_inicio);
    t_positions_start = find(abs(t_highband_BLA - TTL_CS1_inicio(i)) == min(abs(t_highband_BLA - TTL_CS1_inicio(i)))); % Buscamos los timestamps del espectrograma donde inicia el CS+
    paso = mean(unique(diff(t_highband_BLA))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*60; % Analizamos el espectro de potencias durante los 60 seg
    S = S_highband_BLA(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T1(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum1 = mean(T1,1);
sem2 = std(T1,1)/sqrt(size(T1,1));
SEM(1,:) = powerspectrum1 + sem2;
SEM(2,:) = powerspectrum1 - sem2;
plot_vector(powerspectrum1,f_highband_BLA,'l',SEM,'r');
xlabel(['Frequency (Hz)']); ylabel(['Power (a.u.,10*log10)']); title(['BLA High Freq Power Spectrum']);
clear S sem2 SEM t_positions_start t_positions_end paso i;
hold on

% Calculamos los momentos del espectrograma en los cuales inicia el CS- y calculamos el espectro de potencias de ese segmento
for i = 1:length(TTL_CS2_inicio);
    t_positions_start = find(abs(t_highband_BLA - TTL_CS2_inicio(i)) == min(abs(t_highband_BLA - TTL_CS2_inicio(i)))); % Buscamos los timestamps del espectrograma donde inicia el CS-
    paso = mean(unique(diff(t_highband_BLA))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*60; % Analizamos el espectro de potencias durante los 60 seg
    S = S_highband_BLA(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T2(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum2 = mean(T2,1);
sem2 = std(T2,1)/sqrt(size(T2,1));
SEM(1,:) = powerspectrum2 + sem2;
SEM(2,:) = powerspectrum2 - sem2;
plot_vector(powerspectrum2,f_highband_BLA,'l',SEM,'b');
xlabel(['Frequency (Hz)']); ylabel(['Log Power (a.u.)']); 
clear S powerspectrum sem2 SEM t_positions_start t_positions_end paso i;

% Graficamos en el inset la cuantificación de un rango de potencias
% Primer Inset
freq1 = find(abs(f_highband_BLA - 20) == min(abs(f_highband_BLA - 20)));
freq2 = find(abs(f_highband_BLA - 60) == min(abs(f_highband_BLA - 60)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.72 .68 .15 .15])
box on
plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'r', 'MarkerFaceColor', 'r');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'b', 'MarkerFaceColor', 'b');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','r','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','b','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
% ylim([30 50]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('20-60 Hz Mean Power', 'FontSize', 4);
Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
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
hold on

% Segundo Inset
freq1 = find(abs(f_highband_BLA - 60) == min(abs(f_highband_BLA - 60)));
freq2 = find(abs(f_highband_BLA - 120) == min(abs(f_highband_BLA - 120)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.72 .42 .15 .15])
box on
plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'r', 'MarkerFaceColor', 'r');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'b', 'MarkerFaceColor', 'b');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','r','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','b','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
% ylim([30 40]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('60-120 Hz Mean Power', 'FontSize', 4);
Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
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

%% PFC highband
% Power Spectrum durante el CS+ vs CS-
% Este script requiere de correr primero el script "SpectrogramHighHighFreq.m"

clear T1 T2;

% Calculamos los momentos del espectrograma en los cuales inicia el CS+ y calculamos el espectro de potencias de ese segmento
for i = 1:length(TTL_CS1_inicio);
    t_positions_start = find(abs(t_highband_PFC - TTL_CS1_inicio(i)) == min(abs(t_highband_PFC - TTL_CS1_inicio(i)))); % Buscamos los timestamps del espectrograma donde inicia el CS+
    paso = mean(unique(diff(t_highband_PFC))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*60; % Analizamos el espectro de potencias durante los 60 seg
    S = S_highband_PFC(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T1(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum1 = mean(T1,1);
sem2 = std(T1,1)/sqrt(size(T1,1));
SEM(1,:) = powerspectrum1 + sem2;
SEM(2,:) = powerspectrum1 - sem2;
plot_vector(powerspectrum1,f_highband_PFC,'l',SEM,'r');
xlabel(['Frequency (Hz)']); ylabel(['Power (a.u.,10*log10)']); title(['PFC High Freq Power Spectrum']);
clear S sem2 SEM t_positions_start t_positions_end paso i;
hold on

% Calculamos los momentos del espectrograma en los cuales inicia el CS- y calculamos el espectro de potencias de ese segmento
for i = 1:length(TTL_CS2_inicio);
    t_positions_start = find(abs(t_highband_PFC - TTL_CS2_inicio(i)) == min(abs(t_highband_PFC - TTL_CS2_inicio(i)))); % Buscamos los timestamps del espectrograma donde inicia el CS-
    paso = mean(unique(diff(t_highband_PFC))); % Calculamos el paso temporal que tiene el espectrograma
    t_positions_start = int64(t_positions_start); % Pasamos a enteros
    t_positions_end = t_positions_start + (int64(1/paso))*60; % Analizamos el espectro de potencias durante los 60 seg
    S = S_highband_PFC(t_positions_start:t_positions_end,:); % Extraemos el espectrograma de ese pedazo de tiempo
    T2(i,:) = mean(S,1); % Calculamos el espectro de potencias como la media de ese espectrograma
    clear S step t_positions_start t_positions_end % Borramos las variables que no me sirven
end
powerspectrum2 = mean(T2,1);
sem2 = std(T2,1)/sqrt(size(T2,1));
SEM(1,:) = powerspectrum2 + sem2;
SEM(2,:) = powerspectrum2 - sem2;
plot_vector(powerspectrum2,f_highband_PFC,'l',SEM,'b');
xlabel(['Frequency (Hz)']); ylabel(['Log Power (a.u.)']); 
clear S powerspectrum sem2 SEM t_positions_start t_positions_end paso i;

% Graficamos en el inset la cuantificación de un rango de potencias
% Primer Inset
freq1 = find(abs(f_highband_PFC - 20) == min(abs(f_highband_PFC - 20)));
freq2 = find(abs(f_highband_PFC - 60) == min(abs(f_highband_PFC - 60)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.72 .68 .15 .15])
box on
plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'r', 'MarkerFaceColor', 'r');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'b', 'MarkerFaceColor', 'b');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','r','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','b','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
% ylim([30 50]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('20-60 Hz Mean Power', 'FontSize', 4);
Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
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
hold on

% Segundo Inset
freq1 = find(abs(f_highband_PFC - 60) == min(abs(f_highband_PFC - 60)));
freq2 = find(abs(f_highband_PFC - 120) == min(abs(f_highband_PFC - 120)));
pwr1 = mean(T1(:,freq1:freq2),2); pwr1_mean = mean(pwr1); pwr1_sem = std(pwr1)/sqrt(length(pwr1));
pwr2 = mean(T2(:,freq1:freq2),2); pwr2_mean = mean(pwr2); pwr2_sem = std(pwr2)/sqrt(length(pwr2));
axes('Position',[.72 .42 .15 .15])
box on
plot(1,10*log10(pwr1),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'r', 'MarkerFaceColor', 'r');
hold on
plot(2,10*log10(pwr2),'MarkerSize',2,'Marker','o','LineStyle','none',...)
    'Color', 'b', 'MarkerFaceColor', 'b');
hold on
bar(1,10*log10(pwr1_mean),0.4,'FaceColor','r','FaceAlpha',0.3);
hold on 
bar(2,10*log10(pwr2_mean),0.4,'FaceColor','b','FaceAlpha',0.3);
hold on
xlim([0.5 2.5]);
% ylim([30 40]);
ylabel('Mean Power (a.u.)','FontSize', 4);
title('60-120 Hz Mean Power', 'FontSize', 4);
Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
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