function out = filePath()
%The full file path of the current document
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    out = char( activeEditor.JavaEditor.getLongName );
end
end
