function [] = NP_NavDir(filebase);
% this function navigates to the correct directory for session filebase

cd /DAVIDSUL05/analysis
load MasterDirectory

for i = 1:length(MasterDirectory)
  if (strcmp(filebase,MasterDirectory(i).filebase) == 1)
    cdstr = ['cd ',MasterDirectory(i).location];
    %display(cdstr);
    eval(cdstr);
    return;
  end
end



