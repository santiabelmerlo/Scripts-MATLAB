function plot_behavior_prob_av(B_CS1,B_CS2,tt)
% Para plotear comportamiento centrado en el onset del tono
% Uso: plot_behavior(B_CS1,B_CS2,tt)

span = 20;

cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
    
S_data = B_CS1';
y = nanmean(S_data); % your mean vector;
x = tt;
stdem = nanstd(S_data,1)/sqrt(size(S_data,1));
y = (smooth(y,span))';
stdem = (smooth(stdem,span))';
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

S_data = B_CS2';
y = nanmean(S_data); % your mean vector;
x = tt;
stdem = nanstd(S_data,1)/sqrt(size(S_data,1));
y = (smooth(y,span))';
stdem = (smooth(stdem,span))';
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
line([60 60],[0 100],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
hold off

ylim([0 1]);

return