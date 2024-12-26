%
%[wave,period,t] = NP_LoadWaveletChunk_m(myPath,FileInfo,channel,StartTime,EndTime,toplot,norm)
% toplot, 1:countorf 2:meanwave
% norm,   1:do normalization 2:do not


% Modificado por mariano 

function [wave,period,t] = NP_LoadWaveletChunk_m(myPath,FileInfo,channel,StartTime,EndTime,varargin)

[toplot, norm] =  DefaultArgs(varargin,{0 , 1 });


NumLevels = 65;
% NumLevels = 100;

%[DatSR,EEGSR,NumEEGChannels,GoodEEGChannelBool,EEGChannelLayout,NumCSDChannels,GoodCSDChannelBool,CSDChannelLayout] = NP_GetEEGParams(filebase);

StartSample = (StartTime);
EndSample = (EndTime);
NumSamples = length(StartSample:EndSample);

%NP_NavDir(filebase);

Dir = myPath;
% Dir=[myPath, FileInfo.eegfile.filename];
% Dir=['/lia3/DATA/Results/ThGPP/Wavelet/',FileInfo.eegfile.filename];
% Dir=['/lia3/DATA/Results/ThGPP/Wavelet/2_300/',FileInfo.eegfile.filename];

if isfield(FileInfo, 'maze') == 1 % Just in case the name includes FileInfo.maze field
    fid = fopen([Dir,'/',FileInfo.FileBase,'_WaveletCH',int2str(channel),'_',FileInfo.maze]);
    % fid = fopen([Dir,'/',FileInfo.eegfile.filename,'_WaveletCH',int2str(channel),'_',FileInfo.maze]);

    fseek(fid,(StartSample-1)*4*NumLevels,-1);

    load([Dir,FileInfo.FileBase,'_WaveletstatsCH',int2str(channel),'_',FileInfo.maze,'.mat']);
    load([Dir,FileInfo.FileBase,'_WaveletInfoCH',int2str(channel),'_',FileInfo.maze,'.mat']);
%     load([Dir,'/',FileInfo.eegfile.filename,'_WaveletstatsCH',int2str(channel),'_',FileInfo.maze,'.mat']);
%     load([Dir,'/',FileInfo.eegfile.filename,'_WaveletInfoCH',int2str(channel),'_',FileInfo.maze,'.mat']);
else
    fid = fopen([Dir,FileInfo.FileBase,'_WaveletCH',int2str(channel)]);
%     fid = fopen([Dir,'/',FileInfo.eegfile.filename,'_WaveletCH',int2str(channel)]);

    fseek(fid,(StartSample-1)*4*NumLevels,-1);

    load([Dir,FileInfo.FileBase,'_WaveletstatsCH',int2str(channel),'.mat']);
    load([Dir,FileInfo.FileBase,'_WaveletInfoCH',int2str(channel),'.mat']);
%     load([Dir,'/',FileInfo.eegfile.filename,'_WaveletstatsCH',int2str(channel),'.mat']);
%     load([Dir,'/',FileInfo.eegfile.filename,'_WaveletInfoCH',int2str(channel),'.mat']);
end
 
wave = zeros(NumLevels, NumSamples);
 
% for i = 1:NumSamples
%     %   wave(1:65,i) = fread(fid,NumLevels,'single');
%     wave(1:NumLevels,i) = fread(fid,NumLevels,'single');
% 
% end

wave = fread(fid,[NumLevels, NumSamples],'single');

if norm == 1
    for i = 1:NumLevels
        wave(i,:) = (wave(i,:)-BandMean(i))./BandStd(i);
    end
end

t = StartSample:EndSample;

if (toplot == 1)
%     figure(833);contourf((StartSample:EndSample)/FileInfo.eegfile.SampleRate,(1./period),wave,20);shading flat;caxis([-2 2]);colorbar;
    figure(833);contourf((StartSample:EndSample)/FileInfo.lfpSampleRate,(1./period),wave,20);shading flat;caxis([-2 2]);colorbar;
elseif  toplot==2
    figure(834);plot((1./period),mean(wave,2));
end
fclose(fid);