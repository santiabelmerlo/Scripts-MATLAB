% Modificado por Mariano

function [wavelet, phases] = NP_LoadWaveletFrequencyBand_m2(myPath, FileName, State, channel,frequencyidx)

%NumLevels = 65;

%[DatSR,EEGSR,NumEEGChannels,GoodEEGChannelBool,EEGChannelLayout,NumCSDChannels,GoodCSDChannelBool,CSDChannelLayout] = NP_GetEEGParams(filebase);

%NP_NavDir(filebase);

Dir=[myPath, FileName];
% Dir=['/lia3/DATA/Results/ThGPP/Wavelet/',fileinfo.eegfile.filename];
% Dir=['/lia3/DATA/Results/ThGPP/Wavelet/2_300/',fileinfo.eegfile.filename];

% if isfield(fileinfo, 'maze') == 1 % Just in case the name includes fileinfo.maze field
    fid = fopen([Dir,'/',FileName,'_WaveletCH',int2str(channel),'_',State]);

    % fid = fopen([Dir,'/',FileName,'_WaveletCH',int2str(channel)]);
    fseek(fid,(frequencyidx-1)*4,-1);
    load([Dir,'/',fileinfo.eegfile.filename,'_WaveletInfoCH',int2str(channel),'_',fileinfo.maze,'.mat']);
    % load([Dir,'/',FileName,'_WaveletInfo.mat']);
% else
% 
%     fid = fopen([Dir,'/',FileName,'_WaveletCH',int2str(channel)]);
%     fseek(fid,(frequencyidx-1)*4,-1);
%     load([Dir,'/',FileName,'_WaveletInfo.mat']);
% end

wavelet = fread(fid,EEGlength,'single',64*4);
fclose(fid);


% if isfield(fileinfo, 'maze') == 1 % Just in case the name includes fileinfo.maze field
    fid = fopen([Dir,'/',FileName,'_WaveletPhaseCH',int2str(channel),'_',State]);

    % fid = fopen([Dir,'/',FileName,'_WaveletCH',int2str(channel)]);
    fseek(fid,(frequencyidx-1)*4,-1);
    load([Dir,'/',FileName,'_WaveletInfoCH',int2str(channel),'_',State,'.mat']);
    % load([Dir,'/',FileName,'_WaveletInfo.mat']);
% else
% 
%     fid = fopen([Dir,'/',FileName,'_WaveletPhaseCH',int2str(channel)]);
%     fseek(fid,(frequencyidx-1)*4,-1);
%     load([Dir,'/',FileName,'_WaveletInfo.mat']);
% end

phases = fread(fid,EEGlength,'single',64*4);
fclose(fid);


