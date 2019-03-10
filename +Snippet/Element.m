classdef Element < handle & matlab.mixin.CustomDisplay & matlab.mixin.Copyable
    % ELEMENT is a superclass for snippet elements like static text, tabstop,
    % regular expression and array.
    
    %#ok<*INUSD>
    %#ok<*MANU>
    
    methods( Abstract )
        
        str = toChar(obj)
        % TOCHAR converts the snippet element to the character vector.
        %
        % Syntax:
        %   str = TOCHAR(obj);
        %
        % Outputs:
        %   str ... character vector
        %
        
    end
    
    methods
        
        function value = getPlaceholder(obj,number)
            % GETPLACEHOLDER gets placeholder for the first tabstop with the 
            % matching number and nonempty placeholder.
            %
            % Syntax:
            %   value = GETPLACEHOLDER(obj,number)
            %
            % Inputs:
            %   number ... tabstop number
            %
            % Outputs:
            %   value .... character vector
            %
            value = [];
        end   
        
        
        
        function setPlaceholder(obj,number,value)
            % SETPLACEHOLDER sets placeholder to all tabstops with the
            % matching number.
            %
            % Syntax:
            %   SETPLACEHOLDER(obj,number,value)
            %
            % Inputs:
            %   number ... tabstop number
            %   value .... character vector
            %
        end
        
        
        
        function placeholderObject = getPlaceholderObject(obj,number)
            % GETPLACEHOLDER gets placeholder object for the first tabstop with the 
            % matching number and nonempty placeholder.
            %
            % Syntax:
            %   value = GETPLACEHOLDER(obj,number)
            %
            % Inputs:
            %   number ... tabstop number
            %
            % Outputs:
            %   placeholderObject .... placeholder object (character vector or
            %                          Snippet.Element object)
            %
            placeholderObject = [];
        end       
        
        
        
        function setPlaceholderObject(obj,number,placeholderObject) 
            % SETPLACEHOLDEROBJECT sets placeholder object to all tabstops with 
            % the matching number.
            %
            % Syntax:
            %   SETPLACEHOLDEROBJECT(obj,number,placeholderObject)
            %
            % Inputs:
            %   number ............... tabstop number
            %   placeholderObject .... placeholder object (character vector or
            %                          Snippet.Element object)
            %
        end  
        
        
        
        function [iStart,iEnd] = getPlaceholderPosition(obj,number)
            % GETPLACEHOLDERPOSITION returns position indexes of all 
            % placeholders with the matching tabstop number. The indexes give
            % character positions in the cell array returned by the toChar().
            %
            % Syntax:
            %   [iStart,iEnd] = getPlaceholderPosition(obj,number)
            %
            % Inputs:
            %   number ... tabstop number
            %
            % Outputs:
            %   iStart ... placeholder first character positions (1,n)
            %   iEnd ..... placeholder last character positions (1,n)
            %
            iStart = [];
            iEnd = [];
        end
        
        
        
        function numbers = getTabstopNumbers(obj) 
            % GETTABSTOPNUMBERS returns an array of sorted unique placeholder
            % numbers.
            %
            % Syntax:
            %   numbers = getTabstopNumbers(obj)
            %
            % Outputs:
            %   number ... an array of unique tabstop numbers
            %
            numbers = [];
        end
        
        
        
        function tabstopObject = getTabstopObject(obj,number)
            % GETTABSTOPOBJECT gets tabstop object for the first tabstop 
            % with the matching number and nonempty placeholder.
            %
            % Syntax:
            %   tabstopObject = GETTABSTOPOBJECT(obj,number)
            %
            % Inputs:
            %   number ... tabstop number
            %
            % Outputs:
            %   tabstopObject .... tabstop object (Snippet.Element)
            %
            tabstopObject = [];
        end   
        
        
        
        function isMirrored = isMirrored(obj,number)
            % ISMIRRORED indicates if the tabstop number is mirrored in the 
            % snippet.
            %
            % Syntax:
            %   isMirrored = isMirrored(obj,number)
            %
            % Inputs:
            %   number ... tabstop number
            %
            % Outputs:
            %   isMirrored .... tabstop mirroring indicator (logical)
            %            
            isMirrored = false;
        end
                
    end
    
    methods (Access = protected)
        
        function displayScalarObject(obj)
            % DISPLAYSCALARBOJECT displays the object to the command window
            fprintf('<strong>Snippet:</strong>\n');            
            disp(obj.toChar());            
            disp(' ');
            tabstopNumbers = getTabstopNumbers(obj);            
            fprintf('<strong>Tabstop numbers:</strong>\n');
            disp(num2str(tabstopNumbers(:)'));
            disp(' ');
        end
        
    end
    
end
