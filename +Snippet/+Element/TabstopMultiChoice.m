classdef TabstopMultiChoice < Snippet.Element
    % TABSTOPMULTICHOICE represents a snippet tabstop element with 
    % a multi-choice placeholder.
    
    properties ( Access = private )
        number % tabstop number
        choices % possible choices (cell array of character vectors)
    end
    
    properties
        choiceIndex % current choice index
    end
    
    methods
        
        function obj = TabstopMultiChoice(number,choices)
            % TABSTOPMULTICHOICE constructs snippet tabstop element with
            % multiple choices.
            %
            % Syntax:
            %   obj = TABSTOPMULTICHOICE(number,choices)
            %
            % Inputs:
            %   number .... tabstop number (scalar)
            %   choices ... possible choices (cell array of character vectors)
            %
            if isempty(choices) || ~iscell(choices) || ~all(cellfun(@(c)ischar(c),choices))
                error(['The input argument "choices" must be a non-empty ' ...
                    'cell array of character vectors.']);
            end
            obj.number = number;
            obj.choices = choices;
            obj.choiceIndex = 1;
        end
        
        
        
        function nextChoice = getNextChoice(obj)
            choiceIndex_ = min( obj.choiceIndex+1, length(obj.choices) );
            nextChoice = obj.choices{ choiceIndex_ };
        end
        
        
        
        function previousChoice = getPreviousChoice(obj)
            choiceIndex_ = max( 1 , obj.choiceIndex-1 );
            previousChoice = obj.choices{ choiceIndex_ };
        end
        
        
        
        function str = toChar(obj)
            str = obj.choices{obj.choiceIndex};
        end
        
        
        
        function value = getPlaceholder(obj,number)
            if obj.number == number
                value = obj.toChar();
            else
                value = [];
            end
        end                
        
        
        
        function setPlaceholder(obj,number,value)
            if number == obj.number
                ind = find( strcmp(obj.choices,value) );
                if isempty(ind)
                    warning(['Value "' value '" is not in the list of multi-choice placeholder possible choices.']);
                    ind = 1;
                end 
                obj.choiceIndex = ind(1);
            end
        end
        
        
        
        function placeholderObject = getPlaceholderObject(obj,number)
            if obj.number == number
                placeholderObject = obj.toChar();
            else
                placeholderObject = [];
            end
        end        
        
        
        
        function setPlaceholderObject(obj,number,placeholderObject)
            if obj.number == number
                if ischar(placeholderObject)
                    obj.setPlaceholder(number,placeholderObject);
                else
                    error('The input argument "placeholderObject" must be a character vector.');
                end
            end
        end            
        
        
        
        function [iStart,iEnd] = getPlaceholderPosition(obj,number)
            if obj.number == number
                iStart = 1;
                iEnd = length(obj.toChar());
            else
                iStart = [];
                iEnd = [];
            end
        end
        
        
        
        function numbers = getTabstopNumbers(obj)
            numbers = obj.number;
        end   
        
        
        
        function tabstopObject = getTabstopObject(obj,number)
            if obj.number == number && ~isempty(obj.choices)
                tabstopObject = obj;
            else
                tabstopObject = [];
            end            
        end                      
        
    end
    
end