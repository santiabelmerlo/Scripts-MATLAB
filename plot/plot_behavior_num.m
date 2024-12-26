function plot_behavior_num(B_CS1,B_CS2,tt)
% Para plotear comportamiento centrado en el onset del tono
% En unidades de eventos
% Uso: plot_behavior(B_CS1,B_CS2,tt)

cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
    
S_data = B_CS1'/unique(diff(tt)); S_data = S_data*60;
y = mean(S_data); % your mean vector;
x = tt;
stdem = std(S_data,1)/sqrt(size(S_data,1));
y = (smooth(y))';
stdem = (smooth(stdem))';
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p1 = fill(x2, inBetween, cs1_color,'LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y, 'Color',cs1_color, 'LineWidth', 1);
hold on;
clear S_data;

S_data = B_CS2'/unique(diff(tt)); S_data = S_data*60;
y = mean(S_data); % your mean vector;
x = tt;
stdem = std(S_data,1)/sqrt(size(S_data,1));
y = (smooth(y))';
stdem = (smooth(stdem))';
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p1 = fill(x2, inBetween, cs2_color,'LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y, 'Color',cs2_color, 'LineWidth', 1);
hold on;
clear S_data;
hold on
line([0 0],[0 100],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
line([10 10],[0 100],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
hold off

ylim([0 2]);

return