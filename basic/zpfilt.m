function [lfp] = zpfilt(data,Fs,hp,lp)
    % Filtro con zero-phase distortion. Usa filtfilt y lo hace para un pasa
    % altos y para un pasabajos
    % Uso: [lfp] = zpfilt(data,SamplingFreq,highpass,lowpass);
    % Uso: [lfp] = zpfilt(data,1250,0.1,300);
    highpass = hp; lowpass = lp; % Frecuencias de corte del filtro.
    samplePeriod = 1/Fs; % Frecuencia de muestreo de la señal
    % Aplicamos un filtro pasa altos con corte en 0.1 Hz
    filtHPF = (2*highpass)/(1/samplePeriod);
    [b, a] = butter(4, filtHPF, 'high');
    data_hp = filtfilt(b, a, data);
    % Aplicamos un filtro pasa bajos con corte en 300 Hz
    filtLPF = (2*lowpass)/(1/samplePeriod);
    [b, a] = butter(4, filtLPF, 'low');
    data_hlp = filtfilt(b, a, data_hp); %señal de mag de acel filtrada
    lfp = data_hlp; % Guardamos la señal filtrada como lfp
end