function local_maxima = islocalmax(data)
    % ISLOCALMAX Custom function to detect local maxima in a vector.
    %   local_maxima = ISLOCALMAX(data) returns a logical array where true
    %   values indicate local maxima in the input vector 'data'.
    
    % Ensure data is a row vector
    if iscolumn(data)
        data = data';
    end

    % Initialize the logical array for local maxima
    local_maxima = false(size(data));

    % Loop through the data to find local maxima
    for i = 2:length(data)-1
        if data(i) > data(i-1) && data(i) > data(i+1)
            local_maxima(i) = true;
        end
    end
end
