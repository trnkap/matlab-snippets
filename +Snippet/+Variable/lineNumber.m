function out = lineNumber()
% one-based
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    if verLessThan('matlab', '9.11.0')
        out = num2str( activeEditor.JavaEditor.getLineNumber+1 );
    else
        out = activeEditor.Selection(1);
    end
end
end