%% Como aplicar un modelo GLMM en matlab
% Con datos inventados
clc
clear all

% Define the number of samples
n = 1000;
% Define the Type groups and corresponding means for the normal distributions
typeGroups = ['A', 'B', 'C', 'D'];
groupSizes = n / numel(typeGroups); % Assume equal group sizes
% Generate normal distributions for each Type group
mean_A = 15; % Mean of group A and D
mean_B = 10; % Mean of group B (equal to C)
mean_C = 10; % Mean of group C (equal to B)
% Standard deviation for each group
std_dev = 2;
% Generate random values for Duracion based on the means
duracion_A = mean_A + std_dev * randn(groupSizes, 1);
duracion_B = mean_B + std_dev * randn(groupSizes, 1);
duracion_C = mean_C + std_dev * randn(groupSizes, 1);
duracion_D = mean_A + std_dev * randn(groupSizes, 1); % D is equal to A
% Concatenate Duracion values and create Type labels
Duracion = [duracion_A; duracion_B; duracion_C; duracion_D];
Type = [repmat('A', groupSizes, 1); repmat('B', groupSizes, 1); ...
        repmat('C', groupSizes, 1); repmat('D', groupSizes, 1)];
% Generate Rat values in the range 10 to 15 (as given in the prompt)
Rat = randi([10, 15], n, 1);
% Create the table
df = table(Duracion, Type, Rat);

% Boxplot of Duracion by Type
figure;
boxplot(df.Duracion, df.Type);
hold on;

% Add labels and title
xlabel('Type');
ylabel('Duracion');
title('Distribution of Duracion by Type');

% Customize the plot
grid on;
hold off;

%
% Cambiamos la variable Type a nominal
df.Type = nominal(df.Type);
levels = getlevels(df.Type);
disp(levels);

% Ajustamos el modelo
glme = fitglme(df,'Duracion ~ Type + (1|Rat)', ...
    'Distribution','gamma','Link','log','FitMethod','Laplace','DummyVarCoding','full');
disp(glme)

anova(glme)

% Display fixed-effects estimates
[beta, names] = fixedEffects(glme);
disp('Fixed Effects Coefficients:');
T = table(names, beta)

glme.CoefficientNames

% Check the order of fixed effects in the model

% Contrast for A vs B (assuming A is the reference level)
contrast_A_B = [0 1 0 0]; % B against the reference A
contrast_A_C = [0 0 1 0]; % C against the reference A
contrast_A_D = [0 0 0 1]; % D against the reference A
contrast_B_C = [0 1 -1 0];
contrast_B_D = [0 1 0 -1];
contrast_C_D = [0 0 1 -1];

% Perform each pairwise test using coefTest and display the results
disp('Pairwise comparisons:');
[p_A_B, F_A_B, DF1_A_B, DF2_A_B] = coefTest(glme, contrast_A_B);
disp(['p-value for A vs B: ', num2str(p_A_B)]);

[p_A_C, F_A_C, DF1_A_C, DF2_A_C] = coefTest(glme, contrast_A_C);
disp(['p-value for A vs C: ', num2str(p_A_C)]);

[p_A_D, F_A_D, DF1_A_D, DF2_A_D] = coefTest(glme, contrast_A_D);
disp(['p-value for A vs D: ', num2str(p_A_D)]);

[p_B_C, F_B_C, DF1_B_C, DF2_B_C] = coefTest(glme, contrast_B_C);
disp(['p-value for B vs C: ', num2str(p_B_C)]);

[p_B_D, F_B_D, DF1_B_D, DF2_B_D] = coefTest(glme, contrast_B_D);
disp(['p-value for B vs D: ', num2str(p_B_D)]);

[p_C_D, F_C_D, DF1_C_D, DF2_C_D] = coefTest(glme, contrast_C_D);
disp(['p-value for C vs D: ', num2str(p_C_D)]);

%% Ahora con mis datos
clc
clear all

cd('D:\Doctorado\Analisis')
df = readtable('datosglmmm.csv');

% Ploteamos boxplot
figure;
h = boxplot(df.Duracion, df.Type, ...
    'color', lines, ...
    'labels', {'CS+', 'CS-', 'preCS', 'ITI'}, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 
ylabel('Duración (sec.)');
grid off;
ylim([0 8])
hold off;

% Ajustamos el modelo
df.Type = nominal(df.Type);
glme = fitglme(df,'Duracion ~ Type + (1|Rat)', ...
    'Distribution','gamma','Link','log','FitMethod','Laplace');
disp(glme)

% Mostramos los efectos fijos
[beta, names] = fixedEffects(glme)
CoefNames = glme.CoefficientNames

% Calculamos el ANOVA
ANOVA = anova(glme)

% Hacemos las comparaciones múltiples
disp('CS+ vs CS-:');
[p, F, DF1, DF2] = coefTest(glme, [0 1 0 0]);
disp(['p-value: ', num2str(p)]);
disp('CS+ vs preCS:');
[p, F, DF1, DF2] = coefTest(glme, [0 0 1 0]);
disp(['p-value: ', num2str(p)]);
disp('CS+ vs ITI:');
[p, F, DF1, DF2] = coefTest(glme, [0 0 0 1]);
disp(['p-value: ', num2str(p)]);
disp('CS- vs preCS:');
[p, F, DF1, DF2] = coefTest(glme, [0 1 -1 0]);
disp(['p-value: ', num2str(p)]);
disp('CS- vs ITI:');
[p, F, DF1, DF2] = coefTest(glme, [0 1 0 -1]);
disp(['p-value: ', num2str(p)]);
disp('preCS vs ITI:');
[p, F, DF1, DF2] = coefTest(glme, [0 0 1 -1]);
disp(['p-value: ', num2str(p)]);