function plot_zcurve_permutationtest_av(T_CS1,T_CS2,tt,region,frecuencia)

% Generate sample data (replace with your actual data)
CS1_data = T_CS1; % 100 time points, 50 trials for CS1
CS2_data = T_CS2; % 100 time points, 50 trials for CS2

% Si lo quiero calcular con media y sem
mean_CS1 = nanmedian(CS1_data, 2);
sem_CS1 = nanstd(CS1_data, 0, 2) / sqrt(size(CS1_data, 2));
mean_CS2 = nanmedian(CS2_data, 2);
sem_CS2 = nanstd(CS2_data, 0, 2) / sqrt(size(CS2_data, 2));

% % Si lo quiero calcular con mediana y mad
% mean_CS1 = nanmedian(CS1_data, 2);
% deviations_CS1 = abs(bsxfun(@minus, CS1_data, mean_CS1));
% sem_CS1 = nanmedian(deviations_CS1, 2) / sqrt(size(CS1_data, 2));
% mean_CS2 = nanmedian(CS2_data, 2);
% deviations_CS2 = abs(bsxfun(@minus, CS2_data, mean_CS2));
% sem_CS2 = nanmedian(deviations_CS2, 2) / sqrt(size(CS2_data, 2));

num_permutations = 1000; % Number of permutations
observed_t_statistic = zeros(size(CS1_data, 1), 1);
for t = 1:size(CS1_data, 1)
    [~, observed_t_statistic(t)] = ttest2(CS1_data(t, :), CS2_data(t, :)); % Use [~, observed_t_statistic(t)] to only capture the t-statistic
end

permuted_t_statistics = zeros(num_permutations, size(CS1_data, 1));

for i = 1:num_permutations
    combined_data = [CS1_data, CS2_data];
    shuffled_indices = randperm(size(combined_data, 2));
    shuffled_CS1 = combined_data(:, shuffled_indices(1:size(CS1_data, 2)));
    shuffled_CS2 = combined_data(:, shuffled_indices(size(CS1_data, 2)+1:end));
    
    for t = 1:size(CS1_data, 1)
        [~, permuted_t_statistics(i, t)] = ttest2(shuffled_CS1(t, :), shuffled_CS2(t, :)); % Use [~, permuted_t_statistics(i, t)] to only capture the t-statistic
    end
end

% Calculate p-values for each time point

% Initialize p_values array
p_values = zeros(1, size(CS1_data, 1));

for t = 1:size(CS1_data, 1)
    p_values(t) = sum(permuted_t_statistics(:, t) < observed_t_statistic(t)) / num_permutations;
end

% Find significant points
significant_points = find(p_values < 0.05);

time_points = 1:size(CS1_data, 1);

% % Plot significant times as vertical shaded areas
% for t = 1:length(significant_points)-1
%     x = [tt(significant_points(t)), tt(significant_points(t)+1), tt(significant_points(t)+1), tt(significant_points(t)), tt(significant_points(t))];
%     y = [-10, -10, 10, 10, -10];
%     fill(x, y, [0.8 0.8 0.8], 'FaceAlpha', 0.3,'EdgeColor', 'none');
%     clear x y;
%     hold on;
% end

plot_zcurve_av(T_CS1,T_CS2,tt,region,frecuencia);
set(gca, 'Layer', 'top');
hold on;

set(gca,'fontsize',10);
set(gca, 'YTick', -10:0.5:10);
xlim([-20 80]);
ylim([-1.5 1.5]);
hold off;

return