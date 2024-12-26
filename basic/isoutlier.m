function outliers = isoutlier(data, method, threshold)
    % Outlier detection in a dataset using the 'mean' or the 'median'
    % distance, and a threshold to trigger detection.
    % Usage: outliers = isoutlier(data, method, threshold)
    % e.g: outliers = isoutlier(lfp, 'median', 10)

    % Validate the input arguments
    if nargin < 2
        method = 'median';
    end
    if nargin < 3
        threshold = 3; % Default threshold if not provided
    end
    if ~ismember(method, {'mean', 'median'})
        error('Method must be either "mean" or "median".');
    end

    % Detect outliers based on the specified method
    switch method
        case 'mean'
            % Calculate the mean and standard deviation
            mean_data = nanmean(data);
            std_data = nanstd(data);

            % Calculate the Z-scores
            z_scores = (data - mean_data) / std_data;

            % Find outliers
            outliers = abs(z_scores) > threshold;

        case 'median'
            % Calculate the median
            median_data = nanmedian(data);

            % Calculate the absolute deviations from the median
            abs_deviation = abs(data - median_data);

            % Calculate the MAD (Median Absolute Deviation)
            mad_data = nanmedian(abs_deviation);

            % Find outliers
            outliers = abs(data - median_data) > threshold * mad_data;
    end
end
