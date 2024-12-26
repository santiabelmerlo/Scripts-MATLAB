% function [] = WholeChannelWaveletCSD_m( fileinfo, channel, seg, HighFreq, LowFreq)

% original NP_WholeChannelWaveletCSD (Dave's)
% Load signal and compute the wavelet

% channel: ch to compute wavelet
% seg: [seg11 seg12; segn1 segn2] segments of signal to be load 

function [] = WholeChannelWaveletCSD_m(fileinfo,channel,seg, varargin)


[HighFreq, LowFreq] =  DefaultArgs(varargin,{150 , 2 });

% [DatSR,fileinfo.eegfile.SampleRate,NumEEGChannels,GoodEEGChannelBool,..
%     EEGChannelLayout,fileinfo.SNK,GoodCSDChannelBool,CSDChannelLayout] = NP_GetEEGParams(filebase);



% NP_NavDir(filebase)

% ------ step one: load the channel
% v = readmulti([filebase,'.csd'],nchannels,channel);

v=[];
for j=1:size(seg,1)

    v1 = LoadBinary(fileinfo.eegfile.eeg_filename, channel+1,(fileinfo.nChannels),...
        3,[],[],seg(j,:)); %only CA1 pyr layer

    v = [ v , v1 ];clear v1
end

EEGlength = length(v);

% Some key parameters
%HighFreq = 300;
%LowFreq = 2;
NumBands = 64;
WaveletChunkLength = 100000; % a million samples, approximately 12 minutes @ 1250 Hz. Limited by RAM size
NumBadSamples = 858; % determined for the (300,2,64) for the above parameters

StartSample = 1;
EndSample = WaveletChunkLength;
% # of samples we need to overlap by is the timepoint at which the coi hits the lowest frequency, plus one


% open up the file

Dir=['/lia2/DATA/Results/ThGPP/Wavelet/',fileinfo.eegfile.filename];

if exist (Dir, 'dir') == 0
    mkdir(Dir);
end

if isfield(fileinfo, 'maze') == 1
    fid = fopen([Dir,'/',fileinfo.eegfile.filename,'_WaveletCH',int2str(channel),fileinfo.maze],'w');
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

EndSample = EEGlength;
wavelet_idx = StartSample:EndSample;
[tempwave,period,scale,coi] = NP_RawWavelet(fileinfo.eegfile.SampleRate,v(wavelet_idx),HighFreq,LowFreq,NumBands);
FirstWriteIdx = NumBadSamples + 1;
LastWriteIdx = length(wavelet_idx);
SamplesToBeWritten = wavelet_idx(FirstWriteIdx:LastWriteIdx);
for i = FirstWriteIdx:LastWriteIdx
  fwrite(fid,single(tempwave(:,i)),'single');
end
samples_written = [samples_written,SamplesToBeWritten]; 

% save some important info
if isfield(fileinfo, 'maze') == 1 % Just in case the name includes fileinfo.maze field
    savestr = ['save ',[Dir,'/',fileinfo.eegfile.filename],'_WaveletInfoCH',int2str(channel),fileinfo.maze,'.mat HighFreq LowFreq period scale EEGlength'];
else
    savestr = ['save ',[Dir,'/',fileinfo.eegfile.filename],'_WaveletInfoCH',int2str(channel),'.mat HighFreq LowFreq period scale EEGlength'];
end

eval(savestr);

% Now, calculate mean and std of each band
display('Calculating mean and std of each frequency band');
for i = 1:NumBands+1
  tempfreq = NP_LoadWaveletFrequencyBand_m(fileinfo,channel,i);
  BandMean(i) = mean(tempfreq);
  BandStd(i) = std(tempfreq);
end

if isfield(fileinfo, 'maze') == 1
    savestr = ['save ',[Dir,'/',fileinfo.eegfile.filename],'_WaveletstatsCH',int2str(channel),fileinfo.maze,'.mat BandMean BandStd'];
else
    savestr = ['save ',[Dir,'/',fileinfo.eegfile.filename],'_WaveletstatsCH',int2str(channel),'.mat BandMean BandStd'];
end
eval(savestr);
display('Done!!!');
%keyboard;
