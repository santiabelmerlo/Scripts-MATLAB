function local_minima = islocalmin(data)
    % ISLOCALMIN Custom function to detect local minima in a vector.
    %   local_minima = ISLOCALMIN(data) returns a logical array where true
    %   values indicate local minima in the input vector 'data'.
    
    % Ensure data is a row vector
    if iscolumn(data)
        data = data';
    end

    % Initialize the logical array for local minima
    local_minima = false(size(data));

    % Loop through the data to find local minima
    for i = 2:length(data)-1
        if data(i) < data(i-1) && data(i) < data(i+1)
            local_minima(i) = true;
        end
    end
end
