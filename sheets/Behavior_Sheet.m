%% Behavior_Sheet
% Script para calcular el porcentaje de freezing y movement en cada evento

clc
clear all

% Cargamos la tabla de EventsSheet
cd('D:\Doctorado\Analisis\Sheets');
DataTable = readtable('EventsSheet.csv');

% Initialize an empty table for storing results
Behavior_Sheet = table;

% Get unique events and their associated IDs, Rats, and Sessions
uniqueEvents = unique(DataTable.ID);

% Loop through each unique ID (event)
for i = 1:length(uniqueEvents)
    
    disp(['Processing event n° ' num2str(i)]);
    
    % Extract the current event's row
    currentEvent = DataTable(DataTable.ID == uniqueEvents(i), :);
    
    % Get the associated Rat and Session for this event
    currentRat = currentEvent.Rat(1);
    currentSession = currentEvent.Session(1);
    
    % Find overlapping Freezing and Movement events for the same Rat and Session
    freezingEvents = DataTable(strcmp(DataTable.Event, 'Freezing') & ...
                               DataTable.Rat == currentRat & ...
                               strcmp(DataTable.Session, currentSession), :);
    movementEvents = DataTable(strcmp(DataTable.Event, 'Movement') & ...
                               DataTable.Rat == currentRat & ...
                               strcmp(DataTable.Session, currentSession), :);
    
    % Calculate total time of the current event
    eventDuration = currentEvent.Fin - currentEvent.Inicio;
    
    % Calculate overlapping time with Freezing events
    freezingTime = 0;
    for j = 1:height(freezingEvents)
        overlap = max(0, min(currentEvent.Fin, freezingEvents.Fin(j)) - ...
                         max(currentEvent.Inicio, freezingEvents.Inicio(j)));
        freezingTime = freezingTime + overlap;
    end
    
    % Calculate overlapping time with Movement events
    movementTime = 0;
    for j = 1:height(movementEvents)
        overlap = max(0, min(currentEvent.Fin, movementEvents.Fin(j)) - ...
                         max(currentEvent.Inicio, movementEvents.Inicio(j)));
        movementTime = movementTime + overlap;
    end
    
    % Calculate percentages for Freezing and Movement
    freezingPercentage = (freezingTime / eventDuration) * 100;
    movementPercentage = (movementTime / eventDuration) * 100;
    
    % Add results to the Behavior_Sheet
    newRow = table(currentEvent.ID(1), freezingPercentage, movementPercentage, ...
                   'VariableNames', {'ID', 'Freezing', 'Movement'});
    Behavior_Sheet = [Behavior_Sheet; newRow];
end

% Display the final Behavior_Sheet
disp(Behavior_Sheet);

% Save the table
writetable(Behavior_Sheet, 'Behavior_Sheet.csv');

disp('Ready!');
