function X = random_x(x,n)
    % Uso: X = random_x(x,n)
    % Función para generar una cierta cantidad de valores n alrededor del
    % valor x +- 0.25. Lo utilizo generalmente para plotear todos los
    % valores en un barplot y que no me queden superpuestos en X.
    % x es el valor de x alrededor del que quiero generar las posiciones aleatorias
    % n es el número de valores que quiero generar
    X = (x-0.25)+(0.5)*rand(1,n);
end