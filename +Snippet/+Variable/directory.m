function out = directory()
% The directory of the current document
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    out = fileparts( char( activeEditor.JavaEditor.getLongName ) );
end
end
