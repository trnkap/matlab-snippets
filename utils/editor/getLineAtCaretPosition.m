function [lineAtCaret,i1,i2] = getLineAtCaretPosition()
% Get a word at the current editor caret positon.
%
lineAtCaret = '';
i1 = [];
i2 = [];

activeEditor = getActiveEditor();
if ~isempty(activeEditor)
    caretPosition = activeEditor.JavaEditor.getCaretPosition;
    text = activeEditor.Text;
    
    if isempty(text)
        % --- Empty document
    else
        % --- Text before caret
        [startIndex,endIndex] = regexp(text(1:caretPosition),'[^\n]*$');
        if isempty(startIndex)
            % --- Caret at the line begining
        else
            lineAtCaret = [ lineAtCaret text(startIndex(1):endIndex(1)) ];
            i1 = startIndex(1);
            i2 = endIndex(1);
        end
        % --- Text after caret
        [startIndex,endIndex] = regexp(text(caretPosition+1:end),'^[^\n]*');
        if isempty(lineAtCaret)
            if isempty(startIndex)
                % --- Caret on an empty line
            else
                % --- Caret at the begining of a non-empty line
                lineAtCaret = [ lineAtCaret text(caretPosition+(startIndex(1):endIndex(1))) ];
                i1 = caretPosition+startIndex(1);
                i2 = caretPosition+endIndex(1);
            end
        else
            if isempty(startIndex)
                % --- Caret at the line end
            else
                lineAtCaret = [ lineAtCaret text(caretPosition+(startIndex(1):endIndex(1))) ];
                i2 = caretPosition+endIndex(1);
            end
        end
        
    end
end
end