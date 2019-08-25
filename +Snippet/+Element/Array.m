classdef Array < Snippet.Element
    % ARRAY represents an array of of snippet elements like static text, 
    % tabstop, regular expression and array.
    
    %#ok<*AGROW>
    
    properties ( Access = protected )
        array % cell array of Spippet.Element objects
    end
    
    methods
        
        function obj = Array(array)
            % ARRAY constructs snippet element array.
            % 
            % Syntax:
            %   obj = ARRAY(array)
            %
            % Inputs:
            %   array ... a cell array of Snippet.Element objects
            %   
            if nargin==0 || isempty(array)
                obj.array = {};
            else
                if iscell(array)
                    for i = 1 : length(array)
                        if ~isa(array{i},'Snippet.Element')
                            error('The input argument must be a cell array of Snippet.Element objects.');
                        end
                    end
                    obj.array = array;
                else
                    error('The input argument must be a cell array of Snippet.Element objects.');
                end
            end
        end
        
        
        
        function str = toChar(obj)
            if isempty(obj.array)
                str = '';
            else
                str = strjoin( ...
                    cellfun(@(c)c.toChar(), obj.array, 'UniformOutput', false), ...
                    '' );
            end
        end

        
        
        function value = getPlaceholder(obj,number)
            value = [];
            values = cellfun( ...
                @(c)getPlaceholder(c,number), ...
                obj.array, 'UniformOutput', false );
            for i = 1 : length(values)
                if ~isempty(values{i}) 
                    if isempty(value)
                        value = values{i};
                    elseif ~strcmp(value,values{i})
                        %warning(['Tabstop number ' num2str(number) ' has multiple conflicting placeholders "' value '" and "' values{i} '".']);
                        % --- warning disabled because it might be falsely triggered by
                        % --- more complex snippets that combine nested regular
                        % --- expressions.
                    end
                end
            end
        end
        
        
        
        function setPlaceholder(obj,number,value)
            cellfun( ...
                @(c)setPlaceholder(c,number,value), ...
                obj.array );
        end
        
        
        
        function placeholderObject = getPlaceholderObject(obj,number)
            placeholderObject = [];
            objects = cellfun( ...
                @(c)getPlaceholderObject(c,number), ...
                obj.array, 'UniformOutput', false );
            for i = 1 : length(objects)
                if ~isempty(objects{i})
                    if isempty(placeholderObject)
                        placeholderObject = objects{i};
                    elseif ~isequal(placeholderObject,objects{i})
                        warning(['Tabstop number ' num2str(number) ' has multiple conflicting placeholder definitions.']);
                    end
                end
            end
        end
        
        
        
        function setPlaceholderObject(obj,number,placeholderObject)
            cellfun( ...
                @(c)setPlaceholderObject(c,number,placeholderObject), ...
                obj.array );
        end        
        
        
        
        function [iStart,iEnd] = getPlaceholderPosition(obj,number)
            iStart = [];
            iEnd = [];            
            iend = 0;
            for i = 1 : length(obj.array)
                element = obj.array{i};
                [iStart_,iEnd_] = getPlaceholderPosition(element,number);
                if ~isempty(iStart_) && ~isempty(iEnd_)
                    if any(iStart_<1) || any( iEnd_ > length(element.toChar()) )
                        error('Placeholder indexes out of range.');
                    end
                    iStart = [iStart iend+iStart_]; 
                    iEnd   = [iEnd   iend+iEnd_];
                end
                iend = iend + length(element.toChar());
            end
        end
        
        
        
        function numbers = getTabstopNumbers(obj)
            numbers = [];
            for i = 1 : length(obj.array)
                number = obj.array{i}.getTabstopNumbers();
                if ~isempty(number)
                    numbers = [ numbers number ];
                end
            end    
            numbers = sort(unique(numbers));
        end   
        
        
        
        function tabstopObject = getTabstopObject(obj,number)
            tabstopObject = [];
            tabstopObjects = cellfun( ...
                @(c)getTabstopObject(c,number), ...
                obj.array, 'UniformOutput', false );
            for i = 1 : length(tabstopObjects)
                if ~isempty(tabstopObjects{i})                    
                    % return either the first object or the first with the 
                    % non-empty "value" property
                    if isempty(tabstopObject)
                        tabstopObject = tabstopObjects{i};
                    end
                    hasValue = isprop(tabstopObject,'value') && ~isempty(tabstopObject.value);
                    if hasValue
                        return
                    end
                end
            end
        end  
        
        
        
        function isMirrored = isMirrored(obj,number)
            isMirrored = false;
            numberMatches = false(size(obj.array));
            for i = 1 : length(obj.array)
                isMirrored = ...
                    isMirrored || ...
                    obj.array{i}.isMirrored(number);
                numberMatches(i) = ...
                    ismember(number,obj.array{i}.getTabstopNumbers());
            end    
            isMirrored = isMirrored || (sum(numberMatches)>=2);
        end           
        
    end
    

    methods(Access = protected)
        function cp = copyElement(obj)
            cp = Snippet.Element.Array;
            cp.array = {};
            for i = 1 : length(obj.array)
                if isa(obj.array{i},'Snippet.Element')
                    cp.array{i} = copy(obj.array{i});
                else
                    cp.array{i} = obj.array{i};
                end
            end
        end
    end
    
    
end