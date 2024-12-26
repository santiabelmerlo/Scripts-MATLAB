% Función para detectar regiones consecutivas
function regions = find_regions(signal, min_length)
    edges = diff([0 signal 0]); % Detectar inicios y finales
    starts = find(edges == 1);
    ends = find(edges == -1) - 1;
    durations = ends - starts + 1;
    valid = durations >= min_length; % Filtrar por duración mínima
    regions = [starts(valid)' ends(valid)'];
end