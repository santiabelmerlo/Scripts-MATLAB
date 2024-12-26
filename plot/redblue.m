function colormap = redblue(nColors)
    % REDBLUE Creates a red-white-blue colormap
    % Usage:
    %   cmap = redblue(nColors)
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
    
    % Interpolate red to white
    red_to_white_red = linspace(1, 1, nHalfColors)';
    red_to_white_green = linspace(0, 1, nHalfColors)';
    red_to_white_blue = linspace(0, 1, nHalfColors)';
    
    % Interpolate white to blue
    white_to_blue_red = linspace(1, 0, nHalfColors)';
    white_to_blue_green = linspace(1, 0, nHalfColors)';
    white_to_blue_blue = linspace(1, 1, nHalfColors)';
    
    % Combine the components into a colormap
    red_to_white = [red_to_white_red, red_to_white_green, red_to_white_blue];
    white_to_blue = [white_to_blue_red, white_to_blue_green, white_to_blue_blue];
    colormap = [red_to_white; white_to_blue];
end