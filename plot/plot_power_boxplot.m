function plot_power_boxplot(T_CS1,T_CS2,region,paradigma)

% Graficamos en el inset la cuantificación de un rango de potencias
% Primer Inset
mean_CS1 = nanmedian(nanmedian(T_CS1,1));
mean_CS2 = nanmedian(nanmedian(T_CS2,1));
sem_CS1 = nanmedian(nanmedian(abs(bsxfun(@minus, T_CS1', nanmedian(T_CS1'))))/sqrt(size(T_CS1,2)));
sem_CS2 = nanmedian(nanmedian(abs(bsxfun(@minus, T_CS2', nanmedian(T_CS2'))))/sqrt(size(T_CS2,2)));

if strcmp(paradigma,'appetitive');
    cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
else
    cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
end
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento

bar(1,mean_CS1,0.7,'FaceColor',cs1_color,'FaceAlpha',0.3);
hold on
errorbar(1, mean_CS1, sem_CS1, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
bar(2,mean_CS2,0.7,'FaceColor',cs2_color,'FaceAlpha',0.3);
hold on
errorbar(2, mean_CS2, sem_CS2, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
xlim([0.5 2.5]);
ylabel('Normalized Power Envelope','FontSize', 10);

% Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
set(gca,'FontSize',10);

hold on
[p] = ranksum(nanmedian(T_CS1,1),nanmedian(T_CS2,1));
% p = p*25;
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

ylim([min([mean_CS1-sem_CS1,mean_CS2-sem_CS2])-0.1 max([mean_CS1-sem_CS1,mean_CS2-sem_CS2])+0.1]);
text(1.5,max([mean_CS1-sem_CS1,mean_CS2-sem_CS2])+0.05,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',18);

hold on
title(strcat(region, ' Hole Session Norm. Power Envelope'), 'FontSize', 11);
hold off
return