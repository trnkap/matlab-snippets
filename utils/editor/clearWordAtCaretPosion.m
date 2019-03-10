function clearWordAtCaretPosion()
[wordAtCaret,i1,i2] = getWordAtCaretPosition();
if ~isempty(wordAtCaret)   
    activeEditor = getActiveEditor();
    % --- Select the word
    activeEditor.JavaEditor.setSelection(i1-1,i2);
    % --- Insert empty text to delete the selected word
    activeEditor.JavaEditor.insertTextAtCaret('');
end
end