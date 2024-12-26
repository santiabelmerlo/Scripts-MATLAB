clear all
clc

[PathName] = uigetdir2('/media/mariano/DATA01/DATA/Ceci/','Seleccione carpetas con los archivos *.lfp para analizar');


for INDPath = 2 : length(PathName)
    
    FileInfo.Path     = PathName{INDPath};
    
    F = dir([FileInfo.Path,'/*.lfp']); lfpFILE = F.name ; clear F
    
    FileInfo.FileBase = lfpFILE(1:end-4);
    FileInfo          = LoadPar([FileInfo.Path , '/', FileInfo.FileBase]);
    FileInfo.FileBase = lfpFILE(1:end-4); clear lfpFILE
    FileInfo.Path     = PathName{INDPath};
    
%     ChtoLoad    = [3 6 10 13 17 26 30];   % rata 07
%     ChtoLoad    = [3 6 11 13 18 21 27 30];% rata 11
%     ChtoLoad    = [3 6 11 13 17 22 26 31];% rata 12
%     ChtoLoad    = [2 6 11 15 18 22 27 31];% rata 19
%     ChtoLoad    = [1 4 9 12 18 20 26 29]; % rata 29
    ChtoLoad   = [0 5 8 12 16 20 27 29];%'RATA35'
    
    ind = 0;
    
    for IND = ChtoLoad
        
        ind = ind + 1;
        
%         myEeg = LoadBinary([FileInfo.Path , '/',FileInfo.FileBase,'.lfp'],IND,(FileInfo.nChannels),3,[],[],[]);
        myEeg = LoadBinary([FileInfo.Path , '/',FileInfo.FileBase,'.lfp'],'channels',IND+1,'frequency',1250,'nChannels',(FileInfo.nChannels) );
        
        display(['';'loaded']);
        
        WholeChannelWavelet_m2(FileInfo.Path, FileInfo, myEeg, IND, [], [], [], 1);
        
        display(['';'DONE!!  ', num2str(ind), ' de ', num2str(length(ChtoLoad)) ]);   clear myEeg
    end
    
end
