function out = fileName()
% The filename of the current document
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    if verLessThan('matlab', '9.11.0')
        out = char( activeEditor.JavaEditor.getShortName );
    else
        [~, file, ext] = fileparts( activeEditor.Filename );
        out = [ file, ext ];
    end
end
end
