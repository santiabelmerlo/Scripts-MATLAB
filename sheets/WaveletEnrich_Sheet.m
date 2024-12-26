%% WaveletEnrich_Sheet.m
% Script para crear la sheet WaveletEnrich_Sheet.csv con las columnas Ratio
% y Enrich para clasificar los eventos según la señal de Wavelets
clc
clear all

% Cargamos la tabla de EventsSheet
cd('D:\Doctorado\Analisis\Sheets');
WaveletSheet = readtable('PowerWavelets_forFzSep.csv');

WaveletSheet{:,:}(WaveletSheet{:,:} < 0) = NaN;

WaveletSheet.Ratio = nanmean([WaveletSheet.BLA_4Hz./WaveletSheet.BLA_Theta,WaveletSheet.PL_4Hz./WaveletSheet.PL_Theta,WaveletSheet.IL_4Hz./WaveletSheet.IL_Theta],2);

WaveletSheet.Enrich = repmat({''}, height(WaveletSheet), 1); % Crear columna vacía de celdas
WaveletSheet.Enrich(isnan(WaveletSheet.Ratio)) = {'NaN'};  % Usar una celda con el valor 'NaN'
WaveletSheet.Enrich(WaveletSheet.Ratio > 1) = {'4Hz'};  % Usar una celda con el valor '4Hz'
WaveletSheet.Enrich(WaveletSheet.Ratio <= 1) = {'Theta'};  % Usar una celda con el valor 'Theta'

writetable(WaveletSheet,'WaveletEnrich.csv');