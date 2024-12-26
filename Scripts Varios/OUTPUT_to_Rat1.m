%% Tomamos los datos de OUTPUT y generamos el archivo Rat1.m que luego lee el script ScaterDotPlot.m
% Este script requiere correr primero EventAnalysis.m para generar el archivo OUTPUT

clear all
clc
path = pwd;
cd(path);

load(['R17_OUTPUT.mat']);
fields = char(fieldnames(OUTPUT));

for i = 1:length(fields);
    % Rat1
        % target
            % duringCS
                % ttarget
                    Rat1.duringCS.ttarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.ttarget.CS1;
                    Rat1.duringCS.ttarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.ttarget.CS2;
                % ntarget
                    Rat1.duringCS.ntarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.ntarget.CS1;
                    Rat1.duringCS.ntarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.ntarget.CS2;
                % ltarget
                    Rat1.duringCS.ltarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.ltarget.CS1;
                    Rat1.duringCS.ltarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.ltarget.CS2;
            % postCS
                % ttarget
                    Rat1.postCS.ttarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.ttarget.CS1;
                    Rat1.postCS.ttarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.ttarget.CS2;
                % ntarget
                    Rat1.postCS.ntarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.ntarget.CS1;
                    Rat1.postCS.ntarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.ntarget.CS2;
                % ltarget
                    Rat1.postCS.ltarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.ltarget.CS1;
                    Rat1.postCS.ltarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.ltarget.CS2;
            % preCS
                % ttarget
                    Rat1.preCS.ttarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.ttarget.CS1;
                    Rat1.preCS.ttarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.ttarget.CS2;
                % ntarget
                    Rat1.preCS.ntarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.ntarget.CS1;
                    Rat1.preCS.ntarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.ntarget.CS2;
                % ltarget
                    Rat1.preCS.ltarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.ltarget.CS1;
                    Rat1.preCS.ltarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.ltarget.CS2;

        % puerta
            % duringCS
                % tpuerta
                    Rat1.duringCS.tpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.tpuerta.CS1;
                    Rat1.duringCS.tpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.tpuerta.CS2;
                % npuerta
                    Rat1.duringCS.npuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.npuerta.CS1;
                    Rat1.duringCS.npuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.npuerta.CS2;
                % lpuerta
                    Rat1.duringCS.lpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.lpuerta.CS1;
                    Rat1.duringCS.lpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.lpuerta.CS2;
            % postCS
                % tpuerta
                    Rat1.postCS.tpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.tpuerta.CS1;
                    Rat1.postCS.tpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.tpuerta.CS2;
                % npuerta
                    Rat1.postCS.npuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.npuerta.CS1;
                    Rat1.postCS.npuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.npuerta.CS2;
                % lpuerta
                    Rat1.postCS.lpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.lpuerta.CS1;
                    Rat1.postCS.lpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.lpuerta.CS2;
            % preCS
                % tpuerta
                    Rat1.preCS.tpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.tpuerta.CS1;
                    Rat1.preCS.tpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.tpuerta.CS2;
                % npuerta
                    Rat1.preCS.npuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.npuerta.CS1;
                    Rat1.preCS.npuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.npuerta.CS2;
                % lpuerta
                    Rat1.preCS.lpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.lpuerta.CS1;
                    Rat1.preCS.lpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.lpuerta.CS2;
end

% Calculamos el porcentaje de entradas 
Rat1.duringCS.ppuerta = mean(Rat1.duringCS.tpuerta > 0) * 100;
Rat1.duringCS.ptarget = mean(Rat1.duringCS.ttarget > 0) * 100;
Rat1.postCS.ppuerta = mean(Rat1.postCS.tpuerta > 0) * 100;
Rat1.postCS.ptarget = mean(Rat1.postCS.ttarget > 0) * 100;
Rat1.preCS.ppuerta = mean(Rat1.preCS.tpuerta > 0) * 100;
Rat1.preCS.ptarget = mean(Rat1.preCS.ttarget > 0) * 100;

% Convertimos todo a doubles
Rat1.duringCS.ttarget = double(Rat1.duringCS.ttarget);
Rat1.duringCS.ltarget = double(Rat1.duringCS.ltarget);
Rat1.duringCS.ntarget = double(Rat1.duringCS.ntarget);
Rat1.duringCS.ptarget = double(Rat1.duringCS.ptarget);
Rat1.duringCS.tpuerta = double(Rat1.duringCS.tpuerta);
Rat1.duringCS.lpuerta = double(Rat1.duringCS.lpuerta);
Rat1.duringCS.npuerta = double(Rat1.duringCS.npuerta);
Rat1.duringCS.ppuerta = double(Rat1.duringCS.ppuerta);

Rat1.preCS.ttarget = double(Rat1.preCS.ttarget);
Rat1.preCS.ltarget = double(Rat1.preCS.ltarget);
Rat1.preCS.ntarget = double(Rat1.preCS.ntarget);
Rat1.preCS.ptarget = double(Rat1.preCS.ptarget);
Rat1.preCS.tpuerta = double(Rat1.preCS.tpuerta);
Rat1.preCS.lpuerta = double(Rat1.preCS.lpuerta);
Rat1.preCS.npuerta = double(Rat1.preCS.npuerta);
Rat1.preCS.ppuerta = double(Rat1.preCS.ppuerta);

Rat1.postCS.ttarget = double(Rat1.postCS.ttarget);
Rat1.postCS.ltarget = double(Rat1.postCS.ltarget);
Rat1.postCS.ntarget = double(Rat1.postCS.ntarget);
Rat1.postCS.ptarget = double(Rat1.postCS.ptarget);
Rat1.postCS.tpuerta = double(Rat1.postCS.tpuerta);
Rat1.postCS.lpuerta = double(Rat1.postCS.lpuerta);
Rat1.postCS.npuerta = double(Rat1.postCS.npuerta);
Rat1.postCS.ppuerta = double(Rat1.postCS.ppuerta);

save(['R17_Rat1.mat']);
