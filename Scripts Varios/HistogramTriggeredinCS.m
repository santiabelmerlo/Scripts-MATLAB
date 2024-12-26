    %% Pre4 CS+  ---> 4 seg pre CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) >= (CS1.start(i) - 4000) && IR2.end(j) < (CS1.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia despues de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) >= (CS1.start(i) - 4000) && IR2.start(j) < (CS1.start(i) - 2000) && IR2.end(j) > (CS1.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) - 2000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) < (CS1.start(i) - 4000) && IR2.end(j) > (CS1.start(i) - 4000) && IR2.end(j) <= (CS1.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) - 4000));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) < (CS1.start(i) - 4000) && IR2.end(j) > (CS1.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.pre4.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
    % Pre2 CS+  ---> 2 seg pre CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) >= (CS1.start(i) - 2000) && IR2.end(j) < CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia despues de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) >= (CS1.start(i) - 2000) && IR2.start(j) < CS1.start(i) && IR2.end(j) > CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + (CS1.start(i) - IR2.start(j));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) < (CS1.start(i) - 2000) && IR2.end(j) > (CS1.start(i) - 2000) && IR2.end(j) <= CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) - 2000));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) < (CS1.start(i) - 2000) && IR2.end(j) > CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.pre2.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
    % Durante 0-2 seg del CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= CS1.start(i) && IR2.end(j) < (CS1.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= CS1.start(i) && IR2.start(j) < (CS1.start(i) + 2000) && IR2.end(j) > (CS1.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 2000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < CS1.start(i) && IR2.end(j) > CS1.start(i) && IR2.end(j) <= (CS1.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - CS1.start(i));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < CS1.start(i) && IR2.end(j) > (CS1.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.0to2duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % Durante 2-4 seg del CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 2000) && IR2.end(j) < (CS1.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 2000) && IR2.start(j) < (CS1.start(i) + 4000) && IR2.end(j) > (CS1.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 4000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 2000) && IR2.end(j) > (CS1.start(i) + 2000) && IR2.end(j) <= (CS1.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 2000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 2000) && IR2.end(j) > (CS1.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.2to4duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % Durante 4-6 seg del CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 4000) && IR2.end(j) < (CS1.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 4000) && IR2.start(j) < (CS1.start(i) + 6000) && IR2.end(j) > (CS1.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 6000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 4000) && IR2.end(j) > (CS1.start(i) + 4000) && IR2.end(j) <= (CS1.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 4000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 4000) && IR2.end(j) > (CS1.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.4to6duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % Durante 6-8 seg del CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 6000) && IR2.end(j) < (CS1.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 6000) && IR2.start(j) < (CS1.start(i) + 8000) && IR2.end(j) > (CS1.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 8000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 6000) && IR2.end(j) > (CS1.start(i) + 6000) && IR2.end(j) <= (CS1.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 6000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 6000) && IR2.end(j) > (CS1.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.6to8duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % Durante 8-10 seg del CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 8000) && IR2.end(j) < (CS1.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 8000) && IR2.start(j) < (CS1.start(i) + 10000) && IR2.end(j) > (CS1.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 10000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 8000) && IR2.end(j) > (CS1.start(i) + 8000) && IR2.end(j) <= (CS1.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 8000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 8000) && IR2.end(j) > (CS1.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.8to10duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % 2 seg post CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 10000) && IR2.end(j) < (CS1.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 10000) && IR2.start(j) < (CS1.start(i) + 12000) && IR2.end(j) > (CS1.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 12000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 10000) && IR2.end(j) > (CS1.start(i) + 10000) && IR2.end(j) <= (CS1.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 10000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 10000) && IR2.end(j) > (CS1.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.2postCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % 4 seg post CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 12000) && IR2.end(j) < (CS1.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 12000) && IR2.start(j) < (CS1.start(i) + 14000) && IR2.end(j) > (CS1.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 14000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 12000) && IR2.end(j) > (CS1.start(i) + 12000) && IR2.end(j) <= (CS1.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 12000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 12000) && IR2.end(j) > (CS1.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.4postCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        %% Pre4 CS-  ---> 4 seg pre CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) >= (CS2.start(i) - 4000) && IR2.end(j) < (CS2.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia despues de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) >= (CS2.start(i) - 4000) && IR2.start(j) < (CS2.start(i) - 2000) && IR2.end(j) > (CS2.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) - 2000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) < (CS2.start(i) - 4000) && IR2.end(j) > (CS2.start(i) - 4000) && IR2.end(j) <= (CS2.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) - 4000));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) < (CS2.start(i) - 4000) && IR2.end(j) > (CS2.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.pre4.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
    % Pre2 CS-  ---> 2 seg pre CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) >= (CS2.start(i) - 2000) && IR2.end(j) < CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia despues de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) >= (CS2.start(i) - 2000) && IR2.start(j) < CS2.start(i) && IR2.end(j) > CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + (CS2.start(i) - IR2.start(j));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) < (CS2.start(i) - 2000) && IR2.end(j) > (CS2.start(i) - 2000) && IR2.end(j) <= CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) - 2000));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) < (CS2.start(i) - 2000) && IR2.end(j) > CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.pre2.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
    % Durante 0-2 seg del CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= CS2.start(i) && IR2.end(j) < (CS2.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= CS2.start(i) && IR2.start(j) < (CS2.start(i) + 2000) && IR2.end(j) > (CS2.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 2000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < CS2.start(i) && IR2.end(j) > CS2.start(i) && IR2.end(j) <= (CS2.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - CS2.start(i));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < CS2.start(i) && IR2.end(j) > (CS2.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.0to2duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % Durante 2-4 seg del CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 2000) && IR2.end(j) < (CS2.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 2000) && IR2.start(j) < (CS2.start(i) + 4000) && IR2.end(j) > (CS2.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 4000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 2000) && IR2.end(j) > (CS2.start(i) + 2000) && IR2.end(j) <= (CS2.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 2000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 2000) && IR2.end(j) > (CS2.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.2to4duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % Durante 4-6 seg del CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 4000) && IR2.end(j) < (CS2.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 4000) && IR2.start(j) < (CS2.start(i) + 6000) && IR2.end(j) > (CS2.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 6000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 4000) && IR2.end(j) > (CS2.start(i) + 4000) && IR2.end(j) <= (CS2.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 4000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 4000) && IR2.end(j) > (CS2.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.4to6duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % Durante 6-8 seg del CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 6000) && IR2.end(j) < (CS2.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 6000) && IR2.start(j) < (CS2.start(i) + 8000) && IR2.end(j) > (CS2.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 8000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 6000) && IR2.end(j) > (CS2.start(i) + 6000) && IR2.end(j) <= (CS2.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 6000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 6000) && IR2.end(j) > (CS2.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.6to8duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % Durante 8-10 seg del CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 8000) && IR2.end(j) < (CS2.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 8000) && IR2.start(j) < (CS2.start(i) + 10000) && IR2.end(j) > (CS2.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 10000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 8000) && IR2.end(j) > (CS2.start(i) + 8000) && IR2.end(j) <= (CS2.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 8000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 8000) && IR2.end(j) > (CS2.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.8to10duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % 2 seg post CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 10000) && IR2.end(j) < (CS2.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 10000) && IR2.start(j) < (CS2.start(i) + 12000) && IR2.end(j) > (CS2.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 12000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 10000) && IR2.end(j) > (CS2.start(i) + 10000) && IR2.end(j) <= (CS2.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 10000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 10000) && IR2.end(j) > (CS2.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.2postCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % 4 seg post CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 12000) && IR2.end(j) < (CS2.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 12000) && IR2.start(j) < (CS2.start(i) + 14000) && IR2.end(j) > (CS2.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 14000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 12000) && IR2.end(j) > (CS2.start(i) + 12000) && IR2.end(j) <= (CS2.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 12000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 12000) && IR2.end(j) > (CS2.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.4postCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end