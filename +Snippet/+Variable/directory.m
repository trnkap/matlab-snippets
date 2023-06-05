function out = directory()
% The directory of the current document
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    if verLessThan('matlab', '9.11.0')
        out = fileparts( char( activeEditor.JavaEditor.getLongName ) );
    else
        out = fileparts( activeEditor.Filename );
    end
end
end
