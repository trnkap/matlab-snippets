function closingBracketIndex = findMatchingClosingBracket(str,closingBracket)
% FINDMATCHINGCLOSINGBRACKET Finds matching closing bracket '}' in the character 
% vector.
%
% Syntax:
%   closingBracketIndex = findMatchingClosingBracket(str,bracket)
%
% Inputs:
%   str .............. searched character array
%   closingBracket ... closing bracket character (')','}','>',']')
%                      (optional, default = '}')
%
% Outputs:
%   clsingBracketIndex ... closing bracket index in "str" input argument,
%                          returns [] if no closing bracket was found
%
% Examples:
%
%   >> findMatchingClosingBracket('text}')
%   ans =
%          5
% 
%   >> findMatchingClosingBracket('{text}}')
%   ans =
%          7
% 
%   >> findMatchingClosingBracket('{text}')
%   ans =
%       Empty matrix: 1-by-0
%
if nargin<2
    closingBracket = '}';
end

% --- Determine opening bracket character
openingBrackets = '({<[';
closingBrackets = ')}>]';
ind = find(closingBrackets==closingBracket,1);
if isempty(ind)
    closingBracketsList = strjoin(arrayfun(@(c)['"' c '"'],closingBrackets,'UniformOutput',false),', ');
    error(['Cannot find the closing bracket character "' closingBracket ...
        '" in the list of supported closing bracket types: ' closingBracketsList '.']);
end
openingBracket = openingBrackets(ind);

openingBracketIndicators = (str==openingBracket);
closingBracketIndicators = (str==closingBracket);
closingBracketIndex = find( ...
    cumsum(closingBracketIndicators) > cumsum(openingBracketIndicators), ...
    1);
end