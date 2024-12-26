%% Detección de las partes flat de la señal
% Me genera dos vectores llamados inicio_flat y fin_flat 
% Este script usa la función find_regions

lfp = lfp_BLA;

% Parámetros
Fs = 1250; % Frecuencia de muestreo en Hz

% Calcular diferencias consecutivas
threshold = 0.01; % Umbral para diferencias pequeñas
flat_signal = abs(diff(lfp)) < threshold;

% Detectar regiones planas
min_samples = 5; % Mínimo número de muestras consecutivas para considerar "plano"
flat_regions = find_regions(flat_signal, min_samples);

% Convertir índices a tiempos en segundos
inicio_flat = (flat_regions(:,1) - 1) / Fs; % Inicio de cada región plana
fin_flat = flat_regions(:,2) / Fs;         % Fin de cada región plana
inicio_flat = inicio_flat';
fin_flat = fin_flat';

% Mostrar resultados
disp('Tiempos de inicio de regiones planas (s):');
disp(inicio_flat);
disp('Tiempos de fin de regiones planas (s):');
disp(fin_flat);

% Graficar señal y resaltar regiones planas
figure;
plot((1:length(lfp)) / Fs, lfp); hold on;
for i = 1:size(flat_regions, 1)
    plot((flat_regions(i,1):flat_regions(i,2)) / Fs, lfp(flat_regions(i,1):flat_regions(i,2)), 'r', 'LineWidth', 2);
end
xlabel('Tiempo (s)');
ylabel('Amplitud');
title('Detección de secciones planas en señal LFP');
legend('LFP', 'Secciones planas');


