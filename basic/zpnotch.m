function lfp_filt = zpnotch(lfp, Fs, F0, Q)
    % zpnotch Aplica un filtro notch a la se�al con cero distorsi�n de fase.
    %
    %   se�al_filtrada = aplicarFiltroNotch(se�al, Fs, F0, Q) 
    %   aplica un filtro notch a la se�al de entrada 'se�al' para eliminar
    %   la frecuencia 'F0' con un factor de calidad 'Q'. 'Fs' es la frecuencia 
    %   de muestreo de la se�al.
    %
    %   Par�metros de entrada:
    %       - lfp: Vector con la se�al de entrada.
    %       - Fs: Frecuencia de muestreo (Hz).
    %       - F0: Frecuencia a eliminar (Hz).
    %       - Q: Factor de calidad del filtro.
    %
    %   Par�metro de salida:
    %       - se�al_filtrada: Se�al filtrada sin distorsi�n de fase.
    % 
    %   Uso: lfp_filt = zpnotch(lfp, 1250, 100, 30);

    % Dise�o del filtro notch
    [b, a] = iirnotch(F0/(Fs/2), F0/(Fs/2)/Q);

    % Aplicar el filtro notch con filtfilt (cero distorsi�n de fase)
    lfp_filt = filtfilt(b, a, lfp);
end
