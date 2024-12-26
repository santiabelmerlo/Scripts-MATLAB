function plot_zcurve_av(T_CS1,T_CS2,tt,region,frecuencia)
% Espectro de potencias para el CS+ - CS-
% Uso: plot_zcurve(T_CS1,T_CS2,tt)

cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
    
S_data = T_CS1';
y = mean(S_data); % your mean vector;
x = tt;
stdem = std(S_data,1)/sqrt(size(S_data,1));
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

S_data = T_CS2';
y = mean(S_data); % your mean vector;
x = tt;
stdem = std(S_data,1)/sqrt(size(S_data,1));
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
ylim([0.5 1]);
hold on
line([0 0],[-10 10],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
line([10 10],[-10 10],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
hold off
xlabel('Time (sec.)'); ylabel('Coherence');
title(strcat('',region,' -',frecuencia));

return