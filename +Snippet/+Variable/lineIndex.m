function out = lineIndex()
% zero-based
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    if verLessThan('matlab', '9.11.0')
        out = num2str( activeEditor.JavaEditor.getLineNumber );
    else
        out = activeEditor.Selection(1) - 1;
    end
end
end