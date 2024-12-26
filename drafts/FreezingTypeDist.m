%% Comparamos distribuciuones de potencia y de power ratio
clc
clear all

cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');
FzTypeSheet = readtable('NormPower_Sheet.csv');

rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
event = 'Freezing';

colors = lines;

MergedSheet = join(FzTypeSheet, EventsSheet,'Keys', 'ID');
% MergedSheet = MergedSheet(ismember(MergedSheet.Event, event), :);
% MergedSheet = MergedSheet(ismember(MergedSheet.Session, session_toinclude), :);
% MergedSheet = MergedSheet(ismember(MergedSheet.Rat, rats), :);

% Calculate the nanmean of the three FzType values
MergedSheet.FzType = nanmean([MergedSheet.FourHz_BLA ./ MergedSheet.Theta_BLA, MergedSheet.FourHz_PL ./ MergedSheet.Theta_PL, MergedSheet.FourHz_IL ./ MergedSheet.Theta_IL], 2);


figure;
histogram(MergedSheet.FzType,200);

A = MergedSheet(MergedSheet.FzType > 1,:);
B = MergedSheet(MergedSheet.FzType <= 1,:);

%% FzType = PowerSheet.FourHz_BLA ./ PowerSheet.Theta_BLA;
figure();
i = 5;
histogram(MergedSheet.FourHz_BLA,'BinWidth',0.04,'FaceColor', colors(i,:),'EdgeColor',colors(i,:));
ylabel('Frequency');
xlabel('4-Hz Power');
title('Freezing BLA Power');
xlim([0 3]);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [200, 200, 500 200]);

%%
plot(FzTypeSheet.FourHz_BLA); hold on;
plot(FzTypeSheet.Theta_BLA);