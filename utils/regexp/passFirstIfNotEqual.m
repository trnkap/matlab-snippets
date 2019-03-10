function out = passFirstIfNotEqual(var1,var2,in1,in2)
if isequal(var1,var2)
    out = in2;
else
    out = in1;
end

