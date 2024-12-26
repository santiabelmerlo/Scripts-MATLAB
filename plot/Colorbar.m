%% Colorbar
% Script para plotear solo el colorbar y setear el label y los min y m�x
figure;
cb = colorbar; % Ploteamos el colorbar
colormap(jet); % Seteamos la escala de colores como jet
% cb.YLabel.String = 'Potencia (z-score)'; % Seteamos el label del colorbar
cb.YLabel.String = 'Potencia (dB)'; % Seteamos el label del colorbar
cb.FontSize = 6; % Seteamos el tama�o de la fuente
caxis([-0.5 0.5]); % Seteamos los l�mites minimos y m�ximos de la escala
axis off % Eliminamos los ejes X e Y
set(gcf, 'Color', 'white'); % Seteamos el fondo como blanco
set(gcf, 'Position', [100, 300, 150, 150]); % seteamos el tama�o de la figura
pos = get(cb, 'Position'); % Obtenemos la posici�n actual del colorbar
set(cb, 'Position', [pos(1) 0.42 pos(3) 0.2]); % Seteamos tama�o y posici�n del colorbar

% Personalizamos las etiquetas
set(cb, 'YTick', [-0.5, 0, 0.5]); % Especificamos las ubicaciones de las etiquetas
set(cb, 'YTickLabel', {'15', '27', '40'}); % Definimos las etiquetas personalizadas
