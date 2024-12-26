%% Script para calcular los límites de las bandas frecuenciales
% Fitea una función de Lorentz al PSD medio de la sesión y luego le resta
% ese componente aperiódico. Finalmente busca los máximos y mínimos.

clc;
clear all;
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Importo un espectrograma cualquiera de una sesión
load(strcat(name,'_specgram_ILLowFreq.mat'));

% Normalizamos a decibeles
S = 10*log10(S);

% figure();
S_data = S;
y = mean(S_data); % your mean vector;
x = f;
stdem = std(S_data,1)/sqrt(size(S_data,1));
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p1 = fill(x2, inBetween, 'm','LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y,'m', 'LineWidth', 2);
hold on;

ylabel(['Power ± SEM (dB)']);
xlabel('Frequency (Hz)');
title('Mean PSD');

% Como la potencia debajo de 1 Hz se reduce drásticamente ya que estoy
% multiplicando por un valor menor a 1, lo que puedo hacer es cortar el
% plot en 1 Hz y en 99 Hz ya que en 100 tengo ruido y arriba de 100 no pasa
% nada.
xlim([1 150]);
hold on

S1 = mean(S,1);

% Step 2: Define the custom Lorentz function
lorentzFunc = fittype('b - log10(k + f.^X)', 'independent', 'f', 'coefficients', {'b', 'k', 'X'});

% Step 3: Fit the Lorentz function to the data
% Provide initial guesses for the coefficients [b, k, X]
initialGuesses = [20, 1e6, 15];  % Adjust initial guesses based on your data

% Perform the fit
[fitresult, gof] = fit(f', S1', lorentzFunc, 'StartPoint', initialGuesses);

% Step 4: Display the fit results
disp(fitresult);
disp(gof);

% Plot the original data and the fitted curve
figure;
plot(fitresult, f', S1');
xlabel('Frequency (Hz)');
ylabel('Power ± SEM (dB)');
title('Lorentz Function Fit');
legend('PSD', 'Fitted Lorentz Function');

b = fitresult.b;
k = fitresult.k;
X = fitresult.X;
L = b - log10(k + f.^X);

figure();
xlim([1 150]);
hold on
S2 = mean(S,1) - L;
plot(f,S2);

% Example vector
data = smooth(S2,20);

% Find local minima
local_minima = islocalmin(data);

% Find local maxima
local_maxima = islocalmax(data);

% Extract indices of local minima and maxima
minima_indices = find(local_minima);
maxima_indices = find(local_maxima);

% Display the indices
disp('Local minima detected at indices:');
disp(minima_indices);

disp('Local maxima detected at indices:');
disp(maxima_indices);

% Optional: Visualize the data with local minima and maxima
figure;
plot(f,data, '-b', 'DisplayName', 'Data');
hold on;
plot(f(minima_indices), data(minima_indices), 'ro', 'DisplayName', 'Local Minima');
plot(f(maxima_indices), data(maxima_indices), 'go', 'DisplayName', 'Local Maxima');

xlabel('Frequency (Hz)');
ylabel('Power ± SEM (dB)');
title('Local Minima and Maxima in PSD with no aperiodic component');
legend('show');
hold off;
