%% Grafico dotplot + bars
% Actualizado el 15/12/2022

% Este script requiere correr OUTPUT_to_Rat1.m
% Cargamos los datos parándonos en la carpeta de R00_Analisis

clc
clear all
[~,name,~] = fileparts(pwd); name = name(1:3);
load(strcat(name,'_Rat1.mat'))
[~,name,~] = fileparts(pwd); name = name(1:3);

datos = double(Rat1.preCS.tpuerta); 
% figurename = strcat(name,'_duringCS_tpuerta.png');

which = 't';% subplot(1,2,1);

% Seteamos algunos parámetros
n_tr = 5;           % Número de días de entrenamiento
n_ext = 2;          % Número de días de extinción.
n_ts = 1;           % Número de días de testeo.

% Seteamos el texto del título
titletext = 'Puerta durante el tono';

%-----------------------------------------------------------------------------------%
% Labels para el eje x.
if n_tr > 0;
    for i = 1:n_tr;
        xlabels(i,:) = strcat('TR',int2str(i));
    end
end
if n_ext > 0;
    for i = 1:n_ext;
        xlabels(i+n_tr,:) = strcat('EX',int2str(i));
    end
end
if n_ts > 0;
    for i = 1:n_ts;
        xlabels(i+n_tr+n_ext,:) = strcat('TS',int2str(i));
    end
end

% Labels para el eje y:
if which == 't';
    ylab = 'Tiempo acumulado (ms)'; limsupy = 10000;
elseif which == 'n';
    ylab = '# de nosepokes por trial'; limsupy = 30;
elseif which == 'l';
    ylab = 'Latencia al primer nosepoke (ms)'; limsupy = 10000;
elseif which == 'p';
    ylab = 'Porcentaje de trials con nosepokes (%)'; limsupy = 100;
end

% Ploteamos la figura

if which == 't' | which == 'n' | which == 'l';
    dotseparation = 10;                                                 % Separación de puntos. Valor entre 0 y 100
    pre_color = [190 190 190]/255; % Color de los puntos para el CS1 o CS+
    cs1_color = [0 128 0]/255; % Color de los puntos para el CS1 o CS+
    cs2_color = [96 96 96]/255; % Color de los puntos para el CS2 o CS-
    dmean = nanmean(datos);                                                    % Mean
    stderror= nanstd(datos)/sqrt(length(datos));
    xt = [1:size(datos,2)];                                                         % X-Ticks
    xtd = repmat(xt, size(datos,1), 1);                                  % X-Ticks For Data
    for i = 1:size(xtd,1)
        for j = 1:size(xtd,2)
        xtdd(i,j) = xtd(i,j) + (randi([-dotseparation,dotseparation])/100);
        end
    end
    figure();
    p_cs1_dots = plot(xtdd(:,(1:2:size(datos,2))), datos(:,(1:2:size(datos,2))),'MarkerSize',2,'Marker','o','LineStyle','none',...)
         'Color', cs1_color, 'MarkerFaceColor', cs1_color);
    hold on 
    p_cs2_dots = plot(xtdd(:,(2:2:size(datos,2))), datos(:,(2:2:size(datos,2))),'MarkerSize',2,'Marker','o','LineStyle','none',...
        'Color', cs2_color, 'MarkerFaceColor', cs2_color);
    p_cs1_bar = bar(xt(:,(1:2:size(datos,2))),dmean(:,(1:2:size(datos,2))),0.4,'FaceColor',cs1_color);
        p_cs1_bar.FaceAlpha = 0.3;
    %     p_cs1_errbar = errorbarxt(:,(1:2:size(datos,2))),err1low,err1high);  
    p_cs2_bar = bar(xt(:,(2:2:size(datos,2))),dmean(:,(2:2:size(datos,2))),0.4,'FaceColor',cs2_color);
        p_cs2_bar.FaceAlpha = 0.3;
    hold on
    e = errorbar(xt,dmean,stderror); e.Color = 'black'; e.LineStyle = 'none'; 
    hold off
    xlim([0 (size(datos,2)+1)]);
    ylim([0 limsupy]);
    set(gca, 'XTick', xt, 'XTickLabel', {'CS+','CS-'});
    ylabel(ylab,'FontSize', 8);
    title(titletext, 'FontSize', 8);
    set(gca,'FontSize',8);

    % Hacemos la estadística: ttest
    [p] = ranksum(datos(:,3),datos(:,4));
    j = 1;
    for i = 1:2:(size(datos,2)-1);
        [p] = ranksum(datos(:,i),datos(:,i+1));
%         p = p * (size(datos,2)/2); % Correjimos por múltiples comparaciones
        p_value(j) = p;
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
        text((i+0.5),limsupy,p_value_res,...
            'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);
        j = j + 1;  
    end
end

if which == 'p';
    figure();
    cs1_color = [0 128 0]/255; % Color de los puntos para el CS1 o CS+
    cs2_color = [96 96 96]/255; % Color de los puntos para el CS2 o CS-
    p_cs1_bar = bar((1:2:size(datos,2)),datos(1:2:size(datos,2)),0.4,'FaceColor',cs1_color);
    hold on
    p_cs2_bar = bar((2:2:size(datos,2)),datos(2:2:size(datos,2)),0.4,'FaceColor',cs2_color);
    hold on
    ax = gca;
    ax.XAxis.TickValues = (1:1:size(datos,2));
    e = errorbar((1:size(datos,2)),datos,repelem(0,size(datos,2))); e.Color = 'black'; e.LineStyle = 'none';
    xlim([0 (size(datos,2)+1)]);
    ylim([0 limsupy]);
    set(gca,'XTickLabel', {'CS+','CS-'});
    ylabel(ylab,'FontSize', 8);
    title(titletext, 'FontSize', 8);
    set(gca,'FontSize',8);
    
    % Hacemos la estadística: Chi-squared
    j = 1;
    for i = 1:2:(size(datos,2)-1);
        
        a = datos(i); n1 = round(a*0.6); N1 = 60;
        b = datos(i+1); n2 = round(b*0.6); N2 = 60;
        x1 = [repmat('a',N1,1); repmat('b',N2,1)];
        x2 = [repmat(1,n1,1); repmat(2,N1-n1,1); repmat(1,n2,1); repmat(2,N2-n2,1)];
        [tbl,chi2stat,pval] = crosstab(x1,x2);
        
%         pval = pval * (size(datos,2)/2); % Correjimos por múltiples comparaciones
        p_value(j) = pval;
        
        if pval >= 0.05;
            p_value_res = 'ns';
        elseif pval < 0.05 && pval >= 0.01;
            p_value_res = '*';
        elseif pval < 0.01 && pval >= 0.001;
            p_value_res = '**';        
        elseif pval < 0.001 && pval >= 0.0001;
            p_value_res = '***';
        elseif pval < 0.0001 && pval >= 0.00001;
            p_value_res = '****';
        else
            p_value_res = '*****';
        end
        text((i+0.5),limsupy,p_value_res,...
            'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);
        j = j + 1;  
    end
end

% Colocamos los xlabels de la sesión correspondiente
m = 0.167;
annotation('textbox', [m, 0.05, 0.08, 0], 'string', 'TR1');
annotation('textbox', [(m+(0.103*1)), 0.05, 0.08, 0], 'string', 'TR2');
annotation('textbox', [(m+(0.103*2)), 0.05, 0.08, 0], 'string', 'TR3');
annotation('textbox', [(m+(0.103*3)), 0.05, 0.08, 0], 'string', 'TR4');
annotation('textbox', [(m+(0.103*4)), 0.05, 0.08, 0], 'string', 'TR5');
annotation('textbox', [(m+(0.103*5)), 0.05, 0.08, 0], 'string', 'EXT1');
annotation('textbox', [(m+(0.103*6)), 0.05, 0.08, 0], 'string', 'EXT2');

% Salvamos la figura
% saveas(gcf,figurename);

%% Guardamos el plot como .png
saveas(gcf,'duringCS_tpuerta.png')

%% Ploteamos la curva de aprendizaje del día. Trial a trial.
Day = 2;
plot(datos(:,((Day*2)-1)),'Color',([255 67 66]/255));
hold on
plot(datos(:,(Day*2)),'Color',([70 171 215]/255));
ylim([0 10000]);
ylabel(ylab,'FontSize', 8);
xlab = 'Trial #';
xlabel(xlab,'FontSize', 8)
title(strcat('Day',num2str(Day)),'FontSize', 8)
set(gca,'FontSize',8);

%%
% Analizar probabilidad de entrar a la puerta pre vs during CS.

% Quitar los 500 ms del análisis de tiempo acumulado during CS.

% Mejorar el script de cálculo de # de nosepokes para aquellos casos donde
% se corta el haz muy rápido varias veces.

% Hacer un histograma centrado en el inicio del tono o en el inicio del US
% con el tiempo acumulado o con el numero de nosepokes. 

% 

%% Genero datos para Pre CS vs During CS.
clear all;
clear datos;
load('Rat1.mat')
datos(:,1) = Rat1.preCS.tpuerta(:,1)/50;
datos(:,2) = Rat1.duringCS.tpuerta(:,1)/100;
datos(:,3) = Rat1.preCS.tpuerta(:,3)/50;
datos(:,4) = Rat1.duringCS.tpuerta(:,3)/100;
datos(:,5) = Rat1.preCS.tpuerta(:,5)/50;
datos(:,6) = Rat1.duringCS.tpuerta(:,5)/100;
% datos(:,7) = Rat1.preCS.tpuerta(:,7)/50;
% datos(:,8) = Rat1.duringCS.tpuerta(:,7)/100;
% datos(:,9) = Rat1.preCS.tpuerta(:,9)/50;
% datos(:,10) = Rat1.duringCS.tpuerta(:,9)/100;
% datos(:,11) = Rat1.preCS.tpuerta(:,11)/50;
% datos(:,12) = Rat1.duringCS.tpuerta(:,11)/100;
% datos(:,13) = Rat1.preCS.tpuerta(:,13)/50;
% datos(:,14) = Rat1.duringCS.tpuerta(:,13)/100;

%% Calculamos la curva de aprendizaje en bines de 10 CSs para DuringCS_tpuerta
data(1,:) = mean(datos(1:10,:));
data(2,:) = mean(datos(11:20,:));
data(3,:) = mean(datos(21:30,:));
data(4,:) = mean(datos(31:40,:));
data(5,:) = mean(datos(41:50,:));
data(6,:) = mean(datos(51:60,:));

%% Ploteamos la curva de aprendizaje del día. Trial a trial.

% subplot(1,7,7);

x = [10,20,30,40,50,60];
ylab = 'Tiempo acumulado (ms)'; limsupy = 10000;
plot(x, data(:,13),'Color',([255 67 66]/255),'MarkerSize',6,'Marker','o');
hold on
plot(x, data(:,14),'Color',([70 171 215]/255),'MarkerSize',6,'Marker','o');
ylim([0 6000]);
xlim([0 70]);
ylabel(ylab,'FontSize', 8);
set(gca,'FontSize',8);

% Salvamos la figura
saveas(gcf,'duringCS_tpuerta_curve.png')

%% Hacemos estadística de los primeros 30 CS del TR1, los últimos 30 CS del TR6, los primeros 30 CS del día EXT1
% los últimos 30 CS del día EXT1 y los primeros 30 CS del EXT2

data(:,1:2) = datos(1:30,1:2);
data(:,3:4) = datos(31:60,9:10);
data(:,5:6) = datos(1:30,11:12);
data(:,7:8) = datos(31:60,11:12);
data(:,9:10) = datos(1:30,13:14);
datos = data;
clearvars -except datos

%% Colocamos los xlabels de la sesión correspondiente
m = 0.186;
annotation('textbox', [m, 0.05, 0.095, 0], 'string', 'E-TR-1');
annotation('textbox', [(m+(0.141*1)), 0.05, 0.095, 0], 'string', 'L-TR-5');
annotation('textbox', [(m+(0.141*2)), 0.05, 0.095, 0], 'string', 'E-EXT1');
annotation('textbox', [(m+(0.141*3)), 0.05, 0.095, 0], 'string', 'L-EXT1');
annotation('textbox', [(m+(0.141*4)), 0.05, 0.095, 0], 'string', 'E-EXT2');

%%
data = mean(Rat1.duringCS.tpuerta,1)';