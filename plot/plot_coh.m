function plot_coh(C1,C2,C3,C4,f,freq,color)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Calculamos los limites en el eje tiempo y en eje frecuencias
    
%     t1 = 41; t2 = 160; % Tiempos de inicio y fin del tono
    t1 = 41; t2 = 51; % Tiempos de inicio y fin del freezing
    
    % 4-Hz Oscilación
    if freq == 1
        flegend = '4-Hz';
        fmin = 2; fmax= 5.3;
        f1 = find(abs(f-fmin) == min(abs(f-fmin)));
        f2 = find(abs(f-fmax) == min(abs(f-fmax)));
    end
    % Theta
    if freq == 2
        flegend = 'Theta';
        fmin = 5.3; fmax= 9.6;
        f1 = find(abs(f-fmin) == min(abs(f-fmin)));
        f2 = find(abs(f-fmax) == min(abs(f-fmax)));
    end
    % Beta
    if freq == 3
        flegend = 'Beta';
        fmin = 13; fmax= 30;
        f1 = find(abs(f-fmin) == min(abs(f-fmin)));
        f2 = find(abs(f-fmax) == min(abs(f-fmax)));
    end
    % sGamma
    if freq == 4
        flegend = 'sGamma';
        fmin = 43; fmax= 60;
        f1 = find(abs(f-fmin) == min(abs(f-fmin)));
        f2 = find(abs(f-fmax) == min(abs(f-fmax)));
    end
    % fGamma
    if freq == 5
        flegend = 'fGamma';
        fmin = 60; fmax= 98;
        f1 = find(abs(f-fmin) == min(abs(f-fmin)));
        f2 = find(abs(f-fmax) == min(abs(f-fmax)));
    end
    
    if color == 1
        color1 = [118 6 154]/255; % Seteo el color para el CS+ aversivo
        color2 = [96 96 96]/255; % Seteo el color para el CS-
    elseif color == 2
        color1 = [255 140 0]/255; % Seteo el color para el freezing a un tono de naranja
        color2 = [96 96 96]/255; % Seteo el color para el no freezing
    end

    % Calculamos medias y sem
    mean1 = squeeze(nanmedian(nanmedian(C1(t1:t2,f1:f2,:),2),1));
    mean2 = squeeze(nanmedian(nanmedian(C2(t1:t2,f1:f2,:),2),1));
    mean3 = squeeze(nanmedian(nanmedian(C3(t1:t2,f1:f2,:),2),1));
    mean4 = squeeze(nanmedian(nanmedian(C4(t1:t2,f1:f2,:),2),1));
    sem1 = nanmad(mean1)/sqrt(length(mean1));
    sem2 = nanmad(mean2)/sqrt(length(mean2));
    sem3 = nanmad(mean3)/sqrt(length(mean3));
    sem4 = nanmad(mean4)/sqrt(length(mean4));

    % Finalmente ploteamos
    bar(1,nanmedian(mean1),0.7,'FaceColor',color1,'FaceAlpha',0.3); hold on;
    errorbar(1, nanmedian(mean1), sem1, 'k.', 'LineWidth', 1);
    bar(2,nanmedian(mean2),0.7,'FaceColor',color2,'FaceAlpha',0.3); hold on;
    errorbar(2, nanmedian(mean2), sem2, 'k.', 'LineWidth', 1);
    bar(3,nanmedian(mean3),0.7,'FaceColor',color1,'FaceAlpha',0.3); hold on;
    errorbar(3, nanmedian(mean3), sem3, 'k.', 'LineWidth', 1);
    bar(4,nanmedian(mean4),0.7,'FaceColor',color2,'FaceAlpha',0.3); hold on;
    errorbar(4, nanmedian(mean4), sem4, 'k.', 'LineWidth', 1);

    % Hacemos la estadística
    [p] = ranksum(mean1,mean2);
    if p >= 0.05;
        p_value_res = 'ns';
    elseif p < 0.05 && p >= 0.01;
        p_value_res = '*';
    else
        p_value_res = '**';
    end
    if p < 0.05;
        text(1.5,0.9,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',14);
        line([1 2],[0.86 0.86],'color',[0 0 0]);
    end
    
    [p] = ranksum(mean3,mean4);
    if p >= 0.05;
        p_value_res = 'ns';
    elseif p < 0.05 && p >= 0.01;
        p_value_res = '*';
    else
        p_value_res = '**';
    end
    if p < 0.05;
        text(3.5,0.9,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',14);
        line([3 4],[0.86 0.86],'color',[0 0 0]);
    end
    
    [p] = ranksum(mean1,mean3);
    if p >= 0.05;
        p_value_res = 'ns';
    elseif p < 0.05 && p >= 0.01;
        p_value_res = '*';
    else
        p_value_res = '**';
    end
    if p < 0.05;
        text(2,0.95,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',14);
        line([1 3],[0.91 0.91],'color',[0 0 0]);
    end
    
    [p] = ranksum(mean2,mean4);
    if p >= 0.05;
        p_value_res = 'ns';
    elseif p < 0.05 && p >= 0.01;
        p_value_res = '*';
    else
        p_value_res = '**';
    end
    if p < 0.05;
        text(3,1,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',14);
        line([2 4],[0.96 0.96],'color',[0 0 0]);
    end

    xlim([0.5 4.5]);
    ylim([0.5 1]);
    ylabel('Coherence','FontSize', 10);
    title(sprintf('%s %s', flegend, 'Coherence'));
    set(gca,'xtick',[1.5 3.5],'xticklabel',{'BLA-PL'; 'BLA-IL'});
    set(gca,'FontSize',10);
    set(gca, 'YTick', [0:0.1:1]);
    set(gcf, 'Color', 'white');
    
    hold off
return