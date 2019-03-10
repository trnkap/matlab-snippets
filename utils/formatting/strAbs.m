function str = strAbs(str)
% STRABS computes the absolute value of a number in a character vector.
% Returns the input argument if coversion fails.
%
% Syntax:
%    str = strAbsoluteValue(str)
%
% Inputs:
%    str - input number (character vector)
%
% Outputs:
%    str - output number (character vector)
%
x = str2double(str);
if ~isnan(x)
    x = abs(x);
    str = num2str(x);
end
end