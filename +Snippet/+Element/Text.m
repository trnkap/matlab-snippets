classdef Text < Snippet.Element
    % TEXT represents a snippet element with a static text
    
    properties( Access = private )
        text
    end
    
    methods
        
        function obj = Text(text)
            % TEXT constructs snippet text element
            %
            % Syntax:
            %   obj = TEXT(text)
            %
            % Inputs:
            %   text ... cell array
            %
            if ~ischar(text)
                error('The input argument must a character vector.');
            end
            
            % --- Restore reserved characters
            text = strrep( text, '\$', '$' );
            text = strrep( text, '\`', '`' );
            
            obj.text = text;
        end
        
        
        
        function str = toChar(obj)
            str = obj.text;
        end                
                
    end
    
end
