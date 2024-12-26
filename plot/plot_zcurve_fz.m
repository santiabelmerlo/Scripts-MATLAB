function plot_zcurve_fz(T_CS1,T_CS2,tt,region,frecuencia)
% Espectro de potencias para el CS+ - CS-
% Uso: plot_zcurve(T_CS1,T_CS2,tt)

cs1_color = [255 140 0]/255; % Seteo el color para el freezing a un tono de naranja
cs2_color = [96 96 96]/255; % Seteo el color para el no freezing
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
    
S_data = T_CS1';
y = smooth(nanmedian(S_data)); % your mean vector;
x = tt;

% Calculamos el stdem como el MAD
stdem = smooth(nanmedian(abs(bsxfun(@minus,S_data,nanmedian(S_data,1))),1)/sqrt(size(S_data,1)));
% stdem = smooth(nanstd(S_data,1)/sqrt(size(S_data,1)));
% stdem = nanstd(S_data,1)/sqrt(size(S_data,1));
% stdem(stdem > 0.2) = 0.2;
% stdem = smooth(stdem);

curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1', fliplr(curve2')];
p1 = fill(x2, inBetween, cs1_color,'LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y, 'Color',cs1_color, 'LineWidth', 1);
hold on;
clear S_data;
max1 = max(cat(2,curve1,curve2));
min1 = min(cat(2,curve1,curve2));

S_data = T_CS2';
y = smooth(nanmedian(S_data)); % your mean vector;
x = tt;

% Calculamos el stdem como el MAD
stdem = smooth(nanmedian(abs(bsxfun(@minus,S_data,nanmedian(S_data,1))),1)/sqrt(size(S_data,1)));
% stdem = smooth(nanstd(S_data,1)/sqrt(size(S_data,1)));
% stdem = nanstd(S_data,1)/sqrt(size(S_data,1));
% stdem(stdem > 0.2) = 0.2;
% stdem = smooth(stdem);

curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1', fliplr(curve2')];
p1 = fill(x2, inBetween, cs2_color,'LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y, 'Color',cs2_color, 'LineWidth', 1);
hold on;
clear S_data;
max2 = max(cat(2,curve1,curve2));
min2 = min(cat(2,curve1,curve2));

max3 = max(cat(2,max1,max2));
min3 = min(cat(2,min1,min2));

set(gca, 'YTick', [-1:0.2:1]);
% ylim([min3-0.2 max3+0.2]);
ylim([-1 1]);
hold on
line([0 0],[-10 10],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
% line([10 10],[-10 10],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
hold off
xlabel('Time (sec.)'); ylabel('Power (z-score)');
title(sprintf('%s %s', region, frecuencia));

return