function [] = NP_WholeChannelWaveletCSD(filebase,channel)

[DatSR,EEGSR,NumEEGChannels,GoodEEGChannelBool,EEGChannelLayout,NumCSDChannels,GoodCSDChannelBool,CSDChannelLayout] = NP_GetEEGParams(filebase);




NP_NavDir(filebase)

% step one: load the channel
v = readmulti([filebase,'.csd'],NumCSDChannels,channel);
EEGlength = length(v);

% Some key parameters
HighFreq = 300;
LowFreq = 2;
NumBands = 64;
WaveletChunkLength = 100000; % a million samples, approximately 12 minutes @ 1250 Hz. Limited by RAM size
NumBadSamples = 858; % determined for the (300,2,64) for the above parameters

StartSample = 1;
EndSample = WaveletChunkLength;
% # of samples we need to overlap by is the timepoint at which the coi hits the lowest frequency, plus one


% open up the file
fid = fopen([filebase,'_csdWaveletCH',int2str(channel)],'w');
samples_written = [];

while (EndSample < EEGlength)
  EndSample/EEGlength
  wavelet_idx = StartSample:EndSample;
  [tempwave,period,scale,coi] = NP_RawWavelet(EEGSR,v(wavelet_idx),HighFreq,LowFreq,NumBands);
  
  if (StartSample == 1)
    FirstWriteIdx = 1;
  else
    FirstWriteIdx = NumBadSamples + 1;
  end
  
  LastWriteIdx = WaveletChunkLength-(NumBadSamples +1);
  SamplesToBeWritten = wavelet_idx(FirstWriteIdx:LastWriteIdx);
  
  for i = FirstWriteIdx:LastWriteIdx
    fwrite(fid,(single(tempwave(:,i))),'single');
  end
  samples_written = [samples_written,SamplesToBeWritten];
  
  StartSample = StartSample + WaveletChunkLength-(2*NumBadSamples+1);
  EndSample = StartSample+WaveletChunkLength - 1;
  
end

% do the last bit
EndSample = EEGlength;
wavelet_idx = StartSample:EndSample;
[tempwave,period,scale,coi] = NP_RawWavelet(EEGSR,v(wavelet_idx),HighFreq,LowFreq,NumBands);
FirstWriteIdx = NumBadSamples + 1;
LastWriteIdx = length(wavelet_idx);
SamplesToBeWritten = wavelet_idx(FirstWriteIdx:LastWriteIdx);
for i = FirstWriteIdx:LastWriteIdx
  fwrite(fid,single(tempwave(:,i)),'single');
end
samples_written = [samples_written,SamplesToBeWritten]; 

% save some important info
savestr = ['save ',filebase,'_WaveletInfo.mat HighFreq LowFreq period scale EEGlength'];
eval(savestr);

% Now, calculate mean and std of each band
display('Calculating mean and std of each frequency band');
for i = 1:NumBands+1
  tempfreq = NP_LoadWaveletFrequencyBand(filebase,channel,i);
  BandMean(i) = mean(tempfreq);
  BandStd(i) = std(tempfreq);
end
savestr = ['save ',filebase,'_WaveletstatsCH',int2str(channel),'.mat BandMean BandStd'];
eval(savestr);
display('Done!!!');
keyboard;
