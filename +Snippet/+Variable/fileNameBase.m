function out = fileNameBase()
% The filename of the current document without its extensions
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    if verLessThan('matlab', '9.11.0')
        [~,out] = fileparts( char( activeEditor.JavaEditor.getLongName ) );
    else
        [~, out] = fileparts( activeEditor.Filename );
    end
end
end