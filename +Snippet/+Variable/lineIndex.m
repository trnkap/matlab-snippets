function out = lineIndex()
% zero-based
activeEditor = getActiveEditor();
if isempty(activeEditor)
    out = '';
else    
    out = num2str( activeEditor.JavaEditor.getLineNumber );
end
end