%% Colorbar
% Script para plotear solo el colorbar y setear el label y los min y máx
figure;
cb = colorbar; % Ploteamos el colorbar
colormap(jet); % Seteamos la escala de colores como jet
% cb.YLabel.String = 'Potencia (z-score)'; % Seteamos el label del colorbar
cb.YLabel.String = 'Potencia (dB)'; % Seteamos el label del colorbar
cb.FontSize = 6; % Seteamos el tamaño de la fuente
caxis([-0.5 0.5]); % Seteamos los límites minimos y máximos de la escala
axis off % Eliminamos los ejes X e Y
set(gcf, 'Color', 'white'); % Seteamos el fondo como blanco
set(gcf, 'Position', [100, 300, 150, 150]); % seteamos el tamaño de la figura
pos = get(cb, 'Position'); % Obtenemos la posición actual del colorbar
set(cb, 'Position', [pos(1) 0.42 pos(3) 0.2]); % Seteamos tamaño y posición del colorbar

% Personalizamos las etiquetas
set(cb, 'YTick', [-0.5, 0, 0.5]); % Especificamos las ubicaciones de las etiquetas
set(cb, 'YTickLabel', {'15', '27', '40'}); % Definimos las etiquetas personalizadas
