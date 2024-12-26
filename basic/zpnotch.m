function lfp_filt = zpnotch(lfp, Fs, F0, Q)
    % zpnotch Aplica un filtro notch a la señal con cero distorsión de fase.
    %
    %   señal_filtrada = aplicarFiltroNotch(señal, Fs, F0, Q) 
    %   aplica un filtro notch a la señal de entrada 'señal' para eliminar
    %   la frecuencia 'F0' con un factor de calidad 'Q'. 'Fs' es la frecuencia 
    %   de muestreo de la señal.
    %
    %   Parámetros de entrada:
    %       - lfp: Vector con la señal de entrada.
    %       - Fs: Frecuencia de muestreo (Hz).
    %       - F0: Frecuencia a eliminar (Hz).
    %       - Q: Factor de calidad del filtro.
    %
    %   Parámetro de salida:
    %       - señal_filtrada: Señal filtrada sin distorsión de fase.
    % 
    %   Uso: lfp_filt = zpnotch(lfp, 1250, 100, 30);

    % Diseño del filtro notch
    [b, a] = iirnotch(F0/(Fs/2), F0/(Fs/2)/Q);

    % Aplicar el filtro notch con filtfilt (cero distorsión de fase)
    lfp_filt = filtfilt(b, a, lfp);
end
