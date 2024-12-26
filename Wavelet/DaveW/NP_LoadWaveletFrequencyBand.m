function [a] = NP_LoadWaveletFrequencyBandCSD(filebase,channel,frequencyidx)

NumLevels = 65;

[DatSR,EEGSR,NumEEGChannels,GoodEEGChannelBool,EEGChannelLayout,NumCSDChannels,GoodCSDChannelBool,CSDChannelLayout] = NP_GetEEGParams(filebase);

NP_NavDir(filebase);
fid = fopen([filebase,'_csdWaveletCH',int2str(channel)]);
fseek(fid,(frequencyidx-1)*4,-1)

load([filebase,'_WaveletInfo.mat']);

a = fread(fid,EEGlength,'single',64*4);
