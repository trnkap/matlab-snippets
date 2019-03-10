function out = selectedText()
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    out = activeEditor.SelectedText;
end
end