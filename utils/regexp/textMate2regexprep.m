function [expression,replace,options_] = textMate2regexprep(regex,format,options)
% TEXTMATE2REGEXPREP modifies arguements of the variable and placeholder
% transformation, used in the TextMate snippet syntax, to make them compatible
% with the Matlab regexprep input arguments.
%
% TextMate Snippet syntax for variable transformation
%   ${«variable»/«regex»/«format»/«options»}
% and similarly for tabstop placeholder transformation
%   ${«tab stop»/regex/«format»/«options»}
% Grammar that can be used in the argumets is described in this table:
% https://code.visualstudio.com/docs/editor/userdefinedsnippets#_grammar
%
% Syntax:
%   [expression,replace,options] = textMate2regexprep(regex,format,options)
%
% Inputs:
%   <TextMate variable/placeholder transformation arguments>
%
% Outputs:
%   <Matlab regexprep input arguments>
%
% Note: there are some limits on the conditional replacement - see below.
%

expression = regex;
replace    = format;

% --- Character case modification commands -------------------------------------
replacementTable = {
    '\${\s*(\d+)\s*:\s*/upcase\s*}'     '\${upper(\$$1)}'
    '\${\s*(\d+)\s*:\s*/downcase\s*}'   '\${lower(\$$1)}'
    '\${\s*(\d+)\s*:\s*/capitalize\s*}' '\${capitalize(\$$1)}'
    };
for irow = 1 : size(replacementTable,1)
    replace = regexprep( ...
        replace, ...
        replacementTable{irow,1}, ...
        replacementTable{irow,2} );
end


% --- Conditional replacement --------------------------------------------------
%
% Possible forms:
%   '${' int ':+' if '}'
%   '${' int ':-' else '}'
%   '${' int ':?' if ':' else '}'
%
% Limits:
% * if tabstop values matches ['$' tabstopNumber] then the condition is 
%   evaluated as false
% * "if" cannot contain tabstops (!)
%
iterMax = 1e3;
for iter = 1 : iterMax
    [startIndex,endIndex,tokens] = regexp( ...
        replace, ...
        '\${\s*(\d+)\s*:([+?-])', ...
        'start','end','tokens','once');
    if ~isempty(startIndex)
        tabstopNumber = tokens{1};
        conditionType = tokens{2};
        % ---
        closingBracketIndex = endIndex + findMatchingClosingBracket(replace(endIndex+1:end));
        if isempty(closingBracketIndex)
            error('Cannot find matching closing bracket');
        end
        % ---        
        argument = replace(endIndex+1:closingBracketIndex-1);
        if conditionType=='?'
            semicolonIndex = find( argument==':' );
            if isempty(semicolonIndex)
                error('Conditional replacement is missing "else" part.');
            elseif length(semicolonIndex)>1
                error('There are multiple semicolons in the conditional replacement.');
            end
            argument = { ...
                argument(1:semicolonIndex-1) ...
                argument(semicolonIndex+1:end) ...
                };
        end        
        % ---
        newLineStr = ''' char(10) ''';
        argument = strrep( argument, [char(10) char(13)], newLineStr );
        argument = strrep( argument, [char(13) char(10)], newLineStr );
        argument = strrep( argument, char(10), newLineStr );
        argument = strrep( argument, char(13), newLineStr );
        % ---
        switch conditionType
            case '+'
                cmd = [ 'passIfNotEqual($' tabstopNumber ',''\$' tabstopNumber ''',[''' argument '''])' ];
            case '-'
                cmd = [ 'passIfEqual($' tabstopNumber ',''\$' tabstopNumber ''',[''' argument '''])' ];
            case '?'
                cmd = [ 'passFirstIfNotEqual($' tabstopNumber ',''\$' tabstopNumber ''',[''' argument{1} '''],[''' argument{2} '''])' ];
            otherwise
                error(['Unknown condional replacement type "' contionType '".']);                
        end        
        replace = [ ...
            replace(1:startIndex-1) ...
            '${' cmd '}'
            replace(closingBracketIndex+1:end) ...
            ];
    else
        break
    end
end
if iter == iterMax
    error('Maximum number of iterations reached.');
end


% --- Flags -> regexprep options cell array ------------------------------------
replacementTable = {
    'g'   'all'          'once'
    'i'   'ignorecase'   'matchcase'
    's'   'dotall'       'dotexceptnewline'
    'e'   'emptymatch'   'noemptymatch'      % (non-standard)
    };
    % 'm','u','y' flags are ignored...
    
options_ = cell(1,size(replacementTable,1));
for irow = 1 : size(replacementTable,1)
    if any(options==replacementTable{irow,1})
        options_{irow} = replacementTable{irow,2};
    else
        options_{irow} = replacementTable{irow,3};
    end
end