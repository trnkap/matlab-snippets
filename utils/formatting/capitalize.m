function str = capitalize(str)
% CAPITALIZE capitalizes the first character of a characeter vector.
if ischar(str) && length(str)>=1
    str = [ upper(str(1)) str(2:end) ];
end
end