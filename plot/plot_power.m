function plot_power(T_CS1,T_CS2,region,frecuencia,paradigma)
% Curva de power envelope en funcion de los trials
% Uso: plot_power(SPG_CS1,SPG_CS2,'BLA','Theta','aversivo')

if strcmp(paradigma,'appetitive');
    smoothing = 10;
else
    smoothing = 4;
end

if strcmp(paradigma,'appetitive');
    cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
else
    cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
end
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
    
S_data = T_CS1;
y = nanmedian(S_data',1); % your mean vector;
x = 2:2:size(S_data,1)*2;
stdem = nanmedian(abs(bsxfun(@minus, S_data', nanmedian(S_data'))))/sqrt(size(S_data,2));

% Hacemos padding y suavizado de la mediana de T_CS1
data = y;
pad_size = smoothing;
padded_data = [repmat(data(1), 1, pad_size), data, repmat(data(end), 1, pad_size)];
smoothed_padded_data = smooth(padded_data, smoothing);
smoothed_data = smoothed_padded_data(pad_size+1:end-pad_size);
y = smoothed_data';

% Hacemos padding y suavizado del stdem de T_CS1
data = stdem;
pad_size = smoothing;
padded_data = [repmat(data(1), 1, pad_size), data, repmat(data(end), 1, pad_size)];
smoothed_padded_data = smooth(padded_data, smoothing);
smoothed_data = smoothed_padded_data(pad_size+1:end-pad_size);
stdem = smoothed_data';

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
max1 = max(cat(2,curve1,curve2));
min1 = min(cat(2,curve1,curve2));

S_data = T_CS2;
y = nanmedian(S_data',1); % your mean vector;
x = 2:2:size(S_data,1)*2;
stdem = nanmedian(abs(bsxfun(@minus, S_data', nanmedian(S_data'))))/sqrt(size(S_data,2));

% Hacemos padding y suavizado de la mediana de T_CS2
data = y;
pad_size = smoothing;
padded_data = [repmat(data(1), 1, pad_size), data, repmat(data(end), 1, pad_size)];
smoothed_padded_data = smooth(padded_data, smoothing);
smoothed_data = smoothed_padded_data(pad_size+1:end-pad_size);
y = smoothed_data';

% Hacemos padding y suavizado del stdem de T_CS2
data = stdem;
pad_size = smoothing;
padded_data = [repmat(data(1), 1, pad_size), data, repmat(data(end), 1, pad_size)];
smoothed_padded_data = smooth(padded_data, smoothing);
smoothed_data = smoothed_padded_data(pad_size+1:end-pad_size);
stdem = smoothed_data';

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
max2 = max(cat(2,curve1,curve2));
min2 = min(cat(2,curve1,curve2));

max3 = max(cat(2,max1,max2));
min3 = min(cat(2,min1,min2));

% ylim([min3-0.05 max3+0.05]);
ylim([-1 1]);
xlim([2 size(T_CS1,1)*2]);

hold off
xlabel('Trial'); ylabel('Power (z-score)');
title(sprintf('%s - %s Power', region, frecuencia), 'FontSize', 11);

return