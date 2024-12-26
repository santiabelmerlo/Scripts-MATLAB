function plot_lags(lag1,lag2,color)

mean_lag1 = nanmean(lag1);
mean_lag2 = nanmean(lag2);
sem_lag1 = nanstd(lag1) / sqrt(length(lag1));
sem_lag2 = nanstd(lag2) / sqrt(length(lag2));

if strcmp(color,'CS')
    fz_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
    nofz_color = [96 96 96]/255; % Seteo el color para el CS-
elseif strcmp(color,'fz')
    fz_color = [255 140 0]/255; % Seteo el color para el freezing a un tono de naranja
    nofz_color = [96 96 96]/255; % Seteo el color para el no freezing
else
    fz_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
    nofz_color = [96 96 96]/255; % Seteo el color para el CS-
end

bar(1,mean_lag1,0.7,'FaceColor',fz_color,'FaceAlpha',0.3);
hold on
errorbar(1, mean_lag1, sem_lag1, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
bar(2,mean_lag2,0.7,'FaceColor',nofz_color,'FaceAlpha',0.3);
hold on
errorbar(2, mean_lag2, sem_lag2, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
xlim([0.5 2.5]);
ylabel('Lag (ms)');

if strcmp(color,'CS')
    set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
elseif strcmp(color,'fz')
    set(gca,'xtick',[1:2],'xticklabel',{'Fz'; 'noFz'})
else
    set(gca,'xtick',[1:2],'xticklabel',{'A'; 'B'})
end

hold on
[p1] = ranksum(lag1,lag2);
if p1 >= 0.05;
    p1_value_res = 'ns';
elseif  p1 < 0.05 && p1 >= 0.01;
    p1_value_res = '*';
elseif p1 < 0.01;
    p1_value_res = '**';
end

[p2] =  signrank(lag1);
if p2 >= 0.05;
    p2_value_res = 'ns';
elseif p2 < 0.05 && p2 >= 0.01;
    p2_value_res = '*';
elseif p2 < 0.01;
    p2_value_res = '**';
end

[p3] = signrank(lag2);
if p3 >= 0.05;
    p3_value_res = 'ns';
elseif p3 < 0.05 && p3 >= 0.01;
    p3_value_res = '*';
elseif p3 < 0.01;
    p3_value_res = '**';
end

text(1.5,30,p1_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',12);
line([1 2],[24 24],'Color',[0 0 0],'LineWidth',0.5);
text(1,mean_lag1+10,p2_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',12);
text(2,mean_lag2+10,p3_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',12);

ylim([-10 30]);

hold off
return