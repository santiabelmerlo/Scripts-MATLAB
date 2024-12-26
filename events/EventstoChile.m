%% Script para filtrar la tabla de eventos para enviar al colaborador en Chile
clc
clear all

% Seteamos algunos parámetros para filtrar los datos
Event = {'CS1';'CS2';'Freezing';'Movement'};
Rat = [11,12,13,17,18,19,20];
Session = {'EXT1';'EXT2'};

% Cargamos datos de los sheets
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

% Filtramos la tabla de EventsSheet (filtro general para eventos, ratas y sesiones)
EventsSheet = EventsSheet(ismember(EventsSheet.Event, Event), :);
EventsSheet = EventsSheet(ismember(EventsSheet.Rat, Rat), :);
EventsSheet = EventsSheet(ismember(EventsSheet.Session, Session), :);

% Identificamos las filas de Freezing y Movement
isFreezingOrMovement = ismember(EventsSheet.Event, {'Freezing', 'Movement'});

% Filtramos las filas relevantes con las condiciones adicionales
filteredRows = isFreezingOrMovement & ...
               (EventsSheet.noisy == 0) & ...
               (EventsSheet.Epileptic <= 1) & ...
               (EventsSheet.Flat <= 1);

% Creamos una nueva tabla que combina las filas filtradas y las no filtradas
EventsSheet = [EventsSheet(~isFreezingOrMovement, :); EventsSheet(filteredRows, :)];

% Eliminamos algunas columnas
EventsSheet.noisy = []; % Elimina la columna 'noisy'
EventsSheet.Epileptic = [];
EventsSheet.Flat = [];

cd('C:\Users\santi\Desktop');
writetable(EventsSheet, 'Events.csv');
