function [wPower,period,scale,coi,rawwave] = NP_Wavelet(EEGSR,EEGchunk,UpperLimitHz,LowerLimitHz,NumScales,toplot)
% [tempwave,period,scale,coi] = NP_Wavelet(EEGSR,EEGchunk,UpperLimitHz,LowerLimitHz,NumScales)
if (nargin < 6)
  toplot = 0;
end

dt = 1/EEGSR; %  time per sample of the eeg file

s0 = 1 / UpperLimitHz;

j1 = NumScales; % # of scales: frequency resolution

LowerLimitSeconds = 1 / LowerLimitHz;
dj = log2((LowerLimitSeconds/s0))/j1;

[rawwave,period,scale,coi] = wavelet(EEGchunk,dt,1,dj,s0,j1);

wave = abs(rawwave).^2;
for i = 1:length(period)
  wPower(i,:) = wave(i,:)/period(i)/period(i);
end
wPower = single(wPower);

if (toplot == 1)
  figure;
  contourf(((1:length(EEGchunk))-length(EEGchunk)/2)/EEGSR,1./period,wPower,150);caxis([percentile(wPower,.1) percentile(wPower,99.9)]);shading flat;hold on;plot(((1:length(EEGchunk))-length(EEGchunk)/2)/EEGSR,1./coi,'LineWidth',3,'Color','k');  
end