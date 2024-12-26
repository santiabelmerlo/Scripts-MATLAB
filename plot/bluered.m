function colormap = bluered(nColors)
    % BLUERED Creates a blue-white-red colormap
    % Usage:
    %   cmap = bluered(nColors)
    % Inputs:
    %   nColors - Number of colors in the colormap (default is 256)
    % Outputs:
    %   colormap - The generated colormap matrix
    
    if nargin < 1
        nColors = 256; % Default number of colors
    end
    
    % Ensure nColors is even for smooth transitions
    if mod(nColors, 2) ~= 0
        nColors = nColors + 1;
    end
    
    % Half the number of colors for each transition
    nHalfColors = floor(nColors / 2);
    
    % Interpolate blue to white
    blue_to_white_blue = linspace(1, 1, nHalfColors)';
    blue_to_white_green = linspace(0, 1, nHalfColors)';
    blue_to_white_red = linspace(0, 1, nHalfColors)';
    
    % Interpolate white to red
    white_to_red_blue = linspace(1, 0, nHalfColors)';
    white_to_red_green = linspace(1, 0, nHalfColors)';
    white_to_red_red = linspace(1, 1, nHalfColors)';
    
    % Combine the components into a colormap
    blue_to_white = [blue_to_white_red, blue_to_white_green, blue_to_white_blue];
    white_to_red = [white_to_red_red, white_to_red_green, white_to_red_blue];
    colormap = [blue_to_white; white_to_red];
end
