function plot_GCt(data,frecuencia)
    %   Función para plotear Granger Causality en el dominio del tiempo
    %   integrado por banda frecuencial
    %   Uso: plot_GCt(data,frecuencia)
    %        plot_GCt(FF_CS1,'4-Hz')
    %   Donde: data es la matriz FF de 3 dimensiones y frecuencias es un
    %   string con la frecuencia que estoy analizando, para agregarlo al
    %   titulo del gráfico

    BLA_color = [66,133,244]/255;
    PL_color = [234,67,53]/255;
    IL_color = [251,188,5]/255;
    siz = size(squeeze(data(2,1,:)),1);
    dato = [squeeze(data(2,1,:)); squeeze(data(1,2,:)); squeeze(data(3,1,:)); squeeze(data(1,3,:)); squeeze(data(3,2,:)); squeeze(data(2,3,:))];
    % Crear un vector de grupo
    group = [ones(siz,1); 2*ones(siz,1); 3*ones(siz,1); 4*ones(siz,1); 5*ones(siz,1); 6*ones(siz,1)];
    % Crear el boxplot
%     boxplot(dato, group, 'Colors', [BLA_color;PL_color;BLA_color;IL_color;PL_color;IL_color], 'Whisker', 0, 'Widths', 0.7,'Symbol', '');
    boxplot(dato, group, 'Colors', [BLA_color;PL_color;BLA_color;IL_color;PL_color;IL_color], 'Widths', 0.7,'Symbol', '');
    hold on;
    
    % Agregamos los valores individuales
    scatter_GCt(data(2,1,:),10,BLA_color,1); hold on;
    scatter_GCt(data(1,2,:),10,PL_color,2); hold on;
    scatter_GCt(data(3,1,:),10,BLA_color,3); hold on;
    scatter_GCt(data(1,3,:),10,IL_color,4); hold on;
    scatter_GCt(data(3,2,:),10,PL_color,5); hold on;
    scatter_GCt(data(2,3,:),10,IL_color,6); hold on;
    
    % Ajustar el gráfico
    set(gca, 'XTick', [1.5,3.5,5.5], 'XTickLabel', {'BLA-PL','BLA-IL','PL-IL'});
    set(gca,'FontSize',10);
    xlim([0.5 6.5]);
    ylabel('Granger Causality','FontSize', 10);
    hold on
    
    [p1] = ranksum(squeeze(data(2,1,:)),squeeze(data(1,2,:)));
    [p2] = ranksum(squeeze(data(3,1,:)),squeeze(data(1,3,:)));
    [p3] = ranksum(squeeze(data(3,2,:)),squeeze(data(2,3,:)));

    if p1 >= 0.05;
        p1_value_res = 'ns';
    elseif p1 < 0.05 && p1 >= 0.01;
        p1_value_res = '*';
    else
        p1_value_res = '**';
    end
    
    if p2 >= 0.05;
        p2_value_res = 'ns';
    elseif p2 < 0.05 && p2 >= 0.01;
        p2_value_res = '*';
    else
        p2_value_res = '**';
    end
    
    if p3 >= 0.05;
        p3_value_res = 'ns';
    elseif p3 < 0.05 && p3 >= 0.01;
        p3_value_res = '*';
    else
        p3_value_res = '**';
    end
    
    lim_max = 0.35;
    
    text(1.5,lim_max+0.05,p1_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10); hold on;        
    text(3.5,lim_max+0.05,p2_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10); hold on;
    text(5.5,lim_max+0.05,p3_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10); hold on;
    line([1 2],[lim_max lim_max],'color',[0 0 0]);
    line([3 4],[lim_max lim_max],'color',[0 0 0]);
    line([5 6],[lim_max lim_max],'color',[0 0 0]);
    
    ylim([-0.02 0.4]);
    
    title(frecuencia,'FontSize',10); hold off;
    set(gcf, 'Color', 'white');

return