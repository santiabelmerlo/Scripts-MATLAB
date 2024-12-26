%% Agregar la columna noisy al archivo EventsSheet.csv
clc
clear all

cd('D:\Doctorado\Analisis\Sheets')
EventsSheet = readtable('EventsSheet.csv');
MVGC_Sheet = readtable('MVGC_Sheet.csv');

EventsSheet.noisy = MVGC_Sheet.noisy;
writetable(EventsSheet, 'EventsSheet.csv');

%% Add FreezingPre, FreezingPost, FreezingOnset, FreezingOffset, CS1Onset, CS1Offset, CS2Onset, CS2Offset
clc
clear all

cd('D:\Doctorado\Analisis\Sheets')
EventsSheet = readtable('EventsSheet.csv');

% Create copies of Freezing and Movement events
freezing_indices = strcmp(EventsSheet.Event, 'Freezing');
movement_indices = strcmp(EventsSheet.Event, 'Movement');
cs1_indices = strcmp(EventsSheet.Event, 'CS1');
cs2_indices = strcmp(EventsSheet.Event, 'CS2');

% Extract freezing, movement, CS1, and CS2 events
freezing_events = EventsSheet(freezing_indices, :);
movement_events = EventsSheet(movement_indices, :);
cs1_events = EventsSheet(cs1_indices, :);
cs2_events = EventsSheet(cs2_indices, :);

% Initialize empty tables to hold the new events
new_events = table();

% Get the last ID from the original EventsSheet
last_id = max(EventsSheet.ID);

% Process freezing events
for i = 1:height(freezing_events)
    % Get the original event
    original_event = freezing_events(i, :);
    
    % FreezingPre: 3 seconds before freezing starts
    FreezingPre = original_event; % Copy the original event
    FreezingPre.Event = {'FreezingPre'}; % Change the event type
    FreezingPre.Inicio = original_event.Inicio - 3; % Adjust the start time
    FreezingPre.Fin = original_event.Inicio; % Adjust the end time
    FreezingPre.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    FreezingPre.ID = last_id; % Assign new ID

    % FreezingPost: 3 seconds after freezing ends
    FreezingPost = original_event; % Copy the original event
    FreezingPost.Event = {'FreezingPost'}; % Change the event type
    FreezingPost.Inicio = original_event.Fin; % Adjust the start time
    FreezingPost.Fin = original_event.Fin + 3; % Adjust the end time
    FreezingPost.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    FreezingPost.ID = last_id; % Assign new ID

    % FreezingOnset: first 3 seconds of freezing
    FreezingOnset = original_event; % Copy the original event
    FreezingOnset.Event = {'FreezingOnset'}; % Change the event type
    FreezingOnset.Inicio = original_event.Inicio; % Set start time
    FreezingOnset.Fin = original_event.Inicio + 3; % Adjust the end time
    FreezingOnset.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    FreezingOnset.ID = last_id; % Assign new ID

    % FreezingOffset: last 3 seconds before freezing ends
    FreezingOffset = original_event; % Copy the original event
    FreezingOffset.Event = {'FreezingOffset'}; % Change the event type
    FreezingOffset.Inicio = original_event.Fin - 3; % Adjust the start time
    FreezingOffset.Fin = original_event.Fin; % Adjust the end time
    FreezingOffset.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    FreezingOffset.ID = last_id; % Assign new ID

    % Append to new events
    new_events = [new_events; FreezingPre; FreezingPost; FreezingOnset; FreezingOffset]; %#ok<AGROW>
end

% Process movement events
for i = 1:height(movement_events)
    % Get the original event
    original_event = movement_events(i, :);
    
    % MovementPre: 3 seconds before movement starts
    MovementPre = original_event; % Copy the original event
    MovementPre.Event = {'MovementPre'}; % Change the event type
    MovementPre.Inicio = original_event.Inicio - 3; % Adjust the start time
    MovementPre.Fin = original_event.Inicio; % Adjust the end time
    MovementPre.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    MovementPre.ID = last_id; % Assign new ID

    % MovementPost: 3 seconds after movement ends
    MovementPost = original_event; % Copy the original event
    MovementPost.Event = {'MovementPost'}; % Change the event type
    MovementPost.Inicio = original_event.Fin; % Adjust the start time
    MovementPost.Fin = original_event.Fin + 3; % Adjust the end time
    MovementPost.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    MovementPost.ID = last_id; % Assign new ID

    % MovementOnset: first 3 seconds of movement
    MovementOnset = original_event; % Copy the original event
    MovementOnset.Event = {'MovementOnset'}; % Change the event type
    MovementOnset.Inicio = original_event.Inicio; % Set start time
    MovementOnset.Fin = original_event.Inicio + 3; % Adjust the end time
    MovementOnset.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    MovementOnset.ID = last_id; % Assign new ID

    % MovementOffset: last 3 seconds before movement ends
    MovementOffset = original_event; % Copy the original event
    MovementOffset.Event = {'MovementOffset'}; % Change the event type
    MovementOffset.Inicio = original_event.Fin - 3; % Adjust the start time
    MovementOffset.Fin = original_event.Fin; % Adjust the end time
    MovementOffset.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    MovementOffset.ID = last_id; % Assign new ID

    % Append to new events
    new_events = [new_events; MovementPre; MovementPost; MovementOnset; MovementOffset];
end

% Process CS1 events
for i = 1:height(cs1_events)
    % Get the original event
    original_event = cs1_events(i, :);
    
    % CS1Onset: first 3 seconds of CS1
    CS1Onset = original_event; % Copy the original event
    CS1Onset.Event = {'CS1Onset'}; % Change the event type
    CS1Onset.Inicio = original_event.Inicio; % Set start time
    CS1Onset.Fin = original_event.Inicio + 3; % Adjust the end time
    CS1Onset.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    CS1Onset.ID = last_id; % Assign new ID

    % CS1Offset: last 3 seconds before CS1 ends
    CS1Offset = original_event; % Copy the original event
    CS1Offset.Event = {'CS1Offset'}; % Change the event type
    CS1Offset.Inicio = original_event.Fin - 3; % Adjust the start time
    CS1Offset.Fin = original_event.Fin; % Adjust the end time
    CS1Offset.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    CS1Offset.ID = last_id; % Assign new ID

    % Append to new events
    new_events = [new_events; CS1Onset; CS1Offset];
end

% Process CS2 events
for i = 1:height(cs2_events)
    % Get the original event
    original_event = cs2_events(i, :);
    
    % CS2Onset: first 3 seconds of CS2
    CS2Onset = original_event; % Copy the original event
    CS2Onset.Event = {'CS2Onset'}; % Change the event type
    CS2Onset.Inicio = original_event.Inicio; % Set start time
    CS2Onset.Fin = original_event.Inicio + 3; % Adjust the end time
    CS2Onset.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    CS2Onset.ID = last_id; % Assign new ID

    % CS2Offset: last 3 seconds before CS2 ends
    CS2Offset = original_event; % Copy the original event
    CS2Offset.Event = {'CS2Offset'}; % Change the event type
    CS2Offset.Inicio = original_event.Fin - 3; % Adjust the start time
    CS2Offset.Fin = original_event.Fin; % Adjust the end time
    CS2Offset.Duracion = 3; % Set duration
    last_id = last_id + 1; % Increment ID
    CS2Offset.ID = last_id; % Assign new ID

    % Append to new events
    new_events = [new_events; CS2Onset; CS2Offset];
end

% Append the new events to the original events table
all_events = [EventsSheet; new_events];

% Save the new events to a new CSV file
writetable(all_events, 'EventsSheet3.csv');
