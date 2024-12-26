function madValue = nanmad(data, flag, dim)
    % nanmad Calculates the Median Absolute Deviation from the median,
    % ignoring NaN values.
    %
    %   madValue = nanmad(data) returns the MAD of the input data,
    %   ignoring NaNs.
    %
    %   madValue = nanmad(data, flag) specifies the normalization to be used.
    %   If flag is 0 (default), the normalization factor is 1.
    %   If flag is 1, the normalization factor is 1.4826.
    %
    %   madValue = nanmad(data, flag, dim) calculates the MAD along the
    %   specified dimension dim.
    %
    % Inputs:
    %   - data: Input data array
    %   - flag: Normalization factor (0 or 1), optional
    %   - dim: Dimension along which to calculate the MAD, optional
    %
    % Output:
    %   - madValue: Median Absolute Deviation, ignoring NaNs

    if nargin < 2 || isempty(flag)
        flag = 0;
    end
    if nargin < 3
        % If dim is not specified, operate along the first non-singleton dimension
        dim = find(size(data) ~= 1, 1);
        if isempty(dim), dim = 1; end
    end

    % Remove NaNs along the specified dimension
    nanMask = isnan(data);
    data(nanMask) = [];

    % Calculate the median
    med = nanmedian(data, dim);

    % Calculate the absolute deviations from the median
    absDeviation = abs(data - med);

    % Calculate the MAD
    madValue = nanmedian(absDeviation, dim);

    % Apply the normalization factor if flag is 1
    if flag == 1
        madValue = madValue * 1.4826;
    end
end

