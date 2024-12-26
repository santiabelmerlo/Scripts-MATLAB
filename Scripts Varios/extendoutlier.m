function extended_vector = extendoutlier(logical_vector, extension_length)
    % Extend a group of ones in a logical vector
    % I use it to extend the noise detection a couple of samples 
    % Usage: extended_vector = extendoutlier(logical_vector, extension_length)
    % logical_vector: vector with ones and ceros
    % extension_length: how much samples to extend the ones

    % Validate inputs
    if ~islogical(logical_vector)
        error('Input vector must be logical.');
    end
    if ~isscalar(extension_length) || extension_length < 0
        error('Extension length must be a non-negative scalar.');
    end
    
    % Find the indices of ones
    ones_indices = find(logical_vector);
    
    if isempty(ones_indices)
        extended_vector = logical_vector;
        return;
    end
    
    % Initialize the extended vector
    extended_vector = logical_vector;
    
    % Extend the groups of ones
    for i = 1:length(ones_indices)
        % Get the start and end of the current group
        start_idx = ones_indices(i);
        
        % Find the end of the current group
        end_idx = start_idx;
        while end_idx < length(logical_vector) && logical_vector(end_idx + 1)
            end_idx = end_idx + 1;
        end
        
        % Extend the beginning and end of the group
        start_idx = max(1, start_idx - extension_length);
        end_idx = min(length(logical_vector), end_idx + extension_length);
        
        % Set the extended range to ones
        extended_vector(start_idx:end_idx) = 1;
        
        % Skip to the end of the current group
        i = find(ones_indices == end_idx, 1);
    end
end