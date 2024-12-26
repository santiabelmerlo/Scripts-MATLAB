function plot_boxplot_pre(T_CS1,T_CS2,region,frecuencia,timelegend,tmin,tmax)

% Graficamos en el inset la cuantificación de un rango de potencias
% Primer Inset
mean_CS1 = mean(mean(T_CS1(tmin:tmax,:),1));
mean_CS2 = mean(mean(T_CS2(tmin:tmax,:),1));
sem_CS1 = std(mean(T_CS1(tmin:tmax,:),1)) / sqrt(length(mean(T_CS1(tmin:tmax,:),1)));
sem_CS2 = std(mean(T_CS2(tmin:tmax,:),1)) / sqrt(length(mean(T_CS2(tmin:tmax,:),1)));

mean_preCS1 = mean(mean(T_CS1(1:50,:),1));
mean_preCS2 = mean(mean(T_CS2(1:50,:),1));
sem_preCS1 = std(mean(T_CS1(1:50,:),1)) / sqrt(length(mean(T_CS1(1:50,:),1)));
sem_preCS2 = std(mean(T_CS2(1:50,:),1)) / sqrt(length(mean(T_CS2(1:50,:),1)));

cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento

% Ploteamos pre CS+
bar(1,mean_preCS1,0.7,'FaceColor', [1 1 1], 'EdgeColor', cs1_color,'FaceAlpha',0.3);
hold on
errorbar(1, mean_preCS1, sem_preCS1, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
% Ploteamos CS+
bar(2,mean_CS1,0.7,'FaceColor',cs1_color,'FaceAlpha',0.3);
hold on
errorbar(2, mean_CS1, sem_CS1, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
% Ploteamos pre CS-
bar(3,mean_preCS2,0.7,'FaceColor',[1 1 1],'EdgeColor', cs2_color,'FaceAlpha',0.3);
hold on
errorbar(3, mean_preCS2, sem_preCS2, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
% Ploetamos CS-
bar(4,mean_CS2,0.7,'FaceColor',cs2_color,'FaceAlpha',0.3);
hold on
errorbar(4, mean_CS2, sem_CS2, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars


xlim([0.5 4.5]);
ylabel('Power (Z-score)','FontSize', 7);

set(gca,'xtick',[1:4],'xticklabel',{'preCS+'; 'CS+';'preCS-'; 'CS-'})
set(gca,'FontSize',6);

hold on
[p] = ranksum(mean(T_CS1(1:50,:),1),mean(T_CS1(tmin:tmax,:),1));
p = p*2; % Bonferroni correction
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

if mean_CS1 > 1 || mean_CS1 < -1 || mean_preCS1 > 1 || mean_preCS1 < -1 || mean_CS2 > 1 || mean_CS2 < -1 || mean_preCS2 > 1 || mean_preCS2 < -1
    ylim([-2 2]);
    text(1.5,1.95,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10);
elseif mean_CS1 > 2 || mean_CS1 < -2 || mean_preCS1 > 2 || mean_preCS1 < -2 || mean_CS2 > 2 || mean_CS2 < -2 || mean_preCS2 > 2 || mean_preCS2 < -2
    ylim([-3 3]);
    text(1.5,2.95,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10);
else
    ylim([-1 1]);
    text(1.5,0.95,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10);
end

[p] = ranksum(mean(T_CS2(1:50,:),1),mean(T_CS2(tmin:tmax,:),1));
p = p*2; % Bonferroni correction
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

if mean_CS1 > 1 || mean_CS1 < -1 || mean_preCS1 > 1 || mean_preCS1 < -1 || mean_CS2 > 1 || mean_CS2 < -1 || mean_preCS2 > 1 || mean_preCS2 < -1
    ylim([-2 2]);
    text(3.5,1.95,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10);
elseif mean_CS1 > 2 || mean_CS1 < -2 || mean_preCS1 > 2 || mean_preCS1 < -2 || mean_CS2 > 2 || mean_CS2 < -2 || mean_preCS2 > 2 || mean_preCS2 < -2
    ylim([-3 3]);
    text(1.5,2.95,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10);
else
    ylim([-1 1]);
    text(3.5,0.95,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10);
end

hold on
title(strcat(frecuencia, timelegend), 'FontSize', 6);
set(gca,'FontSize',6);
hold off
return