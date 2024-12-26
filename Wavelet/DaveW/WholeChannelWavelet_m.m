% function [] = WholeChannelWavelet_m( fileinfo, signal, channel, HighFreq, LowFreq)

% original NP_WholeChannelWaveletCSD (Dave's)
% Load signal and compute the wavelet

% channel: ch to compute wavelet
% seg: [seg11 seg12; segn1 segn2] segments of signal to be load 

function [] = WholeChannelWavelet_m(myPath, fileinfo, signal, channel, varargin)


[HighFreq, LowFreq] =  DefaultArgs(varargin,{150 , 2 });


% ------ step one: load the channel

v = signal';

EEGlength = length(v);

% Some key parameters
%HighFreq = 150;
%LowFreq = 2;
NumBands = 64;
WaveletChunkLength = 100000; % a million samples, approximately 12 minutes @ 1250 Hz. Limited by RAM size
NumBadSamples = 858; % determined for the (300,2,64) for the above parameters

StartSample = 1;
EndSample = WaveletChunkLength;
% # of samples we need to overlap by is the timepoint at which the coi hits the lowest frequency, plus one


% open up the file

Dir = [myPath,num2str(LowFreq),'_',num2str(HighFreq),'/',fileinfo.eegfile.filename];

% Dir=['/lia3/DATA/Results/ThGPP/Wavelet/',fileinfo.eegfile.filename];
% Dir=['/lia3/DATA/Results/ThGPP/Wavelet/2_300/',fileinfo.eegfile.filename];

if exist (Dir, 'dir') == 0
    mkdir(Dir);
end

if isfield(fileinfo, 'maze') == 1
    fid = fopen([Dir,'/',fileinfo.eegfile.filename,'_WaveletCH',int2str(channel),'_',fileinfo.maze],'w');
else
    fid = fopen([Dir,'/',fileinfo.eegfile.filename,'_WaveletCH',int2str(channel)],'w');
end

samples_written = [];

while (EndSample < EEGlength)
  EndSample/EEGlength
  wavelet_idx = StartSample:EndSample;
  [tempwave,period,scale,coi] = NP_RawWavelet(fileinfo.eegfile.SampleRate,v(wavelet_idx),HighFreq,LowFreq,NumBands);
  
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

EndSample   = EEGlength;
wavelet_idx = StartSample:EndSample;

[tempwave,period,scale,coi] = NP_RawWavelet(fileinfo.eegfile.SampleRate,v(wavelet_idx),HighFreq,LowFreq,NumBands);

FirstWriteIdx      = NumBadSamples + 1;
LastWriteIdx       = length(wavelet_idx);
SamplesToBeWritten = wavelet_idx(FirstWriteIdx:LastWriteIdx);

for i = FirstWriteIdx:LastWriteIdx
  fwrite(fid,single(tempwave(:,i)),'single');
end
samples_written = [samples_written,SamplesToBeWritten]; 

% save some important info
if isfield(fileinfo, 'maze') == 1 % Just in case the name includes fileinfo.maze field
    savestr = ['save ',[Dir,'/',fileinfo.eegfile.filename],'_WaveletInfoCH',int2str(channel),'_',fileinfo.maze,'.mat HighFreq LowFreq period scale EEGlength'];
else
    savestr = ['save ',[Dir,'/',fileinfo.eegfile.filename],'_WaveletInfoCH',int2str(channel),'.mat HighFreq LowFreq period scale EEGlength'];
end

eval(savestr);

% Now, calculate mean and std of each band
display('Calculating mean and std of each frequency band');

myPathII = [myPath,num2str(LowFreq),'_',num2str(HighFreq),'/'];
for i = 1:NumBands+1
  tempfreq = NP_LoadWaveletFrequencyBand_m(myPathII, fileinfo,channel,i);
  BandMean(i) = mean(tempfreq);
  BandStd(i) = std(tempfreq);
end

if isfield(fileinfo, 'maze') == 1
    savestr = ['save ',[Dir,'/',fileinfo.eegfile.filename],'_WaveletstatsCH',int2str(channel),'_',fileinfo.maze,'.mat BandMean BandStd'];
else
    savestr = ['save ',[Dir,'/',fileinfo.eegfile.filename],'_WaveletstatsCH',int2str(channel),'.mat BandMean BandStd'];
end
eval(savestr);
fclose(fid);
display('Done!!!');
%keyboard;
