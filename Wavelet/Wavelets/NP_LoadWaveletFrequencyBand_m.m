% Modificado por Mariano

function [wavelet] = NP_LoadWaveletFrequencyBand_m(myPath, FileInfo, State, channel, frequencyidx)

% NumLevels = 65;

%[DatSR,EEGSR,NumEEGChannels,GoodEEGChannelBool,EEGChannelLayout,NumCSDChannels,GoodCSDChannelBool,CSDChannelLayout] = NP_GetEEGParams(filebase);

%NP_NavDir(filebase);

Dir=[myPath];
% Dir=[myPath, FileName];
% Dir=['/lia3/DATA/Results/ThGPP/Wavelet/',fileinfo.eegfile.filename];
% Dir=['/lia3/DATA/Results/ThGPP/Wavelet/2_300/',fileinfo.eegfile.filename];

if isfield(FileInfo, 'maze') == 1 % Just in case the name includes fileinfo.maze field
    fid = fopen([Dir,'/',FileInfo.FileBase,'_WaveletCH',int2str(channel),'_',State]);

    % fid = fopen([Dir,'/',fileinfo.eegfile.filename,'_WaveletCH',int2str(channel)]);
    fseek(fid,(frequencyidx-1)*4,-1)
    load([Dir,FileInfo.FileBase,'_WaveletInfoCH',int2str(channel),'_',State,'.mat']);
    % load([Dir,'/',fileinfo.eegfile.filename,'_WaveletInfo.mat']);
else

     fid = fopen([Dir,FileInfo.FileBase,'_WaveletCH',int2str(channel)]);
     fseek(fid,(frequencyidx-1)*4,-1)
     load([Dir,FileInfo.FileBase,'_WaveletInfoCH',int2str(channel),'.mat']);
 end

wavelet = fread(fid,EEGlength,'single',64*4);
fclose(fid);



