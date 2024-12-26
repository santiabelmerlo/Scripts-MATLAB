function [DatSR,EEGSR,NumEEGChannels,GoodEEGChannelBool,EEGChannelLayout,NumCSDChannels,GoodCSDChannelBool,CSDChannelLayout] = NP_GetEEGParams(filebase)
% [DatSR,EEGSR,NumEEGChannels,GoodEEGChannelBool,EEGChannelLayout,NumCSDChannels,GoodCSDChannelBool,CSDChannelLayout] = NP_GetEEGParams(filebase)
% Entirely different approach to managing session parameters - Dave doesn't want to have to go in and make sure
% that every .xml file for every frickin recording session is right
% For this to work, the recording session needs to have been logged in the NP_MakeMasterDirectory function

cd /DAVIDSUL05/analysis

load MasterDirectory

idx = 1;

%advance to the right entry in the database
while(strcmp(MasterDirectory(idx).filebase,filebase) == 0)
  idx = idx+1;
end

animal = MasterDirectory(idx).animal;

load RecordingInfo

idx = 1;
while(strcmp(animal,RecordingInfo(idx).Animal) == 0)
  idx = idx+1;
end

DatSR = RecordingInfo(idx).DatSR;
EEGSR = RecordingInfo(idx).EEGSR;

NumEEGChannels = RecordingInfo(idx).NumEEGChannels;
GoodEEGChannelBool = RecordingInfo(idx).GoodEEGChannelBool;
EEGChannelLayout = RecordingInfo(idx).EEGChannelLayout;

NumCSDChannels = RecordingInfo(idx).NumCSDChannels;
GoodCSDChannelBool = RecordingInfo(idx).GoodCSDChannelBool;
CSDChannelLayout = RecordingInfo(idx).CSDChannelLayout;






