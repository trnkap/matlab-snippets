classdef Regexp < Snippet.Element.Tabstop
    % REGEXP represents a snippet tabstop element with a regular replacement 
    % epxression to mirror other tabstops.
    
    %#ok<*INUSD>
    
    properties ( Access = private )
        expression % regexprep arument
        format % regexprep arument
        options % regexprep arument
    end
        
    methods
                       
        function obj = Regexp(number,expression,format,options)
            % TABSTOP constructs snippet tabstop element.
            % 
            % Syntax:
            %   obj = TABSTOP(number,value)
            %
            % Inputs:
            %   number ... tabstop number (scalar)
            %   <TextMate placeholder transformation arguments>
            %            
            obj.number = number;
            obj.value  = '';
            [obj.expression,obj.format,obj.options] = ...
                textMate2regexprep(expression,format,options);
        end
        
        
        
        function str = toChar(obj)
            str = toChar@Snippet.Element.Tabstop(obj);
            % ---
            if ~isempty(obj.expression)
                % --- Replace using regular expression
                str = regexprep( ...
                    str, ...
                    obj.expression, ...
                    obj.format, ...
                    obj.options{:});
                % --- Questionable fix: char([13 10]) -> char(10)
                str = strrep(str,char([13 10]),char(10)); %#ok<CHARTEN>
            end
        end
        
        
        
        function value = getPlaceholder(obj,number)
            % no result from the regular expression element
            value = [];
        end        
        
        
        
        function placeholderObject = getPlaceholderObject(obj,number) 
            % no result from the regular expression element
            placeholderObject = [];
        end  
               
        
        
        function [iStart,iEnd] = getPlaceholderPosition(obj,number)
            % no result from the regular expression element
            iStart = [];
            iEnd = [];
        end

        
        
        function tabstopObject = getTabstopObject(obj,number)
            % no result from the regular expression element
            tabstopObject = [];
        end  
                        
    end
    
end