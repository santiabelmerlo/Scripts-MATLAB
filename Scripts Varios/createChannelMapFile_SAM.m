function createChannelMapFile_mac(filedirectory,varargin)

%
% Crea Channel Map a partir de los datos del XML
% Parametros: xml directory
%             configuration: vertical / horizontal / agrupado(default)
%             /agrupado2
%             debug: 1/0(default)
%              
% USO: createChannelMapFile_SAM([],'configuration','agrupado','debug',1)
%
% MAC 03/08/2021, update 02/08/2022

%% create a channel map file
% Chequeo el directorio de trabajo

if ~exist('filename','var') || isempty(filename)
    disp(' --- Working directory not specified. Searching for XML file in current directory ---');fprintf('\n');
    %path
    basepath = cd;
    [~,basename] = fileparts(basepath);
    %return
else
    basepath = filedirectory;
    [~,basename] = fileparts(basepath);
    %return
end


%% Checking if xml files exist
if ~exist(fullfile(basepath,[basename,'.xml']))
    warning('KilosortWrapper  %s.xml file not in path %s',basename,basepath);fprintf('\n');
    return
end



%% Chequear argumentos pasados al llamar la funcion

p = inputParser;
addParameter(p,'configuration','agrupado',@ischar)  % Specify configuraton for Channel Map file [agrupado/vertical/horizontal]
addParameter(p,'debug',0,@isnumeric)  % Specify plot channel map configuration [0/1]
parse(p,varargin{:})
configuration = p.Results.configuration; %contiene opcion pasada en los argumentos (default 'agrupado')
debug = p.Results.debug;


%% Loading configurations
XMLFilePath = fullfile(basepath, [basename '.xml']);

% Loads xml parameters (Neuroscope)
xml = LoadXml(XMLFilePath);

Nchannels = xml.nChannels;
fs = xml.SampleRate; % sampling frequency

%%
disp('Creating Channel Map');fprintf('\n');
% xcoords e ycoords son las coordenadas X, Y de los electrodos/canales.
xcoords = [];%eventual output arrays
ycoords = [];

ngroups = length(xml.SpkGrps); 
for g = 1:ngroups
    %original comentado para XML ceci groups{g} = xml.SpkGrps(g).Channels;
    groups{g} = xml.AnatGrps(g).Channels;
    
end

switch(configuration)
    case 'agrupado'
        for g = 1:ngroups
            if numel(groups{g})==1
                xcoords(g,1) = 0;
            elseif numel(groups{g})==4
                 x_temp = repmat([-5 -5 5 5], 1, 1)';
                 xcoords = cat(1,xcoords,x_temp(:));
            elseif numel(groups{g})==3
                x_temp = repmat([-5 -5 5], 1, 1)';
                xcoords = cat(1,xcoords,x_temp(:));
            end
        end
        
        %ymax = 200*ngroups;
        dist_tetrodos = 1000; %parametro de dist entre tetrodos
        for i =1:ngroups           
            if numel(groups{i})==1
                y = [];
                y(1) = 0;
                y = y -(i-1)*dist_tetrodos;
                ycoords = cat(1,ycoords,y(:));
            elseif numel(groups{i})==4
                y = [];
                y(1) = 0;
                y(2) = -10;
                y(3) = 0;
                y(4) = -10;

                y = y -(i-1)*dist_tetrodos;
                ycoords = cat(1,ycoords,y(:));
                
            elseif numel(groups{i})==3
                y = [];
                y(1) = 0;
                y(2) = -10;
                y(3) = 0;

                y = y -(i-1)*dist_tetrodos;
                ycoords = cat(1,ycoords,y(:));  
            end           
        end
        
    case 'agrupado2'
        dist_tetrodos = 500; %parametro de dist entre tetrodos
            
        xcoords = [];
        ycoords = [];
        
        for a= 1:ngroups %being super lazy and making this map with loops
            
            tchannels  = groups{a};
            x = nan(length(tchannels),1);
            y = nan(length(tchannels),1);
            c = 5;
            d= 2*c;
            e = -5;
            f= 4*e;
            for i =1:length(tchannels)
                %---x coord----
                if mod(i,2)
                    %ch impar
                    x(i) = c;
                    c = c + 15;
                else
                    %ch par
                    x(i) = d;%length(tchannels)-i;
                    d = d + 15;
                end
                %----y coord----
                if mod(i,2)
                    %ch impar
                    y(i) = e;
                    e = e - 5;
                else
                    %ch par
                    y(i) = f;
                    f = f - 5;
                end
            end
            
            y = y -(a-1)*dist_tetrodos;
            x = x +(a-1)*dist_tetrodos;
            
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
        
    case 'vertical'
        dist_tetrodo = 1000;
        for a= 1:ngroups %being super lazy and making this map with loops
            x = [];
            y = [];
            tchannels  = groups{a};
            dist_electrodo = 5;
            for i = 1:length(tchannels)
                y(i) = 0 - (i-1)*dist_electrodo;
            end
            
            y = y - (a-1)*dist_tetrodo; %distancia entre tetrodos
                     
            for i =1:length(tchannels)
                x(i) = 0;
            end
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
        
    case 'horizontal'
        for a= 1:ngroups %being super lazy and making this map with loops
            x = [];
            y = [];
            y(1) = -20;
            y(2) = -20;
            y(3) = -40;
            y(4) = -40;
            tchannels  = groups{a};
            for i =1:length(tchannels)
                x(i) = 20;%length(tchannels)-i;
               %y(i) = -i*20; %Modificado (MAC)
                if mod(i,2)
                    x(i) = -x(i);
                end
            end
            x = x+a*200;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
    otherwise
        disp('Incorrect configuration option for channel map. Must be agrupado/vertical/horizontal');
        return
end

%Agrupo los canales por tetrodo
kcoords = zeros(1,Nchannels);
for a= 1:ngroups
    kcoords(groups{a}+1) = a;
end


%Estan todos los canales conectados?
connected = true(Nchannels, 1);
connected(33:35,1) = 0; % Anulamos los canales del acelerómetro para no hacer sorting de esos canales en experimentos de 35ch.
% connected(65:70,1) = 0; % Anulamos los canales del acelerómetro para no hacer sorting de esos canales en experimentos de 70ch.


% just use AnatGrps
% Removing dead channels by the skip parameter in the xml
% modificado para que desconecte los channles indicdos en el xml (MAC)
order = [xml.SpkGrps.Channels]; %Modificado (MAC) %order = [par.AnatGrps.Channels];
skip = find([xml.AnatGrps.Skip]); 
%modificado para XML ceci
%connected(order(skip)+1) = false;
connected(order(skip)) = false;

%Mapa de canales
chanMap     = 1:Nchannels;
chanMap0ind = chanMap - 1;
[~,I] =  sort(horzcat(groups{:})); 
xcoords = xcoords(I)';
ycoords  = ycoords(I)';


%agrego esto para que ande en el KS[25]
configFxn = '';

%creo la figura con la distribucion de los electrodos del tetrodo
if debug
    disp('Plotting Channel Map Configuration..');
    fig_hist = figure(33); clf;
    
    s = scatter(xcoords,ycoords,'s');
    s.LineWidth = 1.0;
    s.MarkerEdgeColor = 'b';
    s.MarkerFaceColor = [0 0.5 0.5];
    

    
    grid on
    box on
    
    title('Tetrodes Configuration','FontSize',12)
    
    if (max(abs(ycoords)) - min(abs(ycoords))) > (max(abs(xcoords)) - min(abs(xcoords)))
        set(fig_hist, 'Position', [700, 50, 350, 900]) %vertical
        xlabel('Electrode Separation (um)')
        ylabel('Tetrode Distance (um)')
        if (max(abs(xcoords)) + min(abs(xcoords))) > 0
            x_min = min(xcoords) - 50;
            x_max = max(xcoords) + 50;
            xlim([x_min x_max])
        end
    else
        set(fig_hist, 'Position', [350, 450, 1200, 350]) %horizontal
        ylabel('Electrode Separation (um)')
        xlabel('Tetrode Distance (um)')
        y_min = min(ycoords) - 50;
        y_max = max(ycoords) + 50;
        ylim([y_min y_max])
    end
    
    
    
end



disp('Saving Channel map file...');
clear Nchannels
save(fullfile(basepath,'chanMap.mat'), ...
    'chanMap','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs','configFxn')
disp('Done'); fprintf('\n');



%%

% kcoords is used to forcefully restrict templates to channels in the same
% channel group. An option can be set in the master_file to allow a fraction 
% of all templates to span more channel groups, so that they can capture shared 
% noise across all channels. This option is

% ops.criterionNoiseChannels = 0.2; 

% if this number is less than 1, it will be treated as a fraction of the total number of clusters

% if this number is larger than 1, it will be treated as the "effective
% number" of channel groups at which to set the threshold. So if a template
% occupies more than this many channel groups, it will not be restricted to
% a single channel group. 