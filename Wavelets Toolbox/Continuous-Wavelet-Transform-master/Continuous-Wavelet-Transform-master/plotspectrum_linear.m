function plotspectrum_linear(t,f,y,coi)
%-INPUT--------------------------------------------------------------------
% t: time (in seconds) of the spectrum and original signal
% f: frequency bins (in Hz) of the spectrum
% y: output time-frequency spectrum (complex matrix)
%-OUTPUT-------------------------------------------------------------------
% none: creates new figure and plots the time-frequency spectrum

[t,coiweightt,ut] = engunits(t,'unicode','time');
xlbl = ['Time (',ut,')'];
[f,coiweightf,uf] = engunits(f,'unicode');
ylbl = ['Frequency (',uf,'Hz)'];
coi = (coi * mean(diff(t))) ./ (coiweightt * coiweightf);
invcoi = 1 ./ coi;
invcoi(invcoi>max(f)) = max(f);

hf = figure;
hf.NextPlot = 'replace';
ax = axes('parent',hf);
imagesc(ax,t,f,abs(y));  % Plot the frequency axis in linear scale

cmap = jet(1000);
cmap = cmap([round(linspace(1,375,250)),376:875],:); % Adjust colormap
colormap(cmap)

ax.YLim = [min(f), max(f)];
ax.YTick = linspace(min(f), max(f), 10);  % Linear ticks for frequency
ax.YDir = 'normal';
set(ax, 'YTick', ax.YTick, 'YTickLabel', num2str(ax.YTick(:)), 'layer', 'top');

title('Magnitude Scalogram');
xlabel(xlbl);
ylabel(ylbl);
hcol = colorbar;
hcol.Label.String = 'Magnitude';
hold(ax, 'on');

% Shade out complement of coi
plot(ax, t, invcoi, 'w--', 'linewidth', 2);
A1 = area(ax, t, invcoi, min([min(ax.YLim) min(invcoi)]));
A1.EdgeColor = 'none';
A1.FaceColor = [0.5 0.5 0.5];
alpha(A1, 0.8);
hold(ax, 'off');
hf.NextPlot = 'replace';

end
