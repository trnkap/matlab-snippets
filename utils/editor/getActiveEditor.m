function activeEditor = getActiveEditor()
% GETACTIVEEDITOR gets the active document in the editor.
%
% Syntax:
%   activeEditor = getActiveEditor()
%
% Outputs:
%   activeEditor - active editor object (matlab.desktop.editor.Document)
%
% Based on: 
% https://nl.mathworks.com/matlabcentral/fileexchange/41704-insert-a-piece-of-code-a-snippet-in-the-matlab-editor
%
if verLessThan('matlab', '8.1.0')
    activeEditor = editorservices.getActive;
else
    activeEditor = matlab.desktop.editor.getActive;
end
end

