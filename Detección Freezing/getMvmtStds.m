function [quiet, intermediate, change, transitionDU, transitionUD,sKyIxs,win,overlap_pts] = getMvmtStds(dataX,dataY,dataZ,varargin)
% getMvmtStds(dataX,dataY,dataZ{,paired values})
% e.g.: [quiet, intermediate, change, transision] = getMvmtStds(dataX,dataY,[],'property',value)
% Typically: [arrestW, undefinedW, motionW, transitionW] = getMvmtStds(dataX,dataY,[],...
%                                   'stdX_threshold',3.5,'stdX_intermediate',2)
%                                   'stdY_threshold',3.5,'stdY_intermediate',2)
%                                   'stdZ_threshold',3.5,'stdZ_intermediate',2)
%
%   Input:
%   fs_w: sample_rate in hz (d:39.0625 hz)
%   debugging: off(0),on(1),super on(2) for density functions (4)(d:0)
%   std_win:  half of number of points used for get each std (d:5)
%   overlap_pts: number of points overlaped between std wins (d:2*win-1)
%   stdX(Y,Z)_thresdhold = values above this sd are big movement (d:3.5)
%   stdX(Y,Z)_intermediate = values above this sd are undefined state (d:2)
%   
%   thre_little_big_mvmt: min number of points to be preserved when (d:15)
%   filtering states changes by size
%   thre_little_arrests:  same (d:25)
%
%
%   Output:
%   getMvmtStds returns arrest, undefined, motion all are (n,2) dimensions, 
%   with n the numbers of each class of events found.
%   quiet(1,:) --> index of time series of begining of arrest
%   quiet(2,:) --> index of time series of end of arrest
%   intermediate(1,:) --> index of time series of begining of undefined
%   intermediate(2,:) --> index of time series of end of undefined
%   change(1,:) --> index of time series of begining of motion
%   change(2,:) --> index of time series of end of motion
%   
%   transitionDU(1,:) --> index of time series of begining transition
%   transitionDU(2,:) --> index of time series of end of transition
%   transitionUD(1,:) --> index of time series of begining transition 
%   transitionUD(2,:) --> index of time series of end of transition
%
%   All values in event array correspond to _indices_ in the original signal.
%
%
%   Output is ready to be saved as a .mat event file with the standard,
%   i.e.:
%   event1_type1    event2_type1    event3_type1....eventN_type1
%   event1_type2    event2_type2    event3_type2....eventN_type2
%   event1_type3    event2_type3    event3_type3....eventN_type3
%         .               .               .               .
%         .               .               .               .
%         .               .               .               .
%   event1_typeM    event2_typeM    event3_typeM....eventN_typeM
%
% Where eventi  MUST HAPPEN before eventj   for i<j and
%       typei   MUST HAPPEN before typej    for i<j
    %% load Data signals
    try 
        data = [dataX(:), dataY(:), dataZ(:)];
    catch
        error('Data arrays size must be the same or empty.')
    end
    dof = size(data,2);   %num de vectores x y z ingresados 
    %% LOAD DEFAULT PARS
    %Load properties passed or defaults
    parNames = {'fs_w','debugging',...
        'std_win','overlap_pts',...
        'stdX_threshold','stdX_intermediate',...
        'stdY_threshold','stdY_intermediate',...
        'stdZ_threshold','stdZ_intermediate',...
        'thre_little_big_mvmt','thre_little_arrests'};
    if length(data) < 260000
        fs_w = 39.0625;
        std_win = 5;
        overlap_pts = 2*std_win-1;
    else
        fs_w = 1250;
        std_win = 70;
        overlap_pts = 0;
    end
    debugging = 0;
    thre_little_big_mvmt =  round((fs_w/(2*std_win-overlap_pts))*.4);
    %min number of conexed points to be preserved in intermediate ^ means .4 secs

    thre_little_arrests = round((fs_w/(2*std_win-overlap_pts))*.6);
    %min number of conexed points to be preserved in arrest     ^ means .6 secs

    stdX_threshold = 3.5; stdX_intermediate = 2;
    stdY_threshold = 3.5; stdY_intermediate = 2;
    stdZ_threshold = 3.5; stdZ_intermediate = 2;

    %%check all to be pairs
    nArgs = length(varargin);
    if round(nArgs/2) ~= nArgs/2
       error('getFileNameList needs propertyName/propertyValue pairs')
    end

    %%Overwrite deafaults
    for pair = reshape(varargin,2,[]) % pair is {propName;propValue}
       %inpName = lower(pair{1}); % make case insensitive
       inpName = pair{1};
       if any(strcmp(inpName,parNames))
            command = sprintf('%s=%s;', inpName, 'pair{2}');
            eval(command);
       else
            error('%s is not a recognized parameter name',inpName)
       end
    end
    std_threshold = [stdX_threshold stdY_threshold stdZ_threshold];
    std_intermediate = [stdX_intermediate stdY_intermediate stdZ_intermediate];
    %% Armo el tiempo de wheel (t_w)
    t_w = 1/fs_w:1/fs_w:length(dataX)*(1/fs_w);
    %% Cargo los colores
    colore = [0 0 1;0 0 0;0 .5 .5;1 0 0;0 1 0;1 1 0];
    %% plot PATH
    % plot(dataX,dataY,'b')
    %% CALCULATE TIME STD. ONE STD VALUE FOR EACH POINT, BASED ON 2*WIN NEIGHBORS
    win = std_win;
    step = 2*win-overlap_pts;
    stds_length = floor((length(data)-(2*win))/(step));
    stds = nan(stds_length,dof);
    t_w_std = nan(stds_length,1);
    sKyIxs = win+1:step:length(data)-win; %indice en sample rate de la mitad de la ventana
    %calculo el STD para cada ventana en los datos
    for ii = 1:length(sKyIxs)
        stds(ii,:) = std(data(sKyIxs(ii)-win:sKyIxs(ii)+win-1,:));
        t_w_std(ii) = t_w(sKyIxs(ii));
    end
    lostE = floor(overlap_pts/2);
    %% EXCLUDE DATA OUTLIERS
    % stdsX(stdsX > 10*std(stdsX)-mean(stdsX)) = nan;
    % stdsY(stdsY > 10*std(stdsY)-mean(stdsY)) = nan;
    %% PLOT::X=BLUE::Y=RED::
    if debugging
        nsubplots = 4;
        uk = figure('visible','on');

        a = subplot(nsubplots,1,1,'visible','on');
        hold on; grid on;
        for ii = 1:dof
            plot(a,t_w(lostE+1:end-(lostE)),data(lostE+1:end-(lostE),ii),'color',colore(ii,:))
        end

        b = subplot(nsubplots,1,2,'visible','on');
        hold on; grid on;
        for ii = 1:dof
            plot(b,t_w_std,stds(:,ii),'.', 'color',colore(ii,:))
        end
        linkaxes([a b],'x')
    end
    %% DENSITY FUNCTION TO IDENTIFY ARRESTS
    if debugging == 4
        scotland = figure('visible','on');
        for ii = 1:dof
            [f,x] = ksdensity(stds(:,ii));
            plot(x,f,'color',colore(ii,:))
            hold on, grid on
        end
    end
    % After getting the arrests, this is the noise: useless plot btw
    % ksdensity(stdsY(setxor([indeces_mov1; indeces_mov2], 1:length(stdsY))))
    % xlim([-1 2])
    %% FIND MOVEMENTS AND PLOT THEM::BIG MOV=RED::LITTLE MOV=GREEN
    % HERE'S WHERE THRESHOLDS ARE USED
    indeces_mov1 = nan(length(stds),dof);
    indeces_mov2 = nan(length(stds),dof);
    for ii = 1:dof
        aux = find(stds(:,ii) >= std_threshold(ii));
        if isempty(aux)
            error(['No values above threshold ' int2str(ii)])
        end
        indeces_mov1(1:length(aux),ii) = aux;
        aux = find(stds(:,ii) < std_threshold(ii) & stds(:,ii) >= std_intermediate(ii));
        if isempty(aux)
            error(['No values above threshold intermediate and below threshold ' int2str(ii)])
        end
        indeces_mov2(1:length(aux),ii) = aux;
    end

    if debugging
        for jj=1:dof
            wholEvWinIxs = nan(win*2*length(indeces_mov2(:,jj)),1);
            for i=1:sum(~isnan(indeces_mov2(:,jj)))
                %me quedo con los pedazos de ventana que cumplen con el criterio de movimiento
                wholEvWinIxs((i-1)*2*win+1:(i-1)*2*win+2*win) = sKyIxs(indeces_mov2(i,jj))-win+1:sKyIxs(indeces_mov2(i,jj))+win;
            end       
            dataOrNan = data(lostE+1:end-(lostE),jj);
            wholEvWinIxs( wholEvWinIxs < win | wholEvWinIxs > length(dataOrNan)) = nan;
            serannan = setxor(wholEvWinIxs(~isnan(wholEvWinIxs)),1:length(dataOrNan));
            dataOrNan(serannan) = nan;
            plot(a,t_w(lostE+1:end-(lostE)),dataOrNan,'g');hold on; %grafico los que no son indeces_mov2
            
            wholEvWinIxs = nan(win*2*length(indeces_mov1(:,jj)),1);
            for i=1:sum(~isnan(indeces_mov1(:,jj)))
                wholEvWinIxs((i-1)*2*win+1:(i-1)*2*win+2*win) = sKyIxs(indeces_mov1(i,jj))-win+1:sKyIxs(indeces_mov1(i,jj))+win;
            end
            dataOrNan = data(lostE+1:end-(lostE),jj);
            wholEvWinIxs( wholEvWinIxs < win | wholEvWinIxs > length(dataOrNan)) = nan;
            serannan = setxor(wholEvWinIxs(~isnan(wholEvWinIxs)),1:length(dataOrNan));
            dataOrNan(serannan) = nan;
            plot(a,t_w(lostE+1:end-(lostE)),dataOrNan,'r');hold on;
        end
    end
    %% HISTOGRAM OF STDS::also useless
    % hist(stdsY(setxor([indeces_mov1; indeces_mov2], 1:length(stdsY))),.0:.05:.5)
    % hist(stdsY([indeces_mov1; indeces_mov2]),.0:.05:4)
    %% Peaks in STDS
    if debugging
        figure(uk);
        set(uk,'visible','on')
        c = subplot(nsubplots,1,3);grid on;hold on;

        pksAll = nan(length(stds),dof);
        locsAll = nan(length(stds),dof);
        for ii=1:dof
            [pks,locs] = findpeaks(stds(...
                [indeces_mov1(~isnan(indeces_mov1(:,ii)),ii);indeces_mov2(~isnan(indeces_mov2(:,ii)),ii)],ii),...
                'minpeakheight',std_intermediate(1));
            t_peaks = t_w_std([indeces_mov1(~isnan(indeces_mov1(:,ii)),ii);indeces_mov2(~isnan(indeces_mov2(:,ii)),ii)]);
            plot(c,t_peaks(locs),log10(pks)','.','color',colore(ii,:)); hold on

            pksAll(1:length(pks),ii) = pks;
            locsAll(1:length(locs),ii) = locs;
            clear pks locs
        end
    end
    %% PLOT DENSITY FUNCTION FOR LOG10 OF STDS PEAKS
    if debugging == 4
        Bosnia = figure('visible','on');    
        grid on;hold on;
        for ii = 1:dof
            [f,x] = ksdensity(log10(pksAll(:,ii)));
            plot(x,f,'color',colore(ii,:));
        end
        xlabel('logpks')
    end
    %% PLOT DENSITY FUNCTION OF STDS PEAKS
    if debugging == 4
        Albania = figure('visible','on');
        grid on;hold on;
        for ii = 1:dof
            [f,x] = ksdensity(pksAll(:,ii));
            plot(x,f,'color',colore(ii,:));
        end
        xlabel('pks')
        hold off;
    end
    %% CONJUNCION. CREATES THE TOTALLE ARRAY, WHICH MIXES BOTH COORDINATES CLASSES UNDER THE CRITERIA:
    %   IF ANY IS BIG MOVE => BIG MOVE
    %   ELIF ANY IS SMALL MOVE => SMALL MOVE
    %   ELIF ARREST
    %
    %   IF method = 2
    %   
    %   FROM HERE ON, BOTH PROCESS IS EXACTLY THE SAME FOR BOTH METHODS!
    big_move = sort(unique(indeces_mov1(:)));
    big_move = big_move(~isnan(big_move));
    
    small_move = sort(unique(indeces_mov2(:)));
    small_move = small_move(~isnan(small_move));
    
    small_move(ismember(small_move,big_move)) = nan;
    totalle = zeros(size(stds,1), 1);  %totalle tiene el tipo de mov de cada ventana: quieto, small, big
    small_move(isnan(small_move)) = [];
    totalle(big_move) = 2;
    totalle(small_move) = 1;
        
    if debugging
        figure(uk);
        d = subplot(nsubplots,1,4);grid on;hold on;
        if debugging == 1
            plot(d,t_w_std,totalle,'.b');
        end
    end
    %% totalleByClass compressed class.
    % totalleByClass array is here created.
    % Compress the information in totalle. Totalle saves a class value for
    % each point in signal, while totalleByClass saves one value for each
    % state until change. i.e.:
    %   
    %   totalle =   1
    %               1
    %               1
    %               1
    %               2
    %               2
    %               2
    %   TotalleByClass =    1   4
    %                       2   3
    %
    %
    
    %cuenta la cantidad de segmentos de cada clase a medida que van
    %trnasicionando
    
    n = 1;
    j = 1;
    totalleByClass = nan(length(totalle),2);
    group = totalle(1);
    i = 2;
    while i <= length(totalle)
        while i <= length(totalle) && totalle(i) == group 
            n = n + 1;
            i = i + 1;
        end
        totalleByClass(j,:) = [group,n];
        if ~(i <= length(totalle))
            break;
        end
        n = 1;
        group = totalle(i);
        j = j + 1;
        i = i + 1;
    end
    totalleByClass(j,:) = [group,n];
    totalleByClass = totalleByClass(~any(isnan(totalleByClass),2),:); %borro los nan
 
    %% arrests vs. small_mvmt (big_mvmt) = small_mvmt (big_mvmt) && careful, borders may be not accurate
    %verifica que el mov clase 0 (quieto) cumpla un minimo de tiempo(en ventanas)
    %dado por thre_little_arrests. Caso contrario, reemplaza por el tipo de
    %movimiento que tenia en la ventana atenrior.

   
    thre = thre_little_arrests;
    little_arrests_indexes = find(totalleByClass(:,1) == 0 & totalleByClass(:,2) <= thre); %indices de ventanas donde esta quieto (0) durante un periodo max de thre_little_arrests 
    for i = 1:length(little_arrests_indexes)
        if little_arrests_indexes(i) == 1 
            %if its the first element in totalleByClass, then, this block changes to be equal to the second block
            totalleByClass(little_arrests_indexes(i),1) = totalleByClass(little_arrests_indexes(i)+1,1);
        elseif little_arrests_indexes(i) == length(totalleByClass)
            %if its the last element in totalleByClass, then, this block changes to be equal to the end-1 block
            totalleByClass(little_arrests_indexes(i),1) = totalleByClass(little_arrests_indexes(i)-1,1);
        elseif totalleByClass(little_arrests_indexes(i)+1,1) == totalleByClass(little_arrests_indexes(i)-1,1)
           totalleByClass(little_arrests_indexes(i),1) = totalleByClass(little_arrests_indexes(i)+1,1);
        end
    end
    %% Re-sumo los estados contiguos vecinos
    % Luego de la correccion anterior, vuelve a grupar la cantidad de
    % ventanas del tipo de movimiento.
    i = 1;
    while i < length(totalleByClass)
        if totalleByClass(i,1) == totalleByClass(i+1,1)
            totalleByClass(i,2) = totalleByClass(i,2) + totalleByClass(i+1,2);
            totalleByClass(i+1,:) = [];
        else
            i = i + 1;
        end
    end
    %% small_mvmt vs big_mvmt(arrest) = big_mvmt(arrest) && careful, borders may be not accurate
    %hace lo mismo para movimientos medios
    little_small_mvmt_indexes = find(totalleByClass(:,1) == 1 & totalleByClass(:,2) <= thre);
    for i=1:length(little_small_mvmt_indexes)
        if little_small_mvmt_indexes(i) == 1
            %if its the first element in totalleByClass, then, this block changes to be equal to the second block
            totalleByClass(little_small_mvmt_indexes(i),1) = totalleByClass(little_small_mvmt_indexes(i)+1,1);
        elseif little_small_mvmt_indexes(i) == length(totalleByClass)
            %if its the last element in totalleByClass, then, this block changes to be equal to the end-1 block
            totalleByClass(little_small_mvmt_indexes(i),1) = totalleByClass(little_small_mvmt_indexes(i)-1,1);
        elseif totalleByClass(little_small_mvmt_indexes(i)+1,1) == totalleByClass(little_small_mvmt_indexes(i)-1,1)
            totalleByClass(little_small_mvmt_indexes(i),1) = totalleByClass(little_small_mvmt_indexes(i)+1,1);
        end
    end
    %% Re-sumo los estados contiguos vecinos
    i = 1;
    while i < length(totalleByClass)
        if totalleByClass(i,1) == totalleByClass(i+1,1)
            totalleByClass(i,2) = totalleByClass(i,2) + totalleByClass(i+1,2);
            totalleByClass(i+1,:) = [];
        else
            i = i + 1;
        end
    end
    %% big_mvmt vs small_mvmt(arrest) = small_mvmt(arrest) && careful, borders may be not accurate
    %hace lo mismo para movimientos tipo rapido
    thre = thre_little_big_mvmt;
    little_big_mvmt_indexes = find(totalleByClass(:,1) == 2 & totalleByClass(:,2) <= thre);
    for i=1:length(little_big_mvmt_indexes)
        if little_big_mvmt_indexes(i) == 1
            %if its the first element in totalleByClass, then, this block changes to be equal to the second block
            totalleByClass(little_big_mvmt_indexes(i),1) = totalleByClass(little_big_mvmt_indexes(i)+1,1);
        elseif little_big_mvmt_indexes(i) == length(totalleByClass)
            %if its the last element in totalleByClass, then, this block changes to be equal to the end-1 block
            totalleByClass(little_big_mvmt_indexes(i),1) = totalleByClass(little_big_mvmt_indexes(i)-1,1);
        elseif totalleByClass(little_big_mvmt_indexes(i)+1,1) == totalleByClass(little_big_mvmt_indexes(i)-1,1)
            totalleByClass(little_big_mvmt_indexes(i),1) = totalleByClass(little_big_mvmt_indexes(i)+1,1);
        end
    end
    %% Re-sumo los estados contiguos vecinos
    i = 1;
    while i < length(totalleByClass)
        if totalleByClass(i,1) == totalleByClass(i+1,1)
            totalleByClass(i,2) = totalleByClass(i,2) + totalleByClass(i+1,2);
            totalleByClass(i+1,:) = [];
        else
            i = i + 1;
        end
    end
    %% Re escribo el totalle a partir del totalleByClass
    %vuelve a disgregar todo, poniendo el tipo de movimiento que tiene cada ventana
    newTotalle = [];
    for i = 1:length(totalleByClass)
        newTotalle = [newTotalle; ones(totalleByClass(i,2),1)*totalleByClass(i,1)];
    end
    %% Clases and times
    times_clases = nan(length(totalleByClass),3); %times_clases is actually indices_clases
    total = 0;
    for i=1:length(totalleByClass)
        times_clases(i,:) = [totalleByClass(i,1),total+1,total+totalleByClass(i,2)];
        total = total + totalleByClass(i,2);
    end
    %times_clases_in_time_units(:,2:3) = times_clases(:,2:3)*(1/fs_w);
    %% GET TRANSITIONS (INTERMEDIATE MVMTS SURROUNDED BY RED ON ONE SIDE AND BLACK ON THE OTHER)
    interEvts = find(times_clases == 1);
    transitionDU = nan(2,length(interEvts));
    transitionUD = nan(2,length(interEvts));
    jj = 1;
    kk = 1;
    for ii=1:length(interEvts)
        if interEvts(ii) ~= 1 && interEvts(ii) ~= length(times_clases)
            if times_clases(interEvts(ii) - 1) == 0 && times_clases(interEvts(ii) + 1) == 2
                transitionDU(1:2,jj) = times_clases(interEvts(ii),2:3)';
                jj = jj + 1;
            elseif times_clases(interEvts(ii) - 1) == 2 && times_clases(interEvts(ii) + 1) == 0
                transitionUD(1:2,kk) = times_clases(interEvts(ii),2:3)';
                kk = kk + 1;
            end
        end
    end
    transitionDU = transitionDU(:,~any(isnan(transitionDU),1));
    transitionUD = transitionUD(:,~any(isnan(transitionUD),1));
    disp(['getMvmtStds: Number of DU/UD events: ' num2str(length(transitionDU)+length(transitionUD)) ]);
    %% CUT OUT EVENTS BY CLASS
    quiet = times_clases(times_clases(:,1)==0,2:3)';
    intermediate = times_clases(times_clases(:,1)==1,2:3)';
    change = times_clases(times_clases(:,1)==2,2:3)';
    disp(['getMvmtStds: Number of events by class: ' num2str(length(quiet)+length(intermediate)+length(change)) ]);
    
     %% Convierto las salidas a unidades muestreales
     % la ventana del comienzo de segmento tiene el primer punto muestral
     % la ventana del fin de segmento tiene el ult punto muestral 
     
%     varNames = {'transitionDU','transitionUD','quiet','intermediate','change'};
%     
%     for x = 1:length(varNames)
%         salida = eval(varNames{x});
%         TMP = nan(2,length(salida));
%         for f = 1:size(salida,1) %itero sobre las filas (inicio o fin de segmento)
%             for col = 1:size(salida,2) %itero sobre cada columna (segmentos)
%                 if f == 1
%                     if overlap_pts == 0 %no hay overlap
%                         TMP(f,col) = sKyIxs(salida(f,col)) - win;
%                     elseif overlap_pts > 0 && step ~= 1 %hay overlap y step distinto de 1
%                         TMP(f,col) = sKyIxs(salida(f,col)) - win + lostE; 
%                     elseif overlap_pts > 0 && step == 1
%                         TMP(f,col) = sKyIxs(salida(f,col)) - win + lostE;
%                     end
%                     
%                 elseif f == 2 
%                     if overlap_pts == 0
%                         TMP(f,col) = sKyIxs(salida(f,col)) + win -1;
%                     elseif overlap_pts > 0 && step ~= 1 %hay overlap y step distinto de 1
%                         TMP(f,col)     = sKyIxs(salida(f,col)) - win + lostE + step - 1;%
%                     elseif overlap_pts > 0 && step == 1
%                         TMP(f,col) = sKyIxs(salida(f,col)) - win + lostE + step ;
%                     end
%                 end
%             end
%         end
%         %assignin('base',varNames{x},TMP); %NO FUNCIONA
%         if x == 1
%             transitionDU = TMP;
%         elseif x == 2
%             transitionUD = TMP;
%         elseif x == 3
%             quiet = TMP;
%         elseif x == 4
%             intermediate = TMP;
%         elseif x == 5
%             change = TMP;
%         end
%             
%         
%     end
%     clear salida TMP f col x
                
       
    
	%% DEBUGGING
    if debugging
        figure(uk);
        if debugging == 1
            plot(d,t_w_std,newTotalle,'.r');
        elseif debugging == 2
            for jj=1:dof
%                 plot(d,t_w(lostE+1:end-(lostE)),data(lostE+1:end-(lostE),jj),'color',colore(jj,:))
                for i=1:length(change)
                    plot(d,t_w(sKyIxs(change(1,i)):sKyIxs(change(2,i))),...
                        data(sKyIxs(change(1,i)):sKyIxs(change(2,i)),jj),'r')
                end
                for i=1:length(intermediate)
                    plot(d,t_w(sKyIxs(intermediate(1,i)):sKyIxs(intermediate(2,i))),...
                        data(sKyIxs(intermediate(1,i)):sKyIxs(intermediate(2,i)),jj),'g')
                end
                for i=1:length(quiet)
                    plot(d,t_w(sKyIxs(quiet(1,i)):sKyIxs(quiet(2,i))),...
                        data(sKyIxs(quiet(1,i)):sKyIxs(quiet(2,i)),jj),'k')
                end
                for i=1:length(transitionDU)
                    plot(d,t_w(sKyIxs(transitionDU(1,i)):sKyIxs(transitionDU(2,i))),...
                        data(sKyIxs(transitionDU(1,i)):sKyIxs(transitionDU(2,i)),jj),'y')
                end
                for i=1:length(transitionUD)
                    plot(d,t_w(sKyIxs(transitionUD(1,i)):sKyIxs(transitionUD(2,i))),...
                        data(sKyIxs(transitionUD(1,i)):sKyIxs(transitionUD(2,i)),jj),'y')
                end
            end
        end
        figure(uk);
        linkaxes([a b c d],'x');
        axis tight;
        tightfig;
    end
return;