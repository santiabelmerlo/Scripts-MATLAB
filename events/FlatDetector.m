%% Detecci�n de las partes flat de la se�al
% Me genera dos vectores llamados inicio_flat y fin_flat 
% Este script usa la funci�n find_regions

lfp = lfp_BLA;

% Par�metros
Fs = 1250; % Frecuencia de muestreo en Hz

% Calcular diferencias consecutivas
threshold = 0.01; % Umbral para diferencias peque�as
flat_signal = abs(diff(lfp)) < threshold;

% Detectar regiones planas
min_samples = 5; % M�nimo n�mero de muestras consecutivas para considerar "plano"
flat_regions = find_regions(flat_signal, min_samples);

% Convertir �ndices a tiempos en segundos
inicio_flat = (flat_regions(:,1) - 1) / Fs; % Inicio de cada regi�n plana
fin_flat = flat_regions(:,2) / Fs;         % Fin de cada regi�n plana
inicio_flat = inicio_flat';
fin_flat = fin_flat';

% Mostrar resultados
disp('Tiempos de inicio de regiones planas (s):');
disp(inicio_flat);
disp('Tiempos de fin de regiones planas (s):');
disp(fin_flat);

% Graficar se�al y resaltar regiones planas
figure;
plot((1:length(lfp)) / Fs, lfp); hold on;
for i = 1:size(flat_regions, 1)
    plot((flat_regions(i,1):flat_regions(i,2)) / Fs, lfp(flat_regions(i,1):flat_regions(i,2)), 'r', 'LineWidth', 2);
end
xlabel('Tiempo (s)');
ylabel('Amplitud');
title('Detecci�n de secciones planas en se�al LFP');
legend('LFP', 'Secciones planas');


