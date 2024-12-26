function asterisk = p_asterisk(p)
    % p_asterisk - Returns a string of asterisks corresponding to the p-value significance.
    %
    % Syntax:
    %   asterisk = p_asterisk(p)
    %
    % Input:
    %   p - The p-value (numeric)
    %
    % Output:
    %   asterisk - A string containing the appropriate number of asterisks.

    if p < 0.05 && p >= 0.01
        asterisk = '*';
    elseif p < 0.01 && p >= 0.001
        asterisk = '**';
    elseif p < 0.001
        asterisk = '***';
    elseif p < 0.0001
        asterisk = '****';
    else
        asterisk = ''; % No significance
    end
end