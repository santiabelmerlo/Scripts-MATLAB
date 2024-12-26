function plot_box(T_CS1,T_CS2,region,frecuencia,paradigma,add)

% Graficamos en el inset la cuantificaci�n de un rango de potencias
% Primer Inset
mean_CS1 = nanmedian(T_CS1);
mean_CS2 = nanmedian(T_CS2);
sem_CS1 = nanmedian((abs(T_CS1) - nanmedian(T_CS1)))/sqrt(size(T_CS1,1));
sem_CS2 = nanmedian((abs(T_CS2) - nanmedian(T_CS2)))/sqrt(size(T_CS2,1));

if strcmp(paradigma,'appetitive');
    cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
else
    cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
end
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento

% bar(1,mean_CS1,0.7,'FaceColor',cs1_color,'FaceAlpha',0.3);
% hold on
% errorbar(1, mean_CS1, sem_CS1, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
% bar(2,mean_CS2,0.7,'FaceColor',cs2_color,'FaceAlpha',0.3);
% hold on
% errorbar(2, mean_CS2, sem_CS2, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Crear una matriz de datos combinados
data = [T_CS1; T_CS2];
% Crear un vector de grupos
group = [ones(size(T_CS1)); 2 * ones(size(T_CS2))];
% Crear el boxplot
boxplot(data, group, 'Colors', [cs1_color; cs2_color], 'Widths', 0.7,'Symbol', '');
% Ajustar el color de los boxplots
h = findobj(gca, 'Tag', 'Box');
for j = 1:length(h)
    if mod(j, 2) == 1
        patch(get(h(j), 'XData'), get(h(j), 'YData'), cs2_color, 'FaceAlpha', 0.3);
    else
        patch(get(h(j), 'XData'), get(h(j), 'YData'), cs1_color, 'FaceAlpha', 0.3);
    end
end

% Ajustar el gr�fico
set(gca, 'XTick', [1, 2], 'XTickLabel', {'CS+', 'CS-'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xlim([0.5 2.5]);
ylabel('Power (Z-score)','FontSize', 10);

% Words = {'word_one'; 'word_two'; 'word_three'};
% set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
set(gca,'FontSize',10);

hold on 
% [p] = ranksum(T_CS1,T_CS2);
[p] = signrank(T_CS1,T_CS2);

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

ylim1 = max(mean_CS1,mean_CS2);
ylim2 = min(mean_CS1,mean_CS2);

if ylim1 < 0;
    ylim1 = 0;
else 
    ylim1 = ylim1 + 0.2;
end

if ylim2 > 0;
    ylim2 = 0;
else 
    ylim2 = ylim2 - 0.2;
end

ylim([-2 3]);
text(1.5,2.8,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10);

hold on
title(sprintf('%s - %s', frecuencia, add), 'FontSize', 10);
hold off

disp(p);
return