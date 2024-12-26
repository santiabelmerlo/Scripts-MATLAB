function plot_matrix_smooth(X,t,f,plt,smooth)
% Function to plot a time-frequency matrix X. Time and frequency axes are in t and f.
% Usage: plot_matrix_smooth(X,t,f,plt,smooth)
% Inputs:
% X: input vector as a function of time and frequency (t x f)
% t: t axis grid for plot. Default [1:size(X,1)]
% f: f axis grid for plot. Default. [1:size(X,2)]
% plt: 'l' for log, 'n' for no log.
% smooth: smooth factor. Number of times to interpolate data. smooth = 1 is
% no interpolation.
if nargin < 1; error('Need data'); end;
[NT,NF]=size(X);
if nargin < 2;
    t=1:NT;
end;
if nargin < 3;
    f=1:NF;
end;
if length(f)~=NF || length(t)~=NT; error('axes grid and data have incompatible lengths'); end;
if nargin < 4 || isempty(plt);
    plt='l';
end;
if strcmp(plt,'l');
    X = 10*log10(X);
end;
if strcmp(plt,'n');
    Z = X;
end;
if nargin <= 5;
    X = imresize(X,[size(X,1)*smooth size(X,2)*smooth]);
    t = interp(t,smooth);
    f = interp(f,smooth);
    imagesc(t,f,X');axis xy; colorbar; title('Spectrogram');
    colormap(jet);
end;

% Setting colormap limits
if strcmp(plt,'l');
    caxis([10 40]);
end;
if strcmp(plt,'n');
    caxis([0 1000]);
end;

xlabel('Time (sec.)');ylabel('Frequency (Hz)');

