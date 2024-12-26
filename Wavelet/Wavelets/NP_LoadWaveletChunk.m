function [wave,period,t] = NP_LoadWaveletChunk(filebase,channel,StartTime,EndTime,toplot)

if (nargin < 5)
  toplot = 0;
end

NumLevels = 65;

[DatSR,EEGSR,NumEEGChannels,GoodEEGChannelBool,EEGChannelLayout,NumCSDChannels,GoodCSDChannelBool,CSDChannelLayout] = NP_GetEEGParams(filebase);

StartSample = (StartTime);
EndSample = (EndTime);
NumSamples = length(StartSample:EndSample);

NP_NavDir(filebase);
fid = fopen([filebase,'_csdWaveletCH',int2str(channel)]);

fseek(fid,(StartSample-1)*4*NumLevels,-1)

load([filebase,'_WaveletstatsCH',int2str(channel),'.mat']);
load([filebase,'_WaveletInfo.mat']);

for i = 1:NumSamples
  wave(1:65,i) = fread(fid,NumLevels,'single');
  
end

for i = 1:NumLevels
  wave(i,:) = (wave(i,:)-BandMean(i))./BandStd(i);
end

t = StartSample:EndSample;

if (toplot == 1)
  figure;contourf((StartSample:EndSample)/EEGSR,(1./period),wave,50);shading flat;caxis([-6 6]);colorbar;
end
fclose(fid);