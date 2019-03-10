function out = fileNameBase()
% The filename of the current document without its extensions
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    [~,out] = fileparts( char( activeEditor.JavaEditor.getLongName ) );
end
end