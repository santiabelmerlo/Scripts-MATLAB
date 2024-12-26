function scatter_GCt(data,dotsize,color,x_pos)
    % Función para plotear un scatter de los valores en el plot_GCt
    % Uso: scatter_GCt(data,dotsize,color,x_pos)
    % Uso: scatter_GCt(FF_CS1(2,1,:),10,BLA_color,1)
    BLA_color = [66,133,244]/255;
    PL_color = [234,67,53]/255;
    IL_color = [251,188,5]/255;
    y = squeeze(data);
    notoutlier = ~isoutlier(y,'median',20);
    y_no = y(notoutlier);
    scatter(random_x(x_pos,size(y_no,1)), y_no, dotsize, color); hold on;
return