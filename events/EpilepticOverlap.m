%% Cargamos ambas planillas y agregamos una columna a EventsSheet.csv que diga que porcentaje del evento est� contaminado por un evento epil�ptico
clc
clear all

cd('D:\Doctorado\Analisis\Sheets');

EpilepticSheet = readtable('EpilepticSheet.csv');
EventsSheet = readtable('EventsSheet.csv');

% Crear la nueva columna Epileptic inicializada en 0
EventsSheet.Epileptic = zeros(height(EventsSheet), 1);

% Iterar sobre cada evento de EventsSheet
for i = 1:height(EventsSheet)
    
    disp(['Analizando evento: ' num2str(i)]);
    
    % Obtener inicio y fin del evento en EventsSheet
    inicio_event = EventsSheet.Inicio(i);
    fin_event = EventsSheet.Fin(i);
    duracion_event = fin_event - inicio_event; % Duraci�n del evento
    
    % Inicializar el tiempo contaminado
    tiempo_contaminado = 0;
    
    % Obtener Rat y Session del evento actual
    rat_actual = EventsSheet.Rat(i);
    session_actual = EventsSheet.Session{i};
    
    % Iterar sobre cada evento de EpilepticSheet para verificar contaminaci�n
    for j = 1:height(EpilepticSheet)
        % Obtener inicio y fin del evento en EpilepticSheet
        inicio_epileptic = EpilepticSheet.Inicio(j);
        fin_epileptic = EpilepticSheet.Fin(j);
        
        % Comparar Rat y Session
        rat_epileptic = EpilepticSheet.Rat(j);
        session_epileptic = EpilepticSheet.Session{j};
        
        % Solo considerar eventos si Rat y Session coinciden
        if rat_actual == rat_epileptic && strcmp(session_actual, session_epileptic)
            % Condiciones para solapamiento:
            % 1. El evento epil�ptico est� completamente dentro del evento
            if inicio_epileptic >= inicio_event && fin_epileptic <= fin_event
                tiempo_contaminado = tiempo_contaminado + (fin_epileptic - inicio_epileptic);
            
            % 2. El evento epil�ptico empieza dentro pero termina fuera del evento
            elseif inicio_epileptic >= inicio_event && inicio_epileptic < fin_event && fin_epileptic > fin_event
                tiempo_contaminado = tiempo_contaminado + (fin_event - inicio_epileptic);
            
            % 3. El evento epil�ptico empieza antes y termina dentro del evento
            elseif inicio_epileptic < inicio_event && fin_epileptic > inicio_event && fin_epileptic <= fin_event
                tiempo_contaminado = tiempo_contaminado + (fin_epileptic - inicio_event);
            
            % 4. El evento epil�ptico cubre completamente el evento
            elseif inicio_epileptic < inicio_event && fin_epileptic > fin_event
                tiempo_contaminado = tiempo_contaminado + (fin_event - inicio_event);
            end
        end
    end
    
    % Calcular el porcentaje de contaminaci�n, asegurarse de evitar divisiones por cero
    if duracion_event > 0
        EventsSheet.Epileptic(i) = round((tiempo_contaminado / duracion_event) * 100,2);
        disp(['Evento: ' num2str(i) ', Tiempo contaminado: ' num2str(tiempo_contaminado) ', Porcentaje: ' num2str(EventsSheet.Epileptic(i))]);
    else
        EventsSheet.Epileptic(i) = 0; % Si la duraci�n del evento es 0
    end
end

cd('D:\Doctorado\Analisis\Sheets');
writetable(EventsSheet, 'EventsSheet2.csv'); % Guardamos la tabla
