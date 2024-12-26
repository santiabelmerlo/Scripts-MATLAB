function plot_GCf(data,lam,lim_x)
    %   Función para plotear Granger Causality en el dominio de las frecuencias
    %   Uso: plot_GCf(data,lam,lim_x)
    %        plot_GCf(ff_CS1,lam,[1,100])
    %   Donde: data es la matriz ff de 4 dimensiones, lam es el vector de
    %   frecuencias y lim_x son los límites en x para el ploteo.
    %   Me genera 3 subplots para las 3 combinaciones de BLA, PL e IL
    
    figure();
    
    BLA_color = [66,133,244]/255;
    PL_color = [234,67,53]/255;
    IL_color = [251,188,5]/255;

    % Ploteamos la causalidad entre BLA y PL
    subplot(131);
    x = lam;
    % Plot 1
    y = (smooth(median(squeeze(data(2,1,:,:)),2),1))';
    stdem = (smooth(mad(squeeze(data(2,1,:,:)),1,2)/sqrt(size(squeeze(data(2,1,:,:)),2)),1))';
    curve1 = y + stdem;
    curve2 = y - stdem;
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
    p1 = fill(x2, inBetween,BLA_color,'LineStyle','none');
    set(p1,'facealpha',.3); hold on;
    p2 = plot(x, y, 'Color',BLA_color, 'LineWidth', 1); hold on;
    % Plot 2
    y = (smooth(median(squeeze(data(1,2,:,:)),2),1))';
    stdem = (smooth(mad(squeeze(data(1,2,:,:)),1,2)/sqrt(size(squeeze(data(1,2,:,:)),2)),1))';
    curve1 = y + stdem;
    curve2 = y - stdem;
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
    p3 = fill(x2, inBetween,PL_color,'LineStyle','none');
    set(p3,'facealpha',.3); hold on;
    p4 = plot(x, y, 'Color',PL_color, 'LineWidth', 1); hold on;
    % Seteamos algunas cosas del gráfico
    xlim(lim_x);
%     ylim([0 0.5]);
    legend([p1 p3],{'BLA to PL','PL to BLA'});
    ylabel('Granger Causality');
    xlabel('Frequency (Hz)');

    % Ploteamos la causalidad entre BLA y IL
    subplot(132);
    x = lam;
    % Plot 1
    y = (smooth(median(squeeze(data(3,1,:,:)),2),1))';
    stdem = (smooth(mad(squeeze(data(3,1,:,:)),1,2)/sqrt(size(squeeze(data(3,1,:,:)),2)),1))';
    curve1 = y + stdem;
    curve2 = y - stdem;
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
    p1 = fill(x2, inBetween,BLA_color,'LineStyle','none');
    set(p1,'facealpha',.3); hold on;
    p2 = plot(x, y, 'Color',BLA_color, 'LineWidth', 1); hold on;
    % Plot 2
    y = (smooth(median(squeeze(data(1,3,:,:)),2),1))';
    stdem = (smooth(mad(squeeze(data(1,3,:,:)),1,2)/sqrt(size(squeeze(data(1,3,:,:)),2)),1))';
    curve1 = y + stdem;
    curve2 = y - stdem;
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
    p3 = fill(x2, inBetween,IL_color,'LineStyle','none');
    set(p3,'facealpha',.3); hold on;
    p4 = plot(x, y, 'Color',IL_color, 'LineWidth', 1); hold on;
    % Seteamos algunas cosas del gráfico
    xlim(lim_x);
%     ylim([0 0.5]);
    legend([p1 p3],{'BLA to IL','IL to BLA'});
    ylabel('Granger Causality');
    xlabel('Frequency (Hz)');

    % Ploteamos la causalidad entre PL y IL
    subplot(133);
    x = lam;
    % Plot 1
    y = (smooth(median(squeeze(data(3,2,:,:)),2),1))';
    stdem = (smooth(mad(squeeze(data(3,2,:,:)),1,2)/sqrt(size(squeeze(data(3,2,:,:)),2)),1))';
    curve1 = y + stdem;
    curve2 = y - stdem;
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
    p1 = fill(x2, inBetween,PL_color,'LineStyle','none');
    set(p1,'facealpha',.3); hold on;
    p2 = plot(x, y, 'Color',PL_color, 'LineWidth', 1); hold on;
    % Plot 2
    y = (smooth(median(squeeze(data(2,3,:,:)),2),1))';
    stdem = (smooth(mad(squeeze(data(2,3,:,:)),1,2)/sqrt(size(squeeze(data(2,3,:,:)),2)),1))';
    curve1 = y + stdem;
    curve2 = y - stdem;
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
    p3 = fill(x2, inBetween,IL_color,'LineStyle','none');
    set(p3,'facealpha',.3); hold on;
    p4 = plot(x, y, 'Color',IL_color, 'LineWidth', 1); hold on;
    % Seteamos algunas cosas del gráfico
    xlim(lim_x);
%     ylim([0 0.5]);
    legend([p1 p3],{'PL to IL','IL to PL'});
    ylabel('Granger Causality');
    xlabel('Frequency (Hz)');

    set(gcf, 'Color', 'white');
    set(gcf, 'Position', [400, 400, 900, 250]);

return