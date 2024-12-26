%%
T = join(PowerData, BehaviorTimeSeries, 'Keys', 'ID');
T = T(T.Flat == 0,:);

for i = 1:height(T);
    data = T.Acc{i};
    data = nanmean(data(11:13,1));
    T.MeanAcc(i) = data;
    clear data;
end

T.Properties.VariableNames{'Enrich_PowerData'} = 'Enrich';

T_4Hz = T(strcmp(T.Enrich, '4Hz'), :);
T_Theta = T(strcmp(T.Enrich, 'Theta'), :);
%%
figure
colores = lines;
scatter(T_4Hz.MeanAcc, T_4Hz.Ratio, 2, 'MarkerFaceColor', colores(3,:), 'MarkerEdgeColor', colores(3,:), 'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 1);
hold on;
scatter(T_Theta.MeanAcc, T_Theta.Ratio, 2, 'MarkerFaceColor', colores(4,:), 'MarkerEdgeColor', colores(4,:), 'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 1);
ylabel('4-Hz:Theta Ratio');
xlabel('Acceleration (cm/s2)');
title('Movement events');
xlim([0 30]);
ylim([0 5])

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 300 300]);

figure
colores = lines;
scatter(T_4Hz.MeanAcc, T_4Hz.Power, 2, 'MarkerFaceColor', colores(1,:), 'MarkerEdgeColor', colores(1,:), 'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 1);
hold on;
scatter(T_Theta.MeanAcc, T_Theta.Power, 2, 'MarkerFaceColor', colores(2,:), 'MarkerEdgeColor', colores(2,:), 'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 1);
ylabel('BLA Theta Power');
xlabel('Acceleration (cm/s2)');
title('Freezing events');
xlim([0 30]);
ylim([-3 5])

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 300 300]);

%% Nos quedamos con los eventos de alta aceleración para ver cómo es el espectrograma
T = T(T.MeanAcc >= 10,:);
SpecT = join(T, SpecData, 'Keys', 'ID');
SpecT.Properties.VariableNames{'Enrich_SpecData'} = 'Enrich';
S_4hz = SpecT(strcmp(SpecT.Enrich, '4Hz'),:);
S_Theta = SpecT(strcmp(SpecT.Enrich, 'Theta'),:);

S1 = [];
for i = 1:size(S_4hz,1)
    S1 = cat(3,S1,S_4hz.S{i});
end
S1 = nanmedian(S1,3);

S2 = [];
for i = 1:size(S_Theta,1)
    S2 = cat(3,S2,S_Theta.S{i});
end
S2 = nanmedian(S2,3);

% Ploteamos los espectrogramas
figure;
subplot(121)
S_1 = bsxfun(@minus, S1, nanmedian(S1(1:round(size(S1,1)/2),:),1));
plot_matrix_smooth(S_1,t_S,f,'n',5); ylim([0 12]); xlim([-5 5]); clim([-0.5 0.5]); colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['4-Hz Fz ' '(n=' num2str(size(S_4hz,1)) ')']);
subplot(122)
S_2 = bsxfun(@minus, S2, nanmedian(S2(1:round(size(S2,1)/2),:),1));
plot_matrix_smooth(S_2,t_S,f,'n',5); ylim([0 12]); xlim([-5 5]); clim([-0.5 0.5]);; colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['Theta Fz ' '(n=' num2str(size(S_Theta,1)) ')']);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 450 200]);

% Ploteamos los espectrogramas
figure;
subplot(121)
S_1 = bsxfun(@minus, S1, nanmedian(S1(1:round(size(S1,1)/2),:),1));
plot_matrix_smooth(S_1,t_S,f,'n',5); ylim([12 100]); xlim([-5 5]); clim([-0.5 0.5]); colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['4-Hz Fz ' '(n=' num2str(size(S_4hz,1)) ')']);
subplot(122)
S_2 = bsxfun(@minus, S2, nanmedian(S2(1:round(size(S2,1)/2),:),1));
plot_matrix_smooth(S_2,t_S,f,'n',5); ylim([12 100]); xlim([-5 5]); clim([-0.5 0.5]);; colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['Theta Fz ' '(n=' num2str(size(S_Theta,1)) ')']);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 450 200]);

%% Nos quedamos con los eventos que tienen aceleración alta para ver como es el perfil de aceleraciones 
% Separando por 4HzFz y ThetaFz

T = join(PowerData, BehaviorTimeSeries, 'Keys', 'ID');
T = T(T.Flat == 0,:);

for i = 1:height(T);
    data = T.Acc{i};
    data = nanmean(data(11:13,1));
    T.MeanAcc(i) = data;
    clear data;
end

T.Properties.VariableNames{'Enrich_PowerData'} = 'Enrich';

T = T(T.MeanAcc >= 10,:);
t_S = -5:0.5:5;

type_labels = containers.Map([0, 1], {'4Hz Fz', 'Theta Fz'}); % Define custom labels for each Type
unique_types = unique(T.Enrich); % Get unique Types after merging
mean_acc_per_type = zeros(length(t_S), length(unique_types)); % Initialize array to store nanmean results

% Loop through each unique Type to calculate the nanmean for each timestamp
for i = 1:length(unique_types)
    % Select rows for the current Type
    type_rows = strcmp(T.Enrich, unique_types(i));
    
    % Extract Acc data for the current Type
    acc_data_cells = T.Acc(type_rows);
    
    % Find the maximum length of Acc data across selected rows
    max_length = max(cellfun(@length, acc_data_cells));
    
    % Pad each Acc entry to the maximum length with NaNs
    acc_data_padded = cellfun(@(x) [x(:); NaN(max_length - length(x), 1)], ...
                              acc_data_cells, 'UniformOutput', false);
    
    % Concatenate padded Acc data and calculate nanmean across each timestamp
    acc_data_matrix = cat(2, acc_data_padded{:});
    sem_acc_per_type(:, i) = nansem(acc_data_matrix,2);
    mean_acc_per_type(:, i) = nanmean(acc_data_matrix, 2);
end

% Plot the results
figure;
hold on;
colors = lines(length(unique_types)); % Get distinct colors for each Type

for i = 1:length(unique_types)
    % Extract mean and SEM for the current type
    y = mean_acc_per_type(:, i); % Mean values
    sem = sem_acc_per_type(:, i); % SEM values
    t = t_S; % Time vector

    % Create shaded error region
    curve1 = y + sem; % Upper bound of SEM
    curve2 = y - sem; % Lower bound of SEM
    x2 = [t, fliplr(t)]; % Combine x-coordinates for fill
    inBetween = [curve1', fliplr(curve2')]; % Combine y-coordinates for fill
    p1 = fill(x2, inBetween, colors(i, :), 'FaceAlpha', 0.4, 'EdgeColor', 'none', ...
              'HandleVisibility', 'off'); % Shaded region without legend entry

    % Plot the mean line
    plot(t, y, 'Color', colors(i, :), 'LineWidth', 1.5, ...
         'DisplayName', unique_types{i}); % Line plot with label
end

% Add labels, legend, and title
xlim([-5 5]);
xlabel('Time (s)');
ylabel('Acceleration (cm/s^2)');
legend('show', 'Location', 'eastoutside'); % Places the legend outside on the right
title('');
hold off;

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 300 200]);

%%
for i = 1:height(T)
    plot(t_S,T.Acc{i})
    pause(2);
end