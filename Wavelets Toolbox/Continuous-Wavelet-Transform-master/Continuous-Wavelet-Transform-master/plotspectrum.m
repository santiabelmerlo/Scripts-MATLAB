function plotspectrum(t,f,y,coi)
%-INPUT--------------------------------------------------------------------
% t: time (in seconds) of the spectrum and original signal
% f: frequency bins (in Hz) of the spectrum
% y: output time-frequency spectrum (complex matrix)
%-OUTPUT-------------------------------------------------------------------
% none: creates new figure and plots the time-frequency spectrum

[t,coiweightt,ut] = engunits(t,'unicode','time');
xlbl = ['Time (sec.)'];
[f,coiweightf,uf] = engunits(f,'unicode');
%coiweightf = 1; uf = ''; %6/24/2018
ylbl = ['Frequency (',uf,'Hz)'];
coi = (coi * mean(diff(t))) ./ (coiweightt * coiweightf);
invcoi = 1 ./ coi;
invcoi(invcoi>max(f)) = max(f);

t = t*60; % Vuelvo a transformar a segundos. Es una modificación mia

hf = figure;
hf.NextPlot = 'replace';
ax = axes('parent',hf);
imagesc(ax,t,log2(f),abs(y));

cmap = jet(1000);cmap = cmap([round(linspace(1,375,250)),376:875],:); %jet is convention, but let's adjust
%cmap = parula(750);
colormap(cmap)

logyticks = round(log2(min(f))):round(log2(max(f)));
ax.YLim = log2([min(f), max(f)]);
ax.YTick = logyticks;
ax.YDir = 'normal';
set(ax,'YLim',log2([min(f),max(f)]), ...
    'layer','top', ...
    'YTick',logyticks(:), ...
    'YTickLabel',num2str(sprintf('%g\n',2.^logyticks)), ...
    'layer','top')
title('Magnitude Scalogram');
xlabel(xlbl);
ylabel(ylbl);
hcol = colorbar;
hcol.Label.String = 'Magnitude';
hold(ax,'on');

%shade out complement of coi
% plot(ax,t,log2(invcoi),'w--','linewidth',2);
% A1 = area(ax,t,log2(invcoi),min([min(ax.YLim) min(invcoi)]));
% A1.EdgeColor = 'none';
% A1.FaceColor = [0.5 0.5 0.5];
% alpha(A1,0.8);
% hold(ax,'off');
% hf.NextPlot = 'replace';
end