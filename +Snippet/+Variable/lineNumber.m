function out = lineNumber()
% one-based
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else
    out = num2str( activeEditor.JavaEditor.getLineNumber+1 );
end
end