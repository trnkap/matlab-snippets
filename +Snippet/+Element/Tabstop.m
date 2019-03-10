classdef Tabstop < Snippet.Element
    % TABSTOP represents a snippet tabstop element with a placeholder
    
    properties ( Access = protected )
        number % tabstop number
    end
    
    properties
        value % placeholder value (character vector or Snippet.Element object)        
    end
        
    methods
                       
        function obj = Tabstop(number,value)
            % TABSTOP constructs snippet tabstop element.
            % 
            % Syntax:
            %   obj = TABSTOP(number,value)
            %
            % Inputs:
            %   number ... tabstop number (scalar)
            %   value .... character vector or Snippet.Element object
            %            
            if nargin>0
                if ~ischar(value) && ~isa(value,'Snippet.Element')
                    error(['Value input argument must be either ' ...
                        'a character vector or Snippet.Element object.']);
                end
                obj.number = number;
                obj.value  = value;
            end
        end
        
        
        
        function str = toChar(obj)
            if isa(obj.value,'Snippet.Element')
                str = obj.value.toChar();
            else
                str = obj.value;
            end
        end
        
        
        
        function value = getPlaceholder(obj,number)
            if obj.number == number
                value = obj.toChar();
            elseif isa(obj.value,'Snippet.Element')
                % --- Nested tabstops with lower "priority"
                value = obj.value.getPlaceholder(number);
            else
                value = [];
            end
        end        
        
        
        
        function setPlaceholder(obj,number,value)
            if ~ischar(value)
                error('Value input argument must be a character vector.');
            end
            if obj.number == number
                % Any nested placeholders will be deleted 
                obj.value = value;                
            elseif isa(obj.value,'Snippet.Element')
                obj.value.setPlaceholder(number,value);
            end
        end
        
        
        
        function placeholderObject = getPlaceholderObject(obj,number)
            if obj.number == number
                placeholderObject = obj.value;
            elseif isa(obj.value,'Snippet.Element')
                % --- Nested tabstops with lower "priority"
                placeholderObject = obj.value.getPlaceholderObject(number);
            else
                placeholderObject = [];
            end
        end  
        
        
        
        function setPlaceholderObject(obj,number,placeholderObject)
            if obj.number == number
                % Any nested placeholders will be deleted 
                if isa(placeholderObject,'Snippet.Element')
                    obj.value = copy( placeholderObject ); % !!! copy !!!
                else
                    obj.value = placeholderObject;
                end
            elseif isa(obj.value,'Snippet.Element')
                obj.value.setPlaceholderObject(number,placeholderObject);
            end
        end        
        
        
        
        function [iStart,iEnd] = getPlaceholderPosition(obj,number)
            if obj.number == number                
                iStart = 1;
                iEnd = length(obj.toChar());
            elseif isa(obj.value,'Snippet.Element')
                % --- Nested tabstops with lower "priority"
                [iStart,iEnd] = getPlaceholderPosition(obj.value,number);
            else
                iStart = [];
                iEnd = [];
            end
        end
        
        
        
        function numbers = getTabstopNumbers(obj)
            numbers = obj.number;
            if isa(obj.value,'Snippet.Element')
                numbers = [ numbers getTabstopNumbers(obj.value) ];
            end
            numbers = sort(unique(numbers));
        end    
        
        
        
        function tabstopObject = getTabstopObject(obj,number)
            if obj.number == number && ~isempty(obj.value)
                tabstopObject = obj;
            elseif isa(obj.value,'Snippet.Element')
                % --- Nested tabstops with lower "priority"
                tabstopObject = obj.value.getTabstopObject(number);
            else
                tabstopObject = [];
            end            
        end  
        
        
        
        function isMirrored = isMirrored(obj,number)
            if isa(obj.value,'Snippet.Element')
                isMirrored = ...
                    obj.value.isMirrored(number) || ...
                    ismember( obj.number, getTabstopNumbers(obj.value));
            else
                isMirrored = false;
            end
        end                
        
    end
    
end