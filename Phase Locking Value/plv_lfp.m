function [plv] = plv_lfp(lfp1,lfp2)
    lfp2 = lfp2(~isnan(lfp1));
    lfp1 = lfp1(~isnan(lfp1));
    % Aplicamos hilbert y nos quedamos con la fase
    phase_sig1 = angle(hilbert(lfp1));
    phase_sig2 = angle(hilbert(lfp2));
    % Computamos el PLV
    e = exp(1i*(phase_sig1 - phase_sig2));
    plv = abs(sum(e,2))/size(e,2);
end
