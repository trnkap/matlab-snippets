function out = fileName()
% The filename of the current document
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    out = char( activeEditor.JavaEditor.getShortName );
end
end
