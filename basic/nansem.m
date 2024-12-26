function s = nansem(x, dim)
% NANSEM - Compute standard error of the mean (SEM), ignoring NaNs.
%
%  USAGE
%    s = nansem(x)
%    s = nansem(x, dim)
%
%    x       vector or matrix over which the SEM should be computed
%    dim     (optional) dimension along which to compute the SEM
%
%    s       standard error of the mean, computed ignoring NaNs
%
%  NOTES
%    If no dimension is specified, SEM is computed along the first non-singleton dimension.
%
%  COPYRIGHT
%    Adapted by User from Michaël Zugaro's original script.

% Check inputs
if nargin < 1
    error('Incorrect number of parameters (type ''help nansem'' for details).');
end

if ~ismatrix(x)
    error('Incorrect input - use vector or matrix (type ''help nansem'' for details).');
end

% Default dimension if not specified
if nargin < 2
    dim = find(size(x) ~= 1, 1); % Find the first non-singleton dimension
    if isempty(dim), dim = 1; end
end

% Number of non-NaN elements along the specified dimension
n = sum(~isnan(x), dim);

% Compute SEM
s = nanstd(x, 0, dim) ./ sqrt(n);

% Handle cases where n == 0 to avoid division by zero
s(n == 0) = NaN;
