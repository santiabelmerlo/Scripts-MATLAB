function plot_boxplot_fz(T_CS1,T_CS2,T_CS3,region,paradigma,frecuencia)

% Graficamos en el inset la cuantificación de un rango de potencias
% Primer Inset
mean_CS1 = nanmedian(nanmedian(T_CS1,1));
mean_CS2 = nanmedian(nanmedian(T_CS2,1));
mean_CS3 = nanmedian(nanmedian(T_CS3,1));
sem_CS1 = nanmedian(nanmedian(abs(bsxfun(@minus, T_CS1', nanmedian(T_CS1'))))/sqrt(size(T_CS1,2)));
sem_CS2 = nanmedian(nanmedian(abs(bsxfun(@minus, T_CS2', nanmedian(T_CS2'))))/sqrt(size(T_CS2,2)));
sem_CS3 = nanmedian(nanmedian(abs(bsxfun(@minus, T_CS3', nanmedian(T_CS3'))))/sqrt(size(T_CS3,2)));

if strcmp(paradigma,'appetitive');
    cs1_color = [255 140 0]/255; % Seteo el color para el freezing a un tono de naranja
else
    cs1_color = [255 140 0]/255; % Seteo el color para el freezing a un tono de naranja
end
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
cs3_color = [255 255 255]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento

bar(1,mean_CS1,0.7,'FaceColor',cs3_color,'FaceAlpha',0.3);
hold on
errorbar(1, mean_CS1, sem_CS1, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
bar(2,mean_CS2,0.7,'FaceColor',cs1_color,'FaceAlpha',0.3);
hold on
errorbar(2, mean_CS2, sem_CS2, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
bar(3,mean_CS3,0.7,'FaceColor',cs2_color,'FaceAlpha',0.3);
hold on
errorbar(3, mean_CS3, sem_CS3, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars

xlim([0.5 3.5]);

ylabel('Power (z-score)','FontSize', 10);

% Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:3],'xticklabel',{'Pre-Fz'; 'Fz'; 'no-Fz'})
set(gca,'FontSize',10);

hold on
[p] = ranksum(nanmedian(T_CS1,1),nanmedian(T_CS2,1));
if p >= 0.05;
    p_value_res = 'ns';
elseif p < 0.05 && p >= 0.01;
    p_value_res = '*';
else
    p_value_res = '**';
end

ylim([min([mean_CS2-sem_CS2,mean_CS3-sem_CS3])-0.1 max([mean_CS2-sem_CS2,mean_CS3-sem_CS3])+0.1]);
text(1.5,0.4,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',14);

[p] = ranksum(nanmedian(T_CS2,1),nanmedian(T_CS3,1));
if p >= 0.05;
    p_value_res = 'ns';
elseif p < 0.05 && p >= 0.01;
    p_value_res = '*';
else
    p_value_res = '**';
end
text(2.5,0.4,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',14);
ylim([min([mean_CS2-sem_CS2,mean_CS3-sem_CS3])-0.1 max([mean_CS2-sem_CS2,mean_CS3-sem_CS3])+0.1]);

set(gca, 'YTick', [-1:0.2:1]);
hold on
title(sprintf('%s %s', region, frecuencia));
hold off
return