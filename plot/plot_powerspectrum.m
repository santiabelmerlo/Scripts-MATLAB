function plot_powerspectrum(T_CS1,T_CS2,f)
% Espectro de potencias para el CS+ - CS-

cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
    
S_data = T_CS1';
y = mean(S_data); % your mean vector;
x = f;
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
x = f;
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
hold on
hold off
xlabel('Frequency (Hz)'); ylabel('Power (dB)');
set(gcf, 'Color', 'white');
ylim([-5 30]);
return