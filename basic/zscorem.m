function [z, medianX, madX] = zscorem(x, dim)
    %ZSCOREM Puntaje Z utilizando mediana y MAD.
    %   Z = ZSCOREM(X) devuelve una versi�n centrada y escalada de X del mismo
    %   tama�o que X. Para el vector X, Z es el vector de puntajes Z 
    %   (X - MEDIANA(X)) ./ MAD(X). Para la matriz X, los puntajes Z se 
    %   calculan usando la mediana y la MAD a lo largo de cada columna de X.
    %   Para matrices de dimensiones superiores, los puntajes Z se calculan
    %   usando la mediana y la MAD a lo largo de la primera dimensi�n no
    %   singleton.
    %
    %   [Z, MEDIANX, MADX] = ZSCOREM(X) tambi�n devuelve MEDIANA(X) en MEDIANX
    %   y MAD(X) en MADX.
    %
    %   [...] = ZSCOREM(X, DIM) estandariza X trabajando a lo largo de la
    %   dimensi�n DIM de X.
    %
    %   Ver tambi�n MEDIAN.

    % [] es un caso especial para la mediana y la mad, simplemente se maneja aqu�.
    if isequal(x, []), z = x; return; end

    if nargin < 2
        % Determinar a lo largo de qu� dimensi�n trabajar.
        dim = find(size(x) ~= 1, 1);
        if isempty(dim), dim = 1; end
    end

    % Calcular la mediana y la MAD de X.
    medianX = median(x, dim);

    % Calcular la MAD manualmente.
    absDeviation = bsxfun(@minus, x, medianX);
    absDeviation = abs(absDeviation);
    madX = median(absDeviation, dim);
    
    % Reemplazar MADs cero con unos para evitar divisi�n por cero.
    madX(madX == 0) = 1;

    % Calcular el puntaje Z.
    z = bsxfun(@minus, x, medianX);
    z = bsxfun(@rdivide, z, madX);
end
