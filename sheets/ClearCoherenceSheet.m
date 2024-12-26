%% Script para limpiar la planilla de Coherence de unos datos medios ruidosos que se daban de forma repetitiva
clc
clear all

% Cargamos los datos
cd('D:\Doctorado\Analisis\Sheets');
Coherence = readtable('Coherence_Sheet.csv');
Coherence.Properties.VariableNames = cellfun(@(x) strrep(x, '_C', ''), Coherence.Properties.VariableNames, 'UniformOutput', false);

% Limpiamos la tabla Coherence de unos datos raros, repetitivos
for col = 2:width(Coherence)
    data = Coherence{:, col}; % Extract the column data
    [unique_vals, ~, indices] = unique(data); % Find unique values and their counts
    counts = accumarray(indices, 1);
    repeated_vals = unique_vals(counts > 20);
    repeated_indices = ismember(data, repeated_vals);
    data(repeated_indices) = NaN;
    Coherence{:, col} = data; % Update the table column
end

% Guardamos ambos datos
cd('D:\Doctorado\Analisis\Sheets');
writetable(Coherence, 'Coherence_Sheet.csv');

disp('Ready!');