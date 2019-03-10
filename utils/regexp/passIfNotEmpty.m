function out = passIfNotEmpty(arg,in)
if isempty(arg)
    out = '';
else
    out = in;
end

