function text = alignCharacter(text,alignmentCharacter)
% ALIGNCHARACTER aligns selected character in cell array of character vectors by
% adding spaces before the character.
% 
% Syntax:
%   text = alignCharacter(text,alignmentCharacter)
%
% Inputs:
%   text - cell array of character vectors
%   alignmentCharacter - single that will be alighned (e.g. '%','=')
% 
% Outputs
%   textu - resulting cell array of character vectors
%
rows = strsplit(text,'\n');
IComment = cell(size(rows));
for i = 1 : length(rows)
    IComment{i} = find(rows{i}==alignmentCharacter,1);
end
IComment_ = cell2mat(IComment);
if ~isempty(IComment_)
    icomment = max(IComment_);
    for i = 1 : length(rows)
        if ~isempty(IComment{i})
            rows{i} = [ ...
                rows{i}(1:IComment{i}-1) ...
                repmat(' ',1,icomment-IComment{i}) ...
                rows{i}(IComment{i}:end) ];
        end
    end
end
text = strjoin(rows,'\n');
end