%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Para calcular la media de freezing de cada animal
% Unique animal IDs
animal_ids = unique(freezing_id);

% Initialize a vector to store the mean values
mean_freezing_dist = zeros(size(animal_ids));
median_freezing_dist = zeros(size(animal_ids));

% Compute mean freezing_dist for each animal
for i = 1:length(animal_ids)
    animal_id = animal_ids(i);
    mean_freezing_dist(i) = nanmean(freezing_dist(freezing_id == animal_id));
    median_freezing_dist(i) = nanmedian(freezing_dist(freezing_id == animal_id));
end

% Display results
disp(table(animal_ids', mean_freezing_dist', 'VariableNames', {'AnimalID', 'MeanFreezingDist'}));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
% Unique animal IDs and conditions
animal_ids = unique(freezing_id);
conditions = unique(freezing_when);

% Initialize a matrix to store the mean values
mean_freezing_dist = zeros(length(animal_ids), length(conditions));
median_freezing_dist = zeros(length(animal_ids), length(conditions));

% Compute mean freezing_dist for each animal and condition
for i = 1:length(animal_ids)
    for j = 1:length(conditions)
        mean_freezing_dist(i, j) = nanmean(freezing_dist(freezing_id == animal_ids(i) & freezing_when == conditions(j)));
        median_freezing_dist(i, j) = nanmedian(freezing_dist(freezing_id == animal_ids(i) & freezing_when == conditions(j)));
    end
end

% Display results
result_table = array2table(median_freezing_dist, 'VariableNames', {'CS_plus', 'CS_minus', 'ITI'});
result_table.AnimalID = animal_ids';
disp(result_table1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Separate freezing_dist by freezing_when
CS_plus = freezing_dist(freezing_when == 1);
CS_minus = freezing_dist(freezing_when == 2);
ITI = freezing_dist(freezing_when == 3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Para contar el numero de eventos de freezing por animal
animal_ids = unique(freezing_id);
conditions = unique(freezing_when);

% Initialize a matrix to store the counts
count_freezing_events = zeros(length(animal_ids), length(conditions));

% Compute the count of freezing events for each animal and condition
for i = 1:length(animal_ids)
    for j = 1:length(conditions)
        count_freezing_events(i, j) = sum(freezing_id == animal_ids(i) & freezing_when == conditions(j));
    end
end

% Convert the result to a table
result_table = array2table(count_freezing_events, 'VariableNames', {'CS_plus', 'CS_minus', 'ITI'});
result_table.AnimalID = animal_ids';

% Display the table
disp(result_table);

%%
% Define the bin edges based on x-axis values
binEdges = 1:0.5:20;  % For example, bins from 1 to 20 with a width of 2

% Calculate the bin width (constant in this case since we defined uniform bins)
binWidth = binEdges(2) - binEdges(1);

% Separate the data into groups based on freezing_when
group1 = freezing_dist(freezing_when == 1);
group2 = freezing_dist(freezing_when == 2);
group3 = freezing_dist(freezing_when == 3);

% Colors for each condition
cs1_color = [0.6350, 0.0780, 0.1840];  % Example color for CS+
cs2_color = [0, 0.4470, 0.7410];       % Example color for CS-
ITI_color = [0.4660, 0.6740, 0.1880];  % Example color for ITI

% Plot the histogram for each group
figure;

% % Group 1 (CS+)
% [counts1, edges1] = histcounts(group1, binEdges);
% probability1 = counts1 / sum(counts1);
% bar(edges1(1:end-1) + binWidth/2, probability1, 'FaceColor', cs1_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'DisplayName', 'CS+');
% hold on;
% 
% % Group 2 (CS-)
% [counts2, edges2] = histcounts(group2, binEdges);
% probability2 = counts2 / sum(counts2);
% bar(edges2(1:end-1) + binWidth/2, probability2, 'FaceColor', cs2_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'DisplayName', 'CS-');

% Group 3 (ITI)
[counts3, edges3] = histcounts(group3, binEdges);
probability3 = counts3 / sum(counts3);
bar(edges3(1:end-1) + binWidth/2, probability3, 'FaceColor', ITI_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'DisplayName', 'ITI');

% Set axis labels and limits
ylabel('Freezing probability');
xlabel('Freezing duration (sec.)');
xlim([0.5 10]);
ylim([0 0.4]);
legend('show');
hold off;

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 600, 400, 200]);