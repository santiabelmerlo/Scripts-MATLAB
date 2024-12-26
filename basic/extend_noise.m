function extended_noise = extend_noise(noise,seg,Fs);    
    % Función para extender el vector de ruido una cierta cantidad de
    % posiciones hacia adelante y hacia atras. 
    % noise: vector lógico de los momentos de ruido en la señal
    % seg: cuantos segundos quiero extender el ruido, hacia adelante y hacia atras
    % Fs: frecuencia de sampleo
    % Uso: extend_noise(noise_BLA, 1, 1250);
    n = seg*Fs;  % Change this to whatever value you need
    % Create the convolution kernel
    kernel = ones(1, 2*n + 1);
    % Convolve the logical vector with the kernel
    extended_noise = conv(double(noise), kernel, 'same') > 0;
    % Convert back to logical if needed
    extended_noise = logical(extended_noise);
end