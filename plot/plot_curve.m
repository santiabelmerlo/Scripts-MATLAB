function plot_curve(x, data, method, color, smoothFactor, LineStyle)
    % Inputs:
    % x - The x-axis values (1xN double)
    % data - The data array (MxN double, where M is the number of trials and N is the number of time points)
    % method - 'mean' for mean and SEM or 'median' for median and MAD
    % color - The color of the plot and shaded area (RGB triplet or color name)
    % smoothFactor - The smoothing factor for the curve and error (scalar)
    % LineStyle - El estilo de la linea: 'cont' o 'dis' para continua o
    % discontinua
    
    % Asignar valor predeterminado a LineStyle si está vacío
    if isempty(LineStyle)
        LineStyle = 'cont'; % valor por defecto (puedes cambiarlo a 'dis' si prefieres)
    end
    
    % Calculate the curve and error based on the selected method
    switch method
        case 'mean'
            y = smooth(nanmean(data, 1), smoothFactor)';
            errorValue = smooth(nanstd(data, 0, 1) / sqrt(size(data, 1)), smoothFactor)';
        case 'median'
            y = smooth(nanmedian(data, 1), smoothFactor)';
            errorValue = smooth(mad(data, 1, 1) / sqrt(size(data, 1)), smoothFactor)';
        otherwise
            error('Invalid method. Use ''mean'' or ''median''.');
    end

    % Calculate the upper and lower bounds of the error
    curveUpper = y + errorValue;
    curveLower = y - errorValue;
    
    % Create the shaded area
    x2 = [x, fliplr(x)];
    inBetween = [curveUpper, fliplr(curveLower)];
    p1 = fill(x2, inBetween, color, 'LineStyle', 'none');
    set(p1, 'facealpha', 0.3); % Set transparency of the shaded area

    % Plot the central tendency curve
    hold on;
    if strcmp(LineStyle,'dis')
        p2 = plot(x, y, 'Color', color, 'LineWidth', 1,'LineStyle','--');
    else
        p2 = plot(x, y, 'Color', color, 'LineWidth', 1);
    end
    hold off;
    
    % Optional: Return the plot handles if needed
    if nargout > 0
        varargout{1} = p1;
        varargout{2} = p2;
    end
end
