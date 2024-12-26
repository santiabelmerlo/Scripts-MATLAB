%% Cálculo de la probabilidad de freezing peri-evento de freezing
% Incluyendo al evento de freezing de referencia
% Leer la tabla de eventos
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

% Filtrar los eventos de Freezing
freezing_events = EventsSheet(strcmp(EventsSheet.Event, 'Freezing'), :);

freezing_events = freezing_events(freezing_events.noisy == 0, :);
freezing_events = freezing_events(freezing_events.Flat < 0.1, :);
freezing_events = freezing_events(freezing_events.Epileptic < 0.1, :);

% Separar los eventos según la columna 'Enrich'
freezing_4Hz = freezing_events(strcmp(freezing_events.Enrich, '4Hz'), :);
freezing_theta = freezing_events(strcmp(freezing_events.Enrich, 'Theta'), :);

% Definir el rango de tiempo para cuantificar la probabilidad (-5s a 5s)
time_range = -5:0.5:5; % Desde -5 a 5 segundos, en intervalos de 0.5 segundos

% Inicializar matrices para almacenar los vectores de probabilidad
freezing_data_4Hz = [];
freezing_data_theta = [];

% Para cada combinación de Rat y Name, calcular la probabilidad
for rat = unique(freezing_4Hz.Rat)'
    for session = unique(freezing_4Hz.Name)'

        % Filtrar eventos por Rat y Name
        session_data_4Hz = freezing_4Hz(freezing_4Hz.Rat == rat & strcmp(freezing_4Hz.Name, session), :);
        session_data_theta = freezing_theta(freezing_theta.Rat == rat & strcmp(freezing_theta.Name, session), :);

        % Iterar sobre cada evento de freezing y calcular los vectores de freezing en el rango de -5s a +5s
        for i = 1:height(session_data_4Hz)
            event_start = session_data_4Hz.Inicio(i);
            
            % Crear un vector de ceros (sin freezing)
            event_vector_4Hz = zeros(length(time_range), 1);
            
            % Verificar si en los bins de -5s a +5s hay eventos de freezing
            for t = -5:0.5:5
                time_window_start = event_start + t - 0.25; % Desde t - 0.25s hasta t + 0.25s
                time_window_end = event_start + t + 0.25; 
                
                % Marcar 1 si algún evento de freezing cae dentro de este intervalo de tiempo
                overlap_4Hz = sum(session_data_4Hz.Inicio < time_window_end & session_data_4Hz.Fin > time_window_start);
                if overlap_4Hz > 0
                    event_vector_4Hz(find(time_range == t)) = 1; % Marcamos 1 si está freezando
                end
            end
            
            % Apilar el vector de freezing para 4Hz
            freezing_data_4Hz = [freezing_data_4Hz; event_vector_4Hz'];
        end

        for i = 1:height(session_data_theta)
            event_start = session_data_theta.Inicio(i);
            
            % Crear un vector de ceros (sin freezing)
            event_vector_theta = zeros(length(time_range), 1);
            
            % Verificar si en los bins de -5s a +5s hay eventos de freezing
            for t = -5:0.5:5
                time_window_start = event_start + t - 0.25; % Desde t - 0.25s hasta t + 0.25s
                time_window_end = event_start + t + 0.25; 
                
                % Marcar 1 si algún evento de freezing cae dentro de este intervalo de tiempo
                overlap_theta = sum(session_data_theta.Inicio < time_window_end & session_data_theta.Fin > time_window_start);
                if overlap_theta > 0
                    event_vector_theta(find(time_range == t)) = 1; % Marcamos 1 si está freezando
                end
            end
            
            % Apilar el vector de freezing para Theta
            freezing_data_theta = [freezing_data_theta; event_vector_theta'];
        end
    end
end

% Calcular la probabilidad de freezing
prob_4Hz = mean(freezing_data_4Hz, 1);
prob_theta = mean(freezing_data_theta, 1);

% Graficar la probabilidad para 4Hz y Theta
figure;
hold on;
plot(time_range, prob_4Hz, 'LineWidth', 2, 'Color', [0.6, 0, 1]); % Color violeta para 4Hz
plot(time_range, prob_theta, 'LineWidth', 2, 'Color', [0, 0, 0]); % Color negro para Theta

% Añadir una línea punteada en el tiempo 0
line([0 0], [0 1], 'Color', [0 0 0], 'LineWidth', 0.5, 'LineStyle', '--');
line([nanmedian(freezing_4Hz.Duracion) nanmedian(freezing_4Hz.Duracion)], [0 1], 'Color', [0.6, 0, 1], 'LineWidth', 0.5, 'LineStyle', '-');
line([nanmedian(freezing_theta.Duracion) nanmedian(freezing_theta.Duracion)], [0 1], 'Color', [0, 0, 0], 'LineWidth', 0.5, 'LineStyle', '-');

% Etiquetas y título
xlabel('Tiempo (segundos)');
ylabel('Probabilidad de Freezing');
title('Probabilidad de Freezing centrada en el inicio del evento');
legend({'4Hz', 'Theta'}, 'Location', 'Best');
hold off;

%% Excluyendo al evento de freezing de referencia
% Leer la tabla de eventos
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

% Filtrar los eventos de Freezing
freezing_events = EventsSheet(strcmp(EventsSheet.Event, 'Freezing'), :);
freezing_events = freezing_events(freezing_events.noisy == 0, :);
freezing_events = freezing_events(freezing_events.Flat < 0.1, :);
freezing_events = freezing_events(freezing_events.Epileptic < 0.1, :);

% Separar los eventos según la columna 'Enrich'
freezing_4Hz = freezing_events(strcmp(freezing_events.Enrich, '4Hz'), :);
freezing_theta = freezing_events(strcmp(freezing_events.Enrich, 'Theta'), :);

% Definir el rango de tiempo para cuantificar la probabilidad (-5s a 5s)
time_range = -5:0.5:5; % Desde -5 a 5 segundos, en intervalos de 0.5 segundos

% Inicializar matrices para almacenar los vectores de probabilidad
freezing_data_4Hz = [];
freezing_data_theta = [];

% Para cada combinación de Rat y Name, calcular la probabilidad
for rat = unique(freezing_4Hz.Rat)'
    for session = unique(freezing_4Hz.Name)'

        % Filtrar eventos por Rat y Name
        session_data_4Hz = freezing_4Hz(freezing_4Hz.Rat == rat & strcmp(freezing_4Hz.Name, session), :);
        session_data_theta = freezing_theta(freezing_theta.Rat == rat & strcmp(freezing_theta.Name, session), :);

        % Iterar sobre cada evento de freezing y calcular los vectores de freezing en el rango de -5s a +5s
        for i = 1:height(session_data_4Hz)
            event_start = session_data_4Hz.Inicio(i);
            
            % Crear un vector de ceros (sin freezing)
            event_vector_4Hz = zeros(length(time_range), 1);
            
            % Verificar si en los bins de -5s a +5s hay eventos de freezing
            for t = -5:0.5:5
                time_window_start = event_start + t - 0.25; % Desde t - 0.25s hasta t + 0.25s
                time_window_end = event_start + t + 0.25; 
                
                % Excluir el propio evento de referencia (evento i)
                overlap_4Hz = sum(session_data_4Hz.Inicio < time_window_end & session_data_4Hz.Fin > time_window_start & (session_data_4Hz.Inicio ~= event_start | session_data_4Hz.Fin ~= session_data_4Hz.Fin(i)));
                if overlap_4Hz > 0
                    event_vector_4Hz(find(time_range == t)) = 1; % Marcamos 1 si está freezando
                end
            end
            
            % Apilar el vector de freezing para 4Hz
            freezing_data_4Hz = [freezing_data_4Hz; event_vector_4Hz'];
        end

        for i = 1:height(session_data_theta)
            event_start = session_data_theta.Inicio(i);
            
            % Crear un vector de ceros (sin freezing)
            event_vector_theta = zeros(length(time_range), 1);
            
            % Verificar si en los bins de -5s a +5s hay eventos de freezing
            for t = -5:0.5:5
                time_window_start = event_start + t - 0.25; % Desde t - 0.25s hasta t + 0.25s
                time_window_end = event_start + t + 0.25; 
                
                % Excluir el propio evento de referencia (evento i)
                overlap_theta = sum(session_data_theta.Inicio < time_window_end & session_data_theta.Fin > time_window_start & (session_data_theta.Inicio ~= event_start | session_data_theta.Fin ~= session_data_theta.Fin(i)));
                if overlap_theta > 0
                    event_vector_theta(find(time_range == t)) = 1; % Marcamos 1 si está freezando
                end
            end
            
            % Apilar el vector de freezing para Theta
            freezing_data_theta = [freezing_data_theta; event_vector_theta'];
        end
    end
end

% Calcular la probabilidad de freezing
prob_4Hz = mean(freezing_data_4Hz, 1);
prob_theta = mean(freezing_data_theta, 1);

% Graficar la probabilidad para 4Hz y Theta
figure;
hold on;
plot(time_range, prob_4Hz, 'LineWidth', 2, 'Color', [0.6, 0, 1]); % Color violeta para 4Hz
plot(time_range, prob_theta, 'LineWidth', 2, 'Color', [0, 0, 0]); % Color negro para Theta

% Añadir una línea punteada en el tiempo 0
line([0 0], [0 1], 'Color', [0 0 0], 'LineWidth', 0.5, 'LineStyle', '--');
line([nanmedian(freezing_4Hz.Duracion) nanmedian(freezing_4Hz.Duracion)], [0 1], 'Color', [0.6, 0, 1], 'LineWidth', 0.5, 'LineStyle', '-');
line([nanmedian(freezing_theta.Duracion) nanmedian(freezing_theta.Duracion)], [0 1], 'Color', [0, 0, 0], 'LineWidth', 0.5, 'LineStyle', '-');

% Etiquetas y título
xlabel('Tiempo (segundos)');
ylabel('Probabilidad de Freezing');
title('Probabilidad de Freezing centrada en el inicio del evento');
legend({'4Hz', 'Theta'}, 'Location', 'Best');
hold off;

%% Cálculo de la probabilidad de freezing peri-evento independientemente de qué evento de freezing es.
clc
clearvars

% Leer la tabla de eventos
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

% Filtrar los eventos de Freezing
freezing_events = EventsSheet(strcmp(EventsSheet.Event, 'Freezing'), :);
freezing_events = freezing_events(freezing_events.noisy == 0, :);
freezing_events = freezing_events(freezing_events.Flat < 0.1, :);
freezing_events = freezing_events(freezing_events.Epileptic < 0.1, :);

% Separar los eventos según la columna 'Enrich'
freezing_4Hz = freezing_events(strcmp(freezing_events.Enrich, '4Hz'), :);
freezing_theta = freezing_events(strcmp(freezing_events.Enrich, 'Theta'), :);

% Definir el rango de tiempo para cuantificar la probabilidad (-5s a 5s)
time_range = -5:0.5:5; % Desde -5 a 5 segundos, en intervalos de 0.5 segundos

% Inicializar matrices para almacenar los vectores de probabilidad
freezing_data_ref_4Hz = [];
freezing_data_ref_theta = [];

% Para cada combinación de Rat y Name, calcular la probabilidad
for rat = unique(freezing_events.Rat)'
    for session = unique(freezing_events.Name)'

        % Filtrar eventos por Rat y Name
        session_data = freezing_events(freezing_events.Rat == rat & strcmp(freezing_events.Name, session), :);
        session_data_4Hz = freezing_4Hz(freezing_4Hz.Rat == rat & strcmp(freezing_4Hz.Name, session), :);
        session_data_theta = freezing_theta(freezing_theta.Rat == rat & strcmp(freezing_theta.Name, session), :);

        % Iterar sobre cada evento de referencia para calcular las ocurrencias de freezing
        % Caso 1: Eventos referenciados a 4Hz
        for i = 1:height(session_data_4Hz)
            event_start = session_data_4Hz.Inicio(i);

            % Crear un vector de ceros (sin freezing)
            event_vector = zeros(length(time_range), 1);

            % Verificar si hay cualquier evento de freezing en el rango de -5s a +5s
            for t = -5:0.5:5
                time_window_start = event_start + t - 0.25; % Desde t - 0.25s hasta t + 0.25s
                time_window_end = event_start + t + 0.25;

                % Verificar superposición con cualquier evento de freezing
                overlap = sum(session_data.Inicio < time_window_end & session_data.Fin > time_window_start);
                if overlap > 0
                    event_vector(find(time_range == t)) = 1; % Marcar como freezing
                end
            end

            % Apilar el vector de freezing referido a 4Hz
            freezing_data_ref_4Hz = [freezing_data_ref_4Hz; event_vector'];
        end

        % Caso 2: Eventos referenciados a Theta
        for i = 1:height(session_data_theta)
            event_start = session_data_theta.Inicio(i);

            % Crear un vector de ceros (sin freezing)
            event_vector = zeros(length(time_range), 1);

            % Verificar si hay cualquier evento de freezing en el rango de -5s a +5s
            for t = -5:0.5:5
                time_window_start = event_start + t - 0.25; % Desde t - 0.25s hasta t + 0.25s
                time_window_end = event_start + t + 0.25;

                % Verificar superposición con cualquier evento de freezing
                overlap = sum(session_data.Inicio < time_window_end & session_data.Fin > time_window_start);
                if overlap > 0
                    event_vector(find(time_range == t)) = 1; % Marcar como freezing
                end
            end

            % Apilar el vector de freezing referido a Theta
            freezing_data_ref_theta = [freezing_data_ref_theta; event_vector'];
        end
    end
end

% Calcular la probabilidad de freezing (independiente del tipo)
prob_ref_4Hz = mean(freezing_data_ref_4Hz, 1);
prob_ref_theta = mean(freezing_data_ref_theta, 1);

% Graficar la probabilidad
figure;
hold on;
plot(time_range, prob_ref_4Hz, 'LineWidth', 2, 'Color', [0.6, 0, 1]); % Color violeta para referencia 4Hz
plot(time_range, prob_ref_theta, 'LineWidth', 2, 'Color', [0, 0, 0]); % Color negro para referencia Theta

% Añadir una línea punteada en el tiempo 0
line([0 0], [0 1], 'Color', [0 0 0], 'LineWidth', 0.5, 'LineStyle', '--');

% Etiquetas y título
xlabel('Tiempo (segundos)');
ylabel('Probabilidad de Freezing');
title('Probabilidad de Freezing peri-evento (independiente del tipo)');
legend({'Referencia 4Hz', 'Referencia Theta'}, 'Location', 'Best');
hold off;

%% Cálculo de la probabilidad de freezing peri-evento independientemente de qué evento de freezing es
% Tomando 900 eventos al azar de cada tipo
clc
clearvars

% Leer la tabla de eventos
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

% Filtrar los eventos de Freezing
freezing_events = EventsSheet(strcmp(EventsSheet.Event, 'Freezing'), :);
freezing_events = freezing_events(freezing_events.noisy == 0, :);
freezing_events = freezing_events(freezing_events.Flat < 0.1, :);
freezing_events = freezing_events(freezing_events.Epileptic < 0.1, :);

% Separar los eventos según la columna 'Enrich'
freezing_4Hz = freezing_events(strcmp(freezing_events.Enrich, '4Hz'), :);
freezing_theta = freezing_events(strcmp(freezing_events.Enrich, 'Theta'), :);

% Tomar al azar 900 eventos de cada tipo
if height(freezing_4Hz) > 900
    freezing_4Hz = freezing_4Hz(randperm(height(freezing_4Hz), 900), :);
end
if height(freezing_theta) > 900
    freezing_theta = freezing_theta(randperm(height(freezing_theta), 900), :);
end

% Definir el rango de tiempo para cuantificar la probabilidad (-5s a 5s)
time_range = -5:0.5:5; % Desde -5 a 5 segundos, en intervalos de 0.5 segundos

% Inicializar matrices para almacenar los vectores de probabilidad
freezing_data_ref_4Hz = [];
freezing_data_ref_theta = [];

% Para cada combinación de Rat y Name, calcular la probabilidad
for rat = unique(freezing_events.Rat)'
    for session = unique(freezing_events.Name)'

        % Filtrar eventos por Rat y Name
        session_data = freezing_events(freezing_events.Rat == rat & strcmp(freezing_events.Name, session), :);
        session_data_4Hz = freezing_4Hz(freezing_4Hz.Rat == rat & strcmp(freezing_4Hz.Name, session), :);
        session_data_theta = freezing_theta(freezing_theta.Rat == rat & strcmp(freezing_theta.Name, session), :);

        % Iterar sobre cada evento de referencia para calcular las ocurrencias de freezing
        % Caso 1: Eventos referenciados a 4Hz
        for i = 1:height(session_data_4Hz)
            event_start = session_data_4Hz.Inicio(i);

            % Crear un vector de ceros (sin freezing)
            event_vector = zeros(length(time_range), 1);

            % Verificar si hay cualquier evento de freezing en el rango de -5s a +5s
            for t = -5:0.5:5
                time_window_start = event_start + t - 0.25; % Desde t - 0.25s hasta t + 0.25s
                time_window_end = event_start + t + 0.25;

                % Verificar superposición con cualquier evento de freezing
                overlap = sum(session_data.Inicio < time_window_end & session_data.Fin > time_window_start);
                if overlap > 0
                    event_vector(find(time_range == t)) = 1; % Marcar como freezing
                end
            end

            % Apilar el vector de freezing referido a 4Hz
            freezing_data_ref_4Hz = [freezing_data_ref_4Hz; event_vector'];
        end

        % Caso 2: Eventos referenciados a Theta
        for i = 1:height(session_data_theta)
            event_start = session_data_theta.Inicio(i);

            % Crear un vector de ceros (sin freezing)
            event_vector = zeros(length(time_range), 1);

            % Verificar si hay cualquier evento de freezing en el rango de -5s a +5s
            for t = -5:0.5:5
                time_window_start = event_start + t - 0.25; % Desde t - 0.25s hasta t + 0.25s
                time_window_end = event_start + t + 0.25;

                % Verificar superposición con cualquier evento de freezing
                overlap = sum(session_data.Inicio < time_window_end & session_data.Fin > time_window_start);
                if overlap > 0
                    event_vector(find(time_range == t)) = 1; % Marcar como freezing
                end
            end

            % Apilar el vector de freezing referido a Theta
            freezing_data_ref_theta = [freezing_data_ref_theta; event_vector'];
        end
    end
end

% Calcular la probabilidad de freezing (independiente del tipo)
prob_ref_4Hz = mean(freezing_data_ref_4Hz, 1);
prob_ref_theta = mean(freezing_data_ref_theta, 1);

% Graficar la probabilidad
figure;
hold on;
plot(time_range, prob_ref_4Hz, 'LineWidth', 2, 'Color', [0.6, 0, 1]); % Color violeta para referencia 4Hz
plot(time_range, prob_ref_theta, 'LineWidth', 2, 'Color', [0, 0, 0]); % Color negro para referencia Theta

% Añadir una línea punteada en el tiempo 0
line([0 0], [0 1], 'Color', [0 0 0], 'LineWidth', 0.5, 'LineStyle', '--');

% Etiquetas y título
xlabel('Tiempo (segundos)');
ylabel('Probabilidad de Freezing');
title('Probabilidad de Freezing peri-evento (independiente del tipo)');
legend({'Referencia 4Hz', 'Referencia Theta'}, 'Location', 'Best');
hold off;

