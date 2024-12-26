%Procesamiento señales alineadas de posicion y aceleracion
%pre procesadas con script "pre_process_acel_pos"
%
% requiere funciones: TriggeredAv_M 
%                     segmentador
%                     getMvmtStds
%                     tightfig
%                     

%%UPDATE 24/05/22: Los tiempos de eventos e inicio de mov se exportan en mseg
%                  se incluyen todos los eventos detectados en la matriz eventos. Filtrar luego  450<ITI<24000 y tipo evento(col 269) que no sea NaN

%Indico el Usuario del script para detectar adecuadamente los datos. CECI o MAC
usuario = 'MAC';

%Abro y leo los datos alineados
[X, X_path, archivo_seleccionado] = uigetfile(fullfile(pwd,strcat('*alinea*.mat')),'Seleccione el archivo de datos alineados a procesar');
if archivo_seleccionado == 0
    warning('No seleccionó el archivo .mat con datos para procesar!!\n\n');
    return
end
archivo_datos = fullfile(X_path,X); 

% genero arhivo LOG
diary(fullfile(X_path,'log_Process_acel_pos.txt'));
fprintf('\n***Running Process data Acel y Pos de Video by Marcos Coletti***\n')
fprintf('---Extraccion de tiempos de inicio de mov---\n\n')

%busco el archivo de la matriz correspondiente al archivo de acel elegido
base_tmp = strsplit(X,'_datos_alineados');
base_file = base_tmp{1}; clear base_tmp
       
if contains(usuario,'MAC')
    file_tmp = dir(fullfile(X_path,strcat(base_file,'_MatrizEventos*.mat')));
elseif contains(usuario,'CECI')
    file_tmp = dir(fullfile(X_path,strcat(base_file,'-MatrizEventos*.mat')));
end

if isempty(file_tmp)
    fprintf('\nNo se encontro el archivo MatrizEventos correspondiente al registro de aceleracion elegido: %s \n',X);
    return
else
    archivo_matriz = fullfile(X_path,file_tmp(1).name); clear file_tmp
end

fprintf('Cargando Datos de aceleración alineados y su Matriz Eventos...\n');
load(archivo_datos); %datos de la matriz eventos
load(archivo_matriz);%datos de la matriz de eventos

if contains(usuario,'CECI')
    col_nan = nan(size(EVENTOS,1),20);
    if size(EVENTOS,2)<270 %no esta usando el script de MAC para convertir
        EVENTOS_B = [EVENTOS(:,1:245) col_nan EVENTOS(:,246:end)];
    end
    clear EVENTOS EVENTOS2 col_nan
end

clear archivo_datos archivo_matriz archivo_seleccionado

%  Cargo el Video
file_tmp = dir(fullfile(X_path,strcat(base_file,'_video-B.*')));
if isempty(file_tmp)
    fprintf('\nNo se encontró el archivo de video correspondiente al archivos de datos alineados elegido: %s \n',X);
else
    archivo_video = fullfile(X_path,file_tmp(1).name); clear file_tmp
    fprintf('Cargando Archivo de Video ...\n\n');
    video = VideoReader(archivo_video);
end

clear archivo_video X

% verifico si hay cargados datos de video y posicion
if exist('pos','var')
    flag_pos = 1;
else
    flag_pos = 0;
end

% Extraigo los datos necesarios de los eventos [tipo t_entrada_puerto]
fm = 32.556; %frecuencia de muestreo del NX para los datos de la matriz

%restricciones de eventos a emplear para el analisis
ITI_min = 450; %tiempo minimo del ITI [mseg]
ITI_max = 240000; %4min
evt_idx = (EVENTOS_B(:,270)>ITI_min & EVENTOS_B(:,270)<ITI_max & ~isnan(EVENTOS_B(:,269))); %excluyo los que estan fueros del ITI max y min y con identificacion de evento NaN

evt_todos_filt(:,1) = EVENTOS_B(evt_idx,269); %col1 tiene el tipo de evento a tiempo
evt_todos_filt(:,2)  = EVENTOS_B(evt_idx,1)/1000; %col2 tiene el tiempo de entrada al puerto [seg] en el NX

evt_todos(:,1) = EVENTOS_B(:,269); %col1 tiene el tipo de evento a tiempo
evt_todos(:,2)  = EVENTOS_B(:,1)/1000; %col2 tiene el tiempo de entrada al puerto [seg] en el NX

clear ITI_min evt_idx

%%  Pre procesamiento de la señal de aceleración
acel_mag_temp = sqrt(sum(acel.data(:,1).^2 + acel.data(:,2).^2 + acel.data(:,3).^2, 2)); %magnitud de aceleracion

% Diseño y aplicacion del filtro
% HP filter accelerometer data
samplePeriod = 1/acel.fm;

filtCutOff = 0.25; %frec de corte del PA
filtHPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(1, filtHPF, 'high');
acel_magFilt = filtfilt(b, a, acel_mag_temp);
acel_x_filt = filtfilt(b, a, acel.data(:,1));
acel_y_filt = filtfilt(b, a, acel.data(:,2));
acel_z_filt = filtfilt(b, a, acel.data(:,3));


% LP filter accelerometer data
filtCutOff = 6;%7.9;
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(1, filtLPF, 'low');

acel_mag = filtfilt(b, a, acel_magFilt); %señal de mag de acel filtrada

acel_data(:,1) = filtfilt(b, a, acel_x_filt);
acel_data(:,2) = filtfilt(b, a, acel_y_filt);
acel_data(:,3) = filtfilt(b, a, acel_z_filt);

%señales de acel disponibles para analizar
%acel_mag --> mag de acel entre 0.25 y 6 Hz
%acel_data --> acel x y z, filt entre 0.25 y 6 Hz

clear acel_mag_abs samplePeriod a b filtCutOff filtHPF  filtLPF stationary acel_x_filt acel_y_filt acel_z_filt acc_magFilt


%% Genero los datos de trigger average para graficar
if flag_pos
    pos_data = pos.data(:,1:2);
end

%tamaño de la ventana alrededor del evento [segundos]
t1 = 3;
t2 = 2;

nBefore_acel = round(t1*acel.fm); %segundos antes de la entrada
nAfter_acel = round(t2*acel.fm); %seg post a la entrada

if flag_pos
    nBefore_pos = round(t1*pos.fm);
    nAfter_pos = round(t2*pos.fm);
end

%separo los tipo de eventos entre Timely, noTimely y Limbo
timely_idx = find(evt_todos_filt(:,1) == 1 | evt_todos_filt(:,1) == 2 | evt_todos_filt(:,1) == 3); 
limbo_idx = find(evt_todos_filt(:,1) == 6);
no_timely_idx =  find(evt_todos_filt(:,1) == 4 | evt_todos_filt(:,1) == 5);

%determinacion de los indices de ocurrencia de los eventos a la fm de cada
%registro
T_acel = round(evt_todos_filt(:,2)*acel.fm); %tiempo de todos los eventos en el registro de acel
T_timely_acel = round(evt_todos_filt(timely_idx,2)*acel.fm);
T_no_timely_acel = round(evt_todos_filt(no_timely_idx,2)*acel.fm);
T_limbo_acel = round(evt_todos_filt(limbo_idx,2)*acel.fm);

if flag_pos
    T_pos = round(evt_todos_filt(:,2)*pos.fm);
    T_timely_pos = round(evt_todos_filt(timely_idx,2)*pos.fm);
    T_no_timely_pos = round(evt_todos_filt(no_timely_idx,2)*pos.fm);
    T_limbo_pos = round(evt_todos_filt(limbo_idx,2)*pos.fm);
end

%trigger todos los eventos de magnitude acel y pos XY 
[Avs_acel_mag_todos, StdErr_acel_mag_todos, Waves_acel_mag_todos] = TriggeredAv_M(acel_mag, nBefore_acel, nAfter_acel, T_acel); 
if flag_pos
    [Avs_pos_todos, StdErr_pos_todos, Waves_pos_todos] = TriggeredAv_M(pos_data, nBefore_pos, nAfter_pos, T_pos); 
end

%trigger todos eventos Timely, unTimely y limbo de ael magnitude y pos XY 
[Avs_acel_t_mag, StdErr_acel_t_mag, Waves_acel_t_mag] = TriggeredAv_M(acel_mag, nBefore_acel, nAfter_acel, T_timely_acel); 
[Avs_acel_ut_mag, StdErr_acel_ut_mag, Waves_acel_ut_mag] = TriggeredAv_M(acel_mag, nBefore_acel, nAfter_acel, T_no_timely_acel);
if ~isempty(T_limbo_acel) %chequeo que haya algun limbo
    [Avs_acel_limbo_mag, StdErr_acel_limbo_mag, Waves_acel_limbo_mag] = TriggeredAv_M(acel_mag, nBefore_acel, nAfter_acel, T_limbo_acel); 
end
if flag_pos
    [Avs_pos_t, StdErr_pos_t, Waves_pos_t] = TriggeredAv_M(pos_data, nBefore_pos, nAfter_pos, T_timely_pos);
    [Avs_pos_ut, StdErr_pos_ut, Waves_pos_ut] = TriggeredAv_M(pos_data, nBefore_pos, nAfter_pos, T_no_timely_pos);
    if ~isempty(T_limbo_acel) %chequeo que haya algun limbo
        [Avs_pos_limbo, StdErr_pos_limbo, Waves_pos_limbo] = TriggeredAv_M(pos_data, nBefore_pos, nAfter_pos, T_limbo_pos);
    end
end
%% -- Graficos------
fig_acel = figure();clf
set(fig_acel, 'Position', [100, 100, 1300, 850])
sgtitle({'Magnitud de Aceleración promedio alineada a la entrada al puerto'});

tiempo_acel = (-nBefore_acel:nAfter_acel)/acel.fm;

subplot(3,2,1)
plot(tiempo_acel,Avs_acel_mag_todos - mean(Avs_acel_mag_todos),'LineWidth',1.1)
hold on
plot([0,0],ylim','k','LineWidth',1.1); %entrada al puerto
hold on
plot([0.2,0.2],ylim','g','LineWidth',1.1); %entrada al puerto
lgd = legend('Acel Magnitude','Entrada puerto','LED');
set(lgd,'Location','northwest');

title('Acel Magnitude - Todos los Eventos')

subplot(3,2,3)
plot(tiempo_acel,Avs_acel_t_mag - mean(Avs_acel_t_mag),'LineWidth',1.1)
hold on
plot([0,0],ylim','k','LineWidth',1.1); %entrada al puerto
hold on
plot([0.2,0.2],ylim','g','LineWidth',1.1); %entrada al puerto
lgd = legend('Acel Magnitude','Entrada puerto','LED');
set(lgd,'Location','northwest');

title('Acel Magnitude - Eventos Timely')

subplot(3,2,5)
plot(tiempo_acel, Avs_acel_ut_mag - mean(Avs_acel_ut_mag),'LineWidth',1.1);
hold on
plot([0,0],ylim','k','LineWidth',1.1); %entrada al puerto
hold on
plot([0.2,0.2],ylim','g','LineWidth',1.1); %entrada al puerto
lgd = legend('Acel Magnitude','Entrada puerto','LED');
set(lgd,'Location','northwest');
title('Acel Magnitude - Eventos uTimely')

if flag_pos
    tiempo_pos = (-nBefore_pos:nAfter_pos)/pos.fm;
    subplot(3,2,2)
    plot(tiempo_pos,Avs_pos_todos,'LineWidth',1.1)
    hold on
    plot([0,0],ylim','k','LineWidth',1.1); %entrada al puerto
    hold on
    plot([0.2,0.2],ylim','g','LineWidth',1.1); %entrada al puerto
    legend('X','Y','Entrada puerto')
    title('Position XY - Todos los eventos Eventos')
    
    subplot(3,2,4)
    plot(tiempo_pos,Avs_pos_t,'LineWidth',1.1)
    hold on
    plot([0,0],ylim','k','LineWidth',1.1); %entrada al puerto
    hold on
    plot([0.2,0.2],ylim','g','LineWidth',1.1); %entrada al puerto
    legend('X','Y','Entrada puerto')
    title('Position XY - Eventos Timely')
    
    subplot(3,2,6)
    plot(tiempo_pos,Avs_pos_ut,'LineWidth',1.1)
    hold on
    plot([0,0],ylim','k','LineWidth',1.1); %entrada al puerto
    hold on
    plot([0.2,0.2],ylim','g','LineWidth',1.1); %entrada al puerto
    legend('X','Y','Entrada puerto')
    title('Position XY - Eventos uTimely')
end

saveas(fig_acel,fullfile(X_path,strcat('acel_mag_',base_file)),'jpeg');
fprintf('Se exportó la imagen "Mag de Acel alineada a la entrada al puerto": %s\n',strcat('acel_mag_',base_file,'.jpg'));

clear Avs_* StdErr_* Waves_* nAfter* nBefore* limbo_idx magnitude no_timely_idx T_* tiempo timely_idx fig_acel lgd


%% ------ Aplico script para deteccion de inicio de movimiento
% %Calculo los cambios de movimiento para acel y pos

fprintf('\nAplicando algoritmo de deteccion de movimiento por umbrales...\n');
clear transitionDU* transitionUD* quiet* intermediate* change*

if contains(usuario,'MAC')
    [quiet_acel, intermediate_acel, change_acel, transitionDU_acel, transitionUD_acel,idx_ventana_acel,win_acel,overlap_acel] = getMvmtStds(acel_data(:,3),[],[],'fs_w',acel.fm,'debugging',1,...
        'std_win',10,'overlap_pts',0,...
        'stdX_threshold',2.3,'stdX_intermediate',1.3,...
        'stdY_threshold',6.5,'stdY_intermediate',2.9,...
        'stdZ_threshold',4.5,'stdZ_intermediate',2.9,...
        'thre_little_big_mvmt',1,'thre_little_arrests',1);
elseif contains(usuario,'CECI')
%     [quiet_acel, intermediate_acel, change_acel, transitionDU_acel, transitionUD_acel,idx_ventana_acel,win_acel,overlap_acel] = getMvmtStds(acel_data(:,1),acel_data(:,2),acel_data(:,3),'fs_w',acel.fm,'debugging',1,...
%         'std_win',10,'overlap_pts',0,...
%         'stdX_threshold',6.55,'stdX_intermediate',2.8,...
%         'stdY_threshold',6.5,'stdY_intermediate',3.1,...
%         'stdZ_threshold',2.5,'stdZ_intermediate',1.1,...
%         'thre_little_big_mvmt',1,'thre_little_arrests',1);
    

    umbral_alto = 5.5;
    umbral_bajo = 2.5;
    
    fprintf('Se utilizaron los siguientes umbrales para el algortimo de deteccion de mov:\n');
    fprintf('Umbral quieto-mov intermedio: %.2f,  Umbral mov intermedio - mov rapido: %.2f \n\n',umbral_bajo,umbral_alto);
    
    [quiet_acel, intermediate_acel, change_acel, transitionDU_acel, transitionUD_acel,idx_ventana_acel,win_acel,overlap_acel] = getMvmtStds(acel_mag,[],[],'fs_w',acel.fm,'debugging',1,...
        'std_win',10,'overlap_pts',0,...
        'stdX_threshold',umbral_alto,'stdX_intermediate',umbral_bajo,...
        'thre_little_big_mvmt',1,'thre_little_arrests',1);   

   clear umbral_*
end






% ---- Conversion de los indices de ventanas a unidades muestrales-------
    % la ventana del comienzo de segmento tiene el primer punto muestral
    % la ventana del fin de segmento tiene el ult punto muestral 
    
varNames = who('transitionDU*','transitionUD*','quiet*','intermediate*','change*');

for x = 1:length(varNames)
    salida = eval(varNames{x});
    %chequeo que señal es la que voy a convertir
    if contains(varNames{x},'pos')
        win = win_pos;
        overlap = overlap_pos;
        idx_ventana = idx_ventana_pos;
    elseif contains(varNames{x},'acel') && ~contains(varNames{x},'mag')
        win = win_acel;
        overlap = overlap_acel;
        idx_ventana = idx_ventana_acel;
    elseif contains(varNames{x},'acel') && contains(varNames{x},'_mag')
        win = win_acel_mag;
        overlap = overlap_acel_mag;
        idx_ventana = idx_ventana_acel_mag;
    end
    
    step = 2*win-overlap;
    lostE =  floor(overlap/2);
    
    TMP = nan(2,length(salida));
    try
        for f = 1:size(salida,1) %itero sobre las filas (inicio o fin de segmento)
            for col = 1:size(salida,2) %itero sobre cada columna (segmentos)
                if strfind(varNames{x},'transition')  %hago otra correccion para los indices de ventana de transicion
                    if f == 1
                        TMP(f,col) = idx_ventana(salida(f,col)); %el punto de inicio va a ser la mitad de la ventana
                    elseif f == 2
                        TMP(f,col) = idx_ventana(salida(f,col)) + win -1; %el punto de fin va a ser el fin de la ventana
                    end
                else %corrijo los indices de los tipos de mov quiet, intermediate y change
                    if f == 1
                        if overlap == 0 %no hay overlap
                            TMP(f,col) = idx_ventana(salida(f,col)) - win;
                        elseif overlap > 0 && step ~= 1 %hay overlap y step distinto de 1
                            TMP(f,col) = idx_ventana(salida(f,col)) - win + lostE;
                        elseif overlap > 0 && step == 1
                            TMP(f,col) = idx_ventana(salida(f,col)) - win + lostE;
                        end
                        
                    elseif f == 2
                        if overlap == 0 %no hay overlap
                            TMP(f,col) = idx_ventana(salida(f,col)) + win -1;
                        elseif overlap > 0 && step ~= 1 %hay overlap y step distinto de 1
                            TMP(f,col)     = idx_ventana(salida(f,col)) - win + lostE + step - 1;%
                        elseif overlap > 0 && step == 1
                            TMP(f,col) = idx_ventana(salida(f,col)) - win + lostE + step ;
                        end
                    end
                end
            end
        end
    catch
        fprintf('Error en la conversion de indices de ventana a muestras para los datos: %s\n',varNames{x});
    end
    %assignin('base',varNames{x},TMP);
    
assignin('base',strcat(varNames{x},'_c'),TMP);
  
end
clear x salida TMP f col
fprintf('\nSe convertieron exitosamente las ventanas a indices muestrales.\n\n');


%% Recorto los datos de deteccion de inicio de mov en una ventana de tiempo de acel confiable 
 % en funcion del grafico del algoritmo de deteccion de incio de mov
 
inicio_intervalo = 0; % [seg] 0 para tomar desde el comienzo
fin_intervalo = 8000; % [seg] 8000 para tomar hasta el final

n_inicio_intervalo = inicio_intervalo*acel.fm;
n_fin_intervalo = fin_intervalo*acel.fm;

% solo recorto la acel porque es la que uso!!!

idx_inicio_intervalo = find(quiet_acel_c(1,:) > n_inicio_intervalo);
idx_inicio_intervalo = idx_inicio_intervalo(1);

idx_fin_intervalo = find(quiet_acel_c(2,:) < n_fin_intervalo);
idx_fin_intervalo = idx_fin_intervalo(end);

if fin_intervalo < 8000 %se esta analizando hasta el final del registro
    fprintf('Procesando solo los inicio de mov detectados entre %d y %d segundos del registro.\n\n',inicio_intervalo, fin_intervalo);
elseif fin_intervalo >= 8000 %se esta analizando hasta el final del registro
    if inicio_intervalo == 0 %se esta analizando desde el comienzo del registro
         fprintf('Procesando todos los inicio de mov detectados del registro.\n\n');
    else
        fprintf('Procesando solo los inicio de mov detectados entre %d segundos y el final del registro.\n\n',inicio_intervalo);
    end
end

quiet_acel_c =  quiet_acel_c(:,idx_inicio_intervalo:idx_fin_intervalo);


clear inicio_intervalo fin_intervalo n_* idx_inicio_intervalo idx_fin_intervalo


%% ---- Metricas ----- Contabilizo los eventos con inicios de mov detectados
clear init_detected
t_previo = 1.2; %tiempo previo a la entrada al puerto para detectar un inicio de mov [seg]

%features a comprobar
var_names_features = {'quiet_acel_c'};

%filtrado del tipo de eventos., genero vectores logicos


fig_trig = figure(15);clf; %figura para los graficos de trigger average
set(fig_trig, 'Position', [300, 400, 800, 450])

for x = 1:length(var_names_features)
    if contains(var_names_features{x},'transitionDU') %elijo el primer valor del segmento detectado
        feature = eval(var_names_features{x})';
        feature_trigger = feature(:,1);
        feature = feature(:,1)*(1/acel.fm);
    elseif contains(var_names_features{x},'quiet') %elijo el ultimo valor del segmento de estado quieto detectado
        feature = eval(var_names_features{x})';
        feature_trigger = feature(:,2);
        feature = feature(:,2)*(1/acel.fm);
    end
    
    %genero una struct de nombre init_detected (i) con i = num de features
    %a probar. 
    init_detected(x).name = var_names_features{x};
    init_detected(x).tiempos = nan(size(evt_todos,1),1);
    init_detected(x).raros{size(evt_todos,1),1} = nan;
    init_detected(x).evt_todos = evt_todos;
    
    for i = 1:size(evt_todos,1)
        try
            init_idx = find(feature >= (evt_todos(i,2) - t_previo) & feature < evt_todos(i,2)); %busco si hay algun iicio detectado entre el tiempo del evento y un t_previo asignado
        catch
            if isnan(evt_todos(i,2))
                fprintf('ERROR: El tiempo de entrada al puerto para el evento %d es NaN. Abortando...\n\n',i);
                return
            else
                fprintf('ERROR: Se produji un error al detectar el inicio de mov para el evento: %d. Abortando...\n\n',i);
                return
            end
        end
        %guardo el numero de evento detectado y el tiempo de deteccion del
        %inicio del mov. Si no tiene, vale NaN
        if ~isempty(init_idx) %verifico que haya encontrado al menos un valor
            if length(init_idx) == 1 %si tiene un solo valor
                 init_detected(x).tiempos(i) = feature(init_idx); %guardo el valor del tiempo de inicio
            elseif length(init_idx) > 1 %se encontro mas de un tiempo de inicio
                init_detected(x).raros{i} = feature(init_idx);
            end
        end
    end
    
    %grafico el trigger average del promedio de inicio de mov de los event en que se detecto para cada feature
    subplot(1,length(var_names_features),x), hold on;
    inicio = round(t1*acel.fm); %[muestras], t1 es tiempo de inicio definido para el analisis de la det de mov
    fin = round(t2*acel.fm); %[muestras], idem que t1 para el fin del segmento de analisis

    [Avs,Error] = TriggeredAv_M(acel_mag, inicio, fin, feature_trigger); %saco el promedio y SD de 
    plot([-inicio:fin]/acel.fm,Avs,'r-','LineWidth',1.2, 'DisplayName','Acel Magnitude')
    plot([-inicio:fin]/acel.fm,Avs+Error,'--','Color',[1 0.45 0.45],'LineWidth',1.2,'HandleVisibility','off')
    plot([-inicio:fin]/acel.fm,Avs-Error,'--','Color',[1 0.45 0.45],'LineWidth',1.2,'HandleVisibility','off')
    plot([0,0],ylim','k','LineWidth',1.1,'DisplayName','Inicio Mov'); %inicio de mov
    title(['Trigger Average Magnitud Aceleración - ' var_names_features{x}]);
    lgd = legend;
    set(lgd,'Location','northwest');
    clear Avs Error

end

saveas(fig_trig,fullfile(X_path,strcat('trigger_avg_',base_file)),'jpeg');
fprintf('Se exportó la imagen "Trigger Average de Mag de Acel alineada al inicio de mov": %s\n',strcat('trigger_avg_',base_file,'.jpg'));

clear i x init_idx inicio fin clear fig_trig

 
%reporte de cant de eventos en q se detectaron el inicio, grafico de histograma y reporte media y SD de los tiempos de inicio,
fprintf('\n----------------- Reporte ----------------\n');



for j = 1:length(var_names_features)
    init_correct_idx = ~isnan(init_detected(j).tiempos); %indices eventos con inicio correcto
    evt_tot = size(evt_todos,1); %num de evt totales
    dif_tiempo_init = evt_todos(:,2) - init_detected(j).tiempos; %tiempo absoluto entre inicio de mov y entrada al puerto
    init_incorrect_idx = ~isnan(cell2mat(init_detected(j).raros)); %index eventos con inicios incorrectamente detectados
    init_not_detected_idx = isnan(init_detected(j).tiempos); %indices eventos sin deteccion de inicio de mov
    evt_not_detected = find(init_not_detected_idx); %eventos sin deteccion de mov
       
    evt_timely = (evt_todos(:,1) == 1 | evt_todos(:,1) == 2 | evt_todos(:,1) == 3 | evt_todos(:,1) == 6) & init_correct_idx; %identifico evt 1,2,3 y 6 (a tiempo, 6 es limbo)
    evt_utimely = (evt_todos(:,1) == 4 | evt_todos(:,1) == 5) & init_correct_idx;%identifico los evt 4 y 5, no timely
    tot_timely =  (evt_todos(:,1) == 1 | evt_todos(:,1) == 2 | evt_todos(:,1) == 3 | evt_todos(:,1) == 6);
    tot_utimely = (evt_todos(:,1) == 4 | evt_todos(:,1) == 5);

    fprintf('Se encontraron %d inicios para un total de %d eventos (equivale al %.2f %c). Para el feature: %s \n',sum(init_correct_idx),evt_tot,100*(sum(init_correct_idx)/evt_tot),'%',init_detected(j).name);
    fprintf('Hay %d (%.2f %c)eventos a TIEMPO y %d (%.2f %c) eventos PREMATUROS\n', sum(evt_timely),100*(sum(evt_timely)/sum(tot_timely)),'%',sum(evt_utimely),100*(sum(evt_utimely)/sum(tot_utimely)),'%');
    fprintf('La media de tiempo es de %.2f segundos; SD: %.2f.\n',nanmean(dif_tiempo_init),nanstd(dif_tiempo_init));
    fprintf('Hay %d eventos con mas de un inicio detectado (equivale al %.2f %c).\n',sum(init_incorrect_idx),100*(sum(init_incorrect_idx)/evt_tot),'%');
    fprintf('No se detecto el inicio de mov en %d eventos (equivale al %.2f %c).\n\n ',sum(init_not_detected_idx),100*(sum(init_not_detected_idx)/evt_tot),'%');
    
    init_detected(j).evt_not_detected = evt_not_detected; %numero de evento con inicio sin detectar
    
    %Genero el histograma de los tiempos aboslutos de inicio de mov
    fig_hist = figure(20+j); clf; %figura para los graficos de los histogramas del tiempo de inicio de mov
    set(fig_hist, 'Position', [150, 250, 1200, 700]) %[350, 450, 1200, 350]
    title(['Histogram de tiempo de inicio de movimiento para feature: ' var_names_features{j}])
    
    subplot(2,2,1); %subplot(1,length(var_names_features),j)
    histogram(dif_tiempo_init,[0:0.05:t_previo],'FaceColor',[0.78 0.135 0.94]);
    ylabel('Cant de Eventos')
    xlabel('Tiempo de inicio[seg]')
    title('Tiempo de inicio: todos los eventos');

    subplot(2,2,2); %subplot(1,length(var_names_features),j)
    histogram(dif_tiempo_init(evt_timely),[0:0.05:t_previo],'FaceColor',[0.78 0.135 0.94]);
    ylabel('Cant de Eventos')
    xlabel('Tiempo de inicio[seg]')
    title('Tiempo de inicio: Timely');

    subplot(2,2,4); %subplot(1,length(var_names_features),j)
    histogram(dif_tiempo_init(evt_utimely),[0:0.05:t_previo],'FaceColor',[0.78 0.135 0.94]);
    ylabel('Cant de Eventos')
    xlabel('Tiempo de inicio[seg]')
    title('Tiempo de inicio: uTimely');
%legend('Tiempo inicio de mov')
 
    
    
end
saveas(fig_hist,fullfile(X_path,strcat('histogram_',base_file)),'jpeg');
fprintf('Se exportó la imagen "Histogramas de tiempo de inicio de mov": %s\n',strcat('histogram_',base_file,'.jpg'));

clear fig_hist evt_tot dif_tiempo_init init_correct_idx init_not_detected_idx 


%-------------------------------------
%---Acondiciono y Exporto todo----------------------
%-------------------------------------

%paso todos los tiempos a [mseg]
for c = 1:length(var_names_features)
    init_detected(c).tiempos = init_detected(c).tiempos*1000;
    init_detected(c).evt_todos = [init_detected(c).evt_todos(:,1) init_detected(c).evt_todos(:,2)*1000];
end

archivo_salida = fullfile(X_path,strcat(base_file,'_init_time.mat'));
save(archivo_salida,'init_detected');

fprintf('\n-----Se exportaron correctamente los datos!-----\n');


% Cierro arhivo LOG
diary off
   


%% Graficos en Eventos puntuales - Generacion de video

%tamaño de la ventana alrededor del evento [segundos]
t1 = 2;
t2 = 2;

% ***PARAMETROS***
E = 195;%evt_not_detected(30); %evento

t1 = t1; %tamaño de la venatana a analizar. Se utilizan los tiempos t1,t2 definidos antes
t2 = t2;

% tiempo salida puerto en el evento anterior
if E > 1 %si no es el evento 1
    TS = (EVENTOS_B(E,1)-EVENTOS_B(E-1,267))/1000;
else
    TS = nan; %para el evento 1
end

% Cargo los colores
colores = [0 0 1;0 0 0;0 .5 .5;1 0 0;0 1 0;1 1 0]; %(1azul,2negro,3gris-verdoso,4rojo,5verde,6amarillo

% tipos de eventos
if evt_todos(E,1) == 1
    tipo_evento = 'TR';
elseif evt_todos(E,1) == 2
    tipo_evento = 'TuR';
elseif evt_todos(E,1) == 3
    tipo_evento = 'T < 8L';
elseif evt_todos(E,1) == 4
    tipo_evento = 'uT > 8L';
elseif evt_todos(E,1) == 5
    tipo_evento = 'uT < 8L';
elseif evt_todos(E,1) == 6
    tipo_evento = 'Limbo';
end

%-------------------------------

if flag_pos
    nE_pos = round(evt_todos(E,2)*pos.fm); %indice del E en los datos de pos
end
    nE_acel = round(evt_todos(E,2)*acel.fm); %indice del E en los datos de acel

nBefore_acel = round(t1*acel.fm); %n muestras antes en los datos de acel
nAfter_acel = round(t2*acel.fm); %n muestras despues en los datos de acel

if flag_pos
    nBefore_pos = round(t1*pos.fm); %muestras de pos
    nAfter_pos = round(t2*pos.fm);
    
    %tiempo_pos = (- t1:1/pos.fm:t2); %el 0 queda en el medio de 1/fm
    tiempo_pos = (-nBefore_pos:nAfter_pos)/pos.fm; %vector de tiempo de posicion
      
    n_pos = (nE_pos - nBefore_pos:nE_pos + nAfter_pos)'; %rango de muestras de pos
end

tiempo_acel = (-nBefore_acel:nAfter_acel)/acel.fm; %vector de tiempo de acel
n_acel = (nE_acel - nBefore_acel:nE_acel + nAfter_acel)'; %rango de muestras de acel

tE_acel = nE_acel/acel.fm;
%tE_pos = nE_pos/pos.fm;
fprintf('\nEl tiempo del evento: %d es: %4.2f seg en el acel.\n\n',E,tE_acel);
%s = seconds(tE_acel+15);s.Format="hh:mm:ss";s


%-----------------grafico de mag de aceleracion para un evento puntual-----------
fig_evt = figure(30);clf;hold on
set(fig_evt, 'Position', [100, 100, 1300, 850])
sgtitle({'Comparación Mag de Acel vs Mag de Acel filtrada',['Magnitud Aceleración - Evento Nº ',num2str(E),'(',tipo_evento,')',', marcando período quieto']});


% ******* figura Acel magnitude tratatada
subplot(2,2,1);hold on
plot(tiempo_acel,acel_mag(n_acel),'c','LineWidth',1.2)
plot([0,0],ylim','--k','LineWidth',1.3); %entrada al puerto
plot([0.2,0.2],ylim','color',colores(3,:),'LineWidth',1.3); %encendido led
if -TS >= -nBefore_acel/acel.fm
    plot([0-TS, 0-TS],ylim','-.k','LineWidth',1.2,'DisplayName','Salida Puerto'); %salida del puerto
end
legend('Acel Magnitude','Entrada puerto','LED')
title('Acel Magnitude procesada')

for i = 1:3
    if i == 1
        data_points = quiet_acel_c;
        color = 1; %azul
    elseif i== 2
        data_points = intermediate_acel_c;
        color = 5;
    elseif i == 3
        data_points = change_acel_c;
        color = 4;
    end
    
    [data_mov, tiempo_mov,idx_start_end] = segmentador(data_points, n_acel, acel_mag(n_acel), tiempo_acel);
    
    if i == 1 %grafico período quieto
        plot(tiempo_mov,data_mov(),'color', colores(color,:),'LineWidth',1.5,'HandleVisibility','off'); %grafica en color azul los segmentos de estado quieto
        alto = ylim;
        basevalue = alto(1); %elijo el limite inferior del grafico 
        if sum(~isnan(data_mov)) > 0 %compruebo que hay algun segmento de estado quieto
            seg_logical = ~isnan(data_mov);
            ones_seg = diff(~isnan(data_mov)); %busco los inicios de los segmentos quietos
            if seg_logical(1) == 1 %si el ind=1 vale 1, ya venia quieto de antes(por fuera de la ventana graficada)
                ones_seg(1) = 1;
            elseif seg_logical(end) == 1 %si el final vale 1, siegue quieto por fuera de la ventana graficada
                ones_seg(end) = 1;
            end
            try
                transition_seg(:,1) = find(ones_seg == 1) + 1; %busco los inicios de seg de transicion
                transition_seg(:,2) = find(ones_seg == -1); %busco los finales de seg de transicion
                for z = 1:size(transition_seg,1) %itero entre los seg quietos que encontró
                    data_transition = nan(length(data_mov),1);
                    data_transition(transition_seg(z,1):transition_seg(z,2))=alto(2);
                    area(tiempo_mov,data_transition,basevalue,'FaceColor',colores(color,:),'FaceAlpha',0.2,'EdgeColor','none','DisplayName','Período quieto'); %grafico un rectangulo marcando el segmento quieto
                end
            catch
                fprintf('El segmento de transicion esta fuera del intervalo analizado del evento! Registro Magnitud de Aceleración procesada\n')
            end
        else
            fprintf('No hay segmentos de transicion en el intervalo analizado del evento! Registro Magnitud de Aceleración procesada\n')
        end
    else
        plot(tiempo_mov,data_mov(),'color', colores(color,:),'LineWidth',1.5,'HandleVisibility','off');
    end
end
%legend('X','Entrada puerto','LED','Quiet','Intermediate','Change','Transition Area');
clear i color alto ones_seg transition_seg z data_mov tiempo_mov


% ******* figura Acel magnitude original
subplot(2,2,2);hold on
plot(tiempo_acel,acel_data(n_acel,:),'c','LineWidth',1.2)
plot([0,0],ylim','--k','LineWidth',1.3); %entrada al puerto
plot([0.2,0.2],ylim','color',colores(3,:),'LineWidth',1.3); %encendido led
if -TS >= -nBefore_acel/acel.fm
    plot([0-TS, 0-TS],ylim','-.k','LineWidth',1.2,'DisplayName','Salida Puerto'); %salida del puerto
end
legend('Acel Magnitude','Entrada puerto','LED')
title('Acel Magnitude original')

for i = 1:3
    if i == 1
        data_points = quiet_acel_c;
        color = 1; %azul
    elseif i== 2
        data_points = intermediate_acel_c;
        color = 5;
    elseif i == 3
        data_points = change_acel_c;
        color = 4;
    end
    
    [data_mov, tiempo_mov,idx_start_end] = segmentador(data_points, n_acel, acel_data(n_acel,:), tiempo_acel);
    
    if i == 1 %grafico período quieto
        plot(tiempo_mov,data_mov(),'color', colores(color,:),'LineWidth',1.5,'HandleVisibility','off'); %grafica en color azul los segmentos de estado quieto
        alto = ylim;
        basevalue = alto(1); %elijo el limite inferior del grafico 
        if sum(~isnan(data_mov)) > 0 %compruebo que hay algun segmento de estado quieto
            seg_logical = ~isnan(data_mov);
            ones_seg = diff(~isnan(data_mov)); %busco los inicios de los segmentos quietos
            if seg_logical(1) == 1 %si el ind=1 vale 1, ya venia quieto de antes(por fuera de la ventana graficada)
                ones_seg(1) = 1;
            elseif seg_logical(end) == 1 %si el final vale 1, siegue quieto por fuera de la ventana graficada
                ones_seg(end) = 1;
            end
            try
                transition_seg(:,1) = find(ones_seg == 1) + 1; %busco los inicios de seg de transicion
                transition_seg(:,2) = find(ones_seg == -1); %busco los finales de seg de transicion
                for z = 1:size(transition_seg,1) %itero entre los seg quietos que encontró
                    data_transition = nan(length(data_mov),1);
                    data_transition(transition_seg(z,1):transition_seg(z,2))=alto(2);
                    area(tiempo_mov,data_transition,basevalue,'FaceColor',colores(color,:),'FaceAlpha',0.2,'EdgeColor','none','DisplayName','Período quieto'); %grafico un rectangulo marcando el segmento quieto
                end
            catch
                fprintf('El segmento de transicion esta fuera del intervalo analizado del evento! Registro Magnitud de Aceleración\n')
            end
        else
            fprintf('No hay segmentos de transicion en el intervalo analizado del evento! Registro Magnitud de Aceleración\n')
        end
    else
        plot(tiempo_mov,data_mov(),'color', colores(color,:),'LineWidth',1.5,'HandleVisibility','off');
    end
end
%legend('X','Entrada puerto','LED','Quiet','Intermediate','Change','Transition Area');
clear i color alto ones_seg transition_seg z data_mov tiempo_mov

% 
% % ******* figura Acel magnitude original
% subplot(2,2,3);hold on
% plot(tiempo_acel,acel_filt(n_acel),'c','LineWidth',1.2)
% plot([0,0],ylim','--k','LineWidth',1.3); %entrada al puerto
% plot([0.2,0.2],ylim','color',colores(3,:),'LineWidth',1.3); %encendido led
% if -TS >= -nBefore_acel/acel.fm
%     plot([0-TS, 0-TS],ylim','-.k','LineWidth',1.2,'DisplayName','Salida Puerto'); %salida del puerto
% end
% legend('Acel Magnitude','Entrada puerto','LED')
% title('Acel Magnitude procesada')
% 
% for i = 1:3
%     if i == 1
%         data_points = quiet_acel_mag_c;
%         color = 1; %azul
%     elseif i== 2
%         data_points = intermediate_acel_mag_c;
%         color = 5;
%     elseif i == 3
%         data_points = change_acel_mag_c;
%         color = 4;
%     end
%     
%     [data_mov, tiempo_mov,idx_start_end] = segmentador(data_points, n_acel, acel_filt(n_acel), tiempo_acel);
%     
%     if i == 1 %grafico período quieto
%         plot(tiempo_mov,data_mov(),'color', colores(color,:),'LineWidth',1.5,'HandleVisibility','off'); %grafica en color azul los segmentos de estado quieto
%         alto = ylim;
%         basevalue = alto(1); %elijo el limite inferior del grafico 
%         if sum(~isnan(data_mov)) > 0 %compruebo que hay algun segmento de estado quieto
%             seg_logical = ~isnan(data_mov);
%             ones_seg = diff(~isnan(data_mov)); %busco los inicios de los segmentos quietos
%             if seg_logical(1) == 1 %si el ind=1 vale 1, ya venia quieto de antes(por fuera de la ventana graficada)
%                 ones_seg(1) = 1;
%             elseif seg_logical(end) == 1 %si el final vale 1, siegue quieto por fuera de la ventana graficada
%                 ones_seg(end) = 1;
%             end
%             try
%                 transition_seg(:,1) = find(ones_seg == 1) + 1; %busco los inicios de seg de transicion
%                 transition_seg(:,2) = find(ones_seg == -1); %busco los finales de seg de transicion
%                 for z = 1:size(transition_seg,1) %itero entre los seg quietos que encontró
%                     data_transition = nan(length(data_mov),1);
%                     data_transition(transition_seg(z,1):transition_seg(z,2))=alto(2);
%                     area(tiempo_mov,data_transition,basevalue,'FaceColor',colores(color,:),'FaceAlpha',0.2,'EdgeColor','none','DisplayName','Período quieto'); %grafico un rectangulo marcando el segmento quieto
%                 end
%             catch
%                 fprintf('El segmento de transicion esta fuera del intervalo analizado del evento! Registro Magnitud de Aceleración procesada\n')
%             end
%         else
%             fprintf('No hay segmentos de transicion en el intervalo analizado del evento! Registro Magnitud de Aceleración procesada\n')
%         end
%     else
%         plot(tiempo_mov,data_mov(),'color', colores(color,:),'LineWidth',1.5,'HandleVisibility','off');
%     end
% end
%legend('X','Entrada puerto','LED','Quiet','Intermediate','Change','Transition Area');
clear i color alto ones_seg transition_seg z data_mov tiempo_mov


%% genero el video del EVENTO
flag_video = 1;
if ~flag_video
    fprintf('No se cargó el video ni los datos de posicion para generar el video del eventos solicitado.\n');
    fprintf('Abortando...\n\n')
    return
end


delay_video = 0; %delay entre frames del video. Si es 0 no tiene delay

%------armo la figura
video_fig = figure(100); clf
video_fig.Position = [350, 50, 1150, 900];
video_fig.Resize = 'off';  
video_fig.Color = 'k';

%armo el box para la imagen del video
ax1 =axes('Parent',video_fig,...
     'Units','pixels','Position',[180 350 640 480],...
     'XTickLabel',[],'YTickLabel',[],'YDir','reverse',...
     'Xlim',[0 640],'Ylim',[0 480]);
box(ax1,'off')
hold(ax1,'on')

%armo el box para el grafico de la señal
ax2 = axes('Parent',video_fig,...
    'Units','pixels','Position',[50 40 1050 250],...
    'XLim',[-t1, t2], 'XTick', -5:0.5:5,...
    'Ylim',[min(acel_mag_temp(n_acel)) - 20, max(acel_mag_temp(n_acel)) + 20, ],...
    'Color','k', 'XColor','w', 'YColor','w','TickLength',[0.01 0.025]);
box(ax2,'on')
hold(ax2,'on')

%-----grafico la señal---------
hold on
plot(ax2,tiempo_acel,acel_mag_temp(n_acel),'c','LineWidth',1.2)
plot(ax2,[0,0],ylim','--y','LineWidth',1.3); %entrada al puerto
plot(ax2,[0.2,0.2],ylim','color','g','LineStyle',':','LineWidth',1.3); %encendido led
if -TS >= -nBefore_acel/acel.fm
    plot(ax2,[0-TS, 0-TS],ylim','-.k','LineWidth',1.2,'DisplayName','Salida Puerto'); %salida del puerto
end
lgd = legend(ax2,'Acel Magnitude','Entrada puerto','LED');
set(lgd,'Location','northeastoutside','TextColor','w','EdgeColor','k');
title('Acel Magnitude original')

for i = 1:3
    if i == 1
        data_points = quiet_acel_c;
        color = 1; %azul
    elseif i== 2
        data_points = intermediate_acel_c;
        color = 5;
    elseif i == 3
        data_points = change_acel_c;
        color = 4;
    end
    
    [data_mov, tiempo_mov,idx_start_end] = segmentador(data_points, n_acel, acel_mag_temp(n_acel), tiempo_acel);
    
    if i == 1 %grafico período quieto
        plot(ax2,tiempo_mov,data_mov(),'color', colores(color,:),'LineWidth',1.5,'HandleVisibility','off'); %grafica en color azul los segmentos de estado quieto
        alto = round(ax2.YLim(2));
        basevalue = round(ax2.YLim(1)); %elijo el limite inferior del grafico 
        if sum(~isnan(data_mov)) > 0 %compruebo que hay algun segmento de estado quieto
            seg_logical = ~isnan(data_mov);
            ones_seg = diff(~isnan(data_mov)); %busco los inicios de los segmentos quietos
            if seg_logical(1) == 1 %si el ind=1 vale 1, ya venia quieto de antes(por fuera de la ventana graficada)
                ones_seg(1) = 1;
            elseif seg_logical(end) == 1 %si el final vale 1, siegue quieto por fuera de la ventana graficada
                ones_seg(end) = 1;
            end
            try
                transition_seg(:,1) = find(ones_seg == 1) + 1; %busco los inicios de seg de transicion
                transition_seg(:,2) = find(ones_seg == -1); %busco los finales de seg de transicion
                for z = 1:size(transition_seg,1) %itero entre los seg quietos que encontró
                    data_transition = nan(length(data_mov),1);
                    data_transition(transition_seg(z,1):transition_seg(z,2))=alto;
                    area(ax2,tiempo_mov,data_transition,basevalue,'FaceColor',colores(color,:),'FaceAlpha',0.2,'EdgeColor','none','DisplayName','Período quieto'); %grafico un rectangulo marcando el segmento quieto
                end
            catch
                fprintf('El segmento de transicion esta fuera del intervalo analizado del evento! Registro Magnitud de Aceleración\n')
            end
        else
            fprintf('No hay segmentos de transicion en el intervalo analizado del evento! Registro Magnitud de Aceleración\n')
        end
    else
        plot(tiempo_mov,data_mov(),'color', colores(color,:),'LineWidth',1.5,'HandleVisibility','off');
    end
end
%legend('X','Entrada puerto','LED','Quiet','Intermediate','Change','Transition Area');
clear i color alto ones_seg transition_seg z data_mov tiempo_mov


%------parametros para extraer los frames del video
FI = pos.frames(1)+1; %frame de del video correspondiente al inicio del registro del NX 

%obtengo el numero de frames de video total del segmento de señal analizado
frame_E = nE_pos + FI; %frame entrada puerto
n_frames = (nE_pos - nBefore_pos:nE_pos + nAfter_pos)';

frames_seg = n_frames + FI; %rango de frames a extraer

%genero carpeta temporal
outfolder = 'video_temp'; %carpeta de guardado temporal del seg de video a analizar

if ~exist(outfolder, 'dir')
    mkdir(outfolder);
end

%Genero el objeto para crear el video
video_evento = VideoWriter([outfolder '\' 'video_evento.avi'],'Motion JPEG AVI');
video_evento.FrameRate = pos.fm;  %framerate del video generado
video_evento.Quality = 100; %maxima calidad del video
open(video_evento); 

%---parametros para el rectangulo movil que cubre la señal
vector_step = round(linspace(1,length(n_acel),length(n_pos))); %vector del largo de frames del video que incluye (la relacion entre el largo de la señal de acel y video) muestras de acel por cada paso (frame) de video
t_rectangle = linspace(-t1,t2,length(n_acel));

x = t_rectangle(1)+0.01;
y = ax2.YLim(1);
alto = ax2.YLim(2);
largo = abs(t_rectangle(1)) + t_rectangle(end)-0.025;

rect = rectangle(ax2,'Position',[x y  largo alto],...
    'LineWidth', 0.1, 'FaceColor','k','EdgeColor','k');

%---genero animacion de video
for i = 1:length(vector_step)
    frame = read(video,frames_seg(i)); %extraigo frame del video original
    imagesc(ax1,frame); %muestro el frame extraido
    
    if frames_seg(i) == frame_E %grafico cuadro fucsia en el video a la entrada al puerto
        set(rect2,'Position',[0 0 640 480],'LineWidth', 2.5,'EdgeColor','m');
        pause(0.2);
    else
        rect2 = rectangle(ax1,'Position',[0 0 640 480],...
            'LineWidth', 2.5,'EdgeColor','k');
    end
    title(['\color{white}Evento Nº ',num2str(E)])
        
    x = t_rectangle(vector_step(i));
    rect.Position(1:2) = [x y];
    
    drawnow;
    if ~isempty(delay_video)
        pause(delay_video)
    end
    
    num_frame = getframe(video_fig);
    writeVideo(video_evento, num_frame);
end
close(video_evento)



