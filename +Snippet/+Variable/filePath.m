function out = filePath()
%The full file path of the current document
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    if verLessThan('matlab', '9.11.0')
        out = char( activeEditor.JavaEditor.getLongName );
    else
        out = activeEditor.Filename;
    end
end
end
