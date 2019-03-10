function [wordAtCaret,i1,i2] = getWordAtCaretPosition()
% Get a word at the current editor caret positon.
%
wordAtCaret = '';
i1 = [];
i2 = [];

activeEditor = getActiveEditor();
if ~isempty(activeEditor)
    caretPosition = activeEditor.JavaEditor.getCaretPosition;
    text = activeEditor.Text;
    
    [startIndex,endIndex] = regexp(text(1:caretPosition),'\S*$');
    if ~isempty(startIndex)
        wordAtCaret = [ wordAtCaret text(startIndex(1):endIndex(1)) ];
        i1 = startIndex(1);
        i2 = endIndex(1);
    end
    [startIndex,endIndex] = regexp(text(caretPosition+1:end),'^\S*');
    if ~isempty(startIndex)
        wordAtCaret = [ wordAtCaret text(caretPosition+(startIndex(1):endIndex(1))) ];
        if isempty(i1)
            i1 = caretPosition+startIndex(1);
        end
        i2 = caretPosition+endIndex(1);
    end
end
end