function text = singleSpace(text,compact)
% SINGLESPACE forces a single space after '(', ',' and before ')'. If compact
% flag is true that it forces no space after '(', a single space after ',' and
% no space before ')'.
%
% Syntax:
%   text = singleSpace(text,targetSymbols)
%
% Inputs:
%   text ... source text (character array)
%   compact ... compact format flag (logical)
%
% Examples:
%   >> singleSpace('fce(in1,arg2,arg3)')
%   ans =
%       'fce( in1, arg2, arg3 )'
%
%   >> singleSpace('fce(  in1  ,  arg2  ,  arg3  )')
%   ans =
%       'fce( in1, arg2, arg3 )'
%
%   >> singleSpace('fce(  in1  ,  arg2  ,  arg3  )',true)
%   ans =
%       'fce( in1, arg2, arg3 )'
%
if nargin<2
    compact = false;
end
% ---
expression = '\([ ]*';
if compact
    replace = '\(';
else
    replace = '\( ';
end
text = regexprep(text,expression,replace);
% ---
expression = '[ ]*,[ ]*';
replace = ', ';
text = regexprep(text,expression,replace);
% ---
expression = '[ ]*\)';
if compact
    replace = '\)';
else
    replace = ' \)';
end
text = regexprep(text,expression,replace);
end