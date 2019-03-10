function lineEndStr = fillEditorLineEndByCharacter(str,fillChar)

% --- Matlab editor line limit
if verLessThan('matlab','9.4') % R2018a
    lineColumn = 80;
else
    matlabSettings = settings();
    lineColumn = matlabSettings.matlab.editor.displaysettings.linelimit.LineColumn.ActiveValue;    
end

% --- Get current line indentation lengths
lineAtCaret = getLineAtCaretPosition();
tokens = regexp(lineAtCaret,'^([ ]*)','tokens','once');
if isempty(tokens)
    indentationStr = '';
else
    indentationStr = tokens{1};
end
indentationLength = length(indentationStr);

% --- Word at caret
wordAtCaret = getWordAtCaretPosition();

nFill = lineColumn - indentationLength - length(str) + length(wordAtCaret);
lineEndStr = repmat(fillChar,1,nFill);

end