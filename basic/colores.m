function rgb = colores(nombre_color)
    % Define tus colores personalizados
    switch lower(nombre_color)  % Ignora mayúsculas/minúsculas
        case 'control'
            rgb = [128, 128, 128]/255; % Gris Control
        case 'cs1'
            rgb = [249, 64, 64]/255; % Magenta CS+
        case 'cs2'
            rgb = [15, 153, 178]/255; % Cyan CS-
        case 'cs+'
            rgb = [249, 64, 64]/255; % Magenta CS+
        case 'cs-'
            rgb = [15, 153, 178]/255; % Cyan CS-
        case 'freezing'
            rgb = [255, 128, 0]/255; % Naranja Freezing
        case 'apetitivo'
            rgb = [0, 192, 0]/255; % Verde Apetitivo
        case 'aversivo'
            rgb = [173, 7, 227]/255; % Gris neutro
        case 'bla'
            rgb = [255, 160, 64]/255; % Naranja Pastel
        case 'pl'
            rgb = [5, 190, 120]/255; % Verde Esmeralda
        case 'il'
            rgb = [192, 0, 192]/255; % Violeta
        case '4hz'
            rgb = [249, 64, 64]/255; % Magenta
        case 'theta'
            rgb = [15, 153, 178]/255; % Cyan 
        case 'beta'
            rgb = [245, 128, 64]/255; % Naranja
        case 'sgamma'
          rgb = [5, 190, 120]/255; % Verde Esmeralda
        case 'fgamma'
            rgb = [192, 0, 192]/255; % Violeta
        case 'negro'
            rgb = [0, 0, 0]/255; % Negro
        case 'gris'
            rgb = [128, 128, 128]/255; % Gris
        case 'magenta'
            rgb = [249, 64, 64]/255; % Magenta CS+
        case 'cyan'
            rgb = [15, 153, 178]/255; % Cyan CS-
        case 'blanco'
            rgb = [255, 255, 255]/255; % Blanco
        otherwise
            rgb = [0, 0, 0]/255; % Negro
    end
end
