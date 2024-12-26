function [plv] = plv(lfp1,lfp2,Fs,range) 
% Filtramos en el rango de interes
lfp1 = zpfilt(lfp1,Fs,range(1),range(2));
lfp2 = zpfilt(lfp2,Fs,range(1),range(2));
% Aplicamos hilbert y nos quedamos con la fase
phase_sig1 = angle(hilbert(lfp1));
phase_sig2 = angle(hilbert(lfp2));
% Computamos el PLV
e = exp(1i*(phase_sig1 - phase_sig2));
plv = abs(sum(e,2));
end
