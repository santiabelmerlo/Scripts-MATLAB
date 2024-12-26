function [data_nan, time_nan, idx_start_end, seg_logical] = segmentador(data_points, n_points, data, time_data)
% segment(data_points, n_points, tiempo_data)
% Ej: [data_nan, tiempo_nan, idx_start_end, seg_logical] = segment(data_points, n_points, tiempo_data)
%
% Compara si los data points de inicio y fin de cada segmento estan
% incluidos en el intervalo n_points. 
%
% INPUTS:
% data_points: datos a verificar (vector fila 2xn)
% n_points: intervalo de verificacion de los data_points (vector columna mx2)
% data: datos asociados a los n_points
% time_data: vector de tiempo de n_points/data (vector columna mx2
% 
% OUTPUTS:
% data_nan: vector data con NaN en los intervalos no comprendidos por los data_points
% time_nan: vector de tiempo correspondiente a data_nan
% idx_start_end: vector con los inicios (col 1) y fin (col 2) de los segmentos
% seg_logical: vector logico de largo data_nan
%

%%

data_points = data_points';
idx_quiet = (ismember((data_points),n_points));


%V1 son los idx de inicio de los seg
%V2 son los idx de fin de los seg.
%--- Combinaciones de V1,V2
% -- numel(V1) = numel(V2) --> El seg esta contenido en el intervalo O faltan los extremos de los seg de inicio y fin
% -- numel(V1) != numel(V2) --> Hay un seg que no tiene inicio o no tiene fin dentro del intervalo

V1 = data_points(idx_quiet(:,1),1);
V2 = data_points(idx_quiet(:,2),2);

if isempty(V1) && isempty(V2)
    V1 = 0; V2 = 0;
elseif isempty(V2)
    V2 = n_points(end);
elseif isempty(V1)
    V1 = n_points(1);
end

if numel(V1) == numel(V2) %misma cant de puntos de inicio y fin
    if V1(1) > V2(1) %el primer segmento no tiene inicio en el intervalo
        if V1(end)> V2(end)%rechequeo. El ult segmento no fin en el intervalo
            IND = zeros(max([numel(V1),numel(V2)])+1,2);
            IND(1,1)          = n_points(1);
            IND(2:end,1)      = V1;
            IND(1:end-1,2)    = V2;
            IND(end,2)        = n_points(end);
        else
            warning('Error en la determinación de los segmentos para igual cantindad de puntos de inicio y fin!.')
            return
        end
    elseif all(V2 >= V1) %todos los fin de seg son mayores que los inicio de segmentos
        IND = zeros(max([numel(V1),numel(V2)]),2);
        IND(:,1)          = V1;
        IND(:,2)          = V2;
    else
        warning('Error en la determinación de los segmentos para igual cantindad de puntos de inicio y fin!.')
        return
    end
    
else %diferente cant de puntos de inicio y fin.
    IND = zeros(max([length(V1),length(V2)]),2);
     if V1(1) > V2(1) %falta el inicio del primer segmento
        IND(1,1)          = n_points(1);
        IND(2:end,1)      = V1;
        IND(:,2)          = V2;
    elseif V1(end) > V2(end) %falta el fin del ultimo segmento
        IND(:,1)          = V1;
        IND(1:end-1,2)    = V2;
        IND(end,2)        = n_points(end);
    elseif V1(1) == V2(1) %redundante. no puede ocurrir
        IND(:,1)          = V1;
        IND(:,2)          = V2;
    end
end


seg = zeros(length(n_points),1);
idx_start_end = IND;
    
%verifico si habia algun segmento contenido o no
if IND(1,1) == IND(1,2) % solo hay un punto
    data_nan = data;
    data_nan(:) = nan;
    
    time_nan = time_data;
    seg_logical = logical(seg);
    
else
    
    seg = zeros(length(n_points),1);
    for II = 1 : size(IND,1)
        seg((IND(II,1):IND(II,2))-n_points(1)+1)=1;
    end

    seg_logical = logical(seg);
    
    data_nan = data;
    data_nan(~seg) = nan;
    
    time_nan = time_data;
    time_nan(~seg) = nan;
end

