classdef Snippet < Snippet.Element.Array
    % SNIPPET encapsulates a snippet constructed from the TextMate syntax.
    %
    % Selected Properties and Methods:
    %
    % SNIPPET Methods:
    %   SNIPPET - constructs a snippet from a string with the
    %   TextMate snippet syntax (https://macromates.com/manual/en/snippets).
    %   This syntax is also used to define snippets in Visual Studio Code 
    %   (https://code.visualstudio.com/docs/editor/userdefinedsnippets).
    %     
    
    % --------------------------------------------------------------------------
    % Author: Pavel Trnka (pavel@trnka.name)
    % Feb 2019
    % --------------------------------------------------------------------------
    
    %#ok<*AGROW>
        
    methods
        
        function obj = Snippet(body)
            % SNIPPET constructs a snippet from a string with the
            % TextMate snippet syntax (https://macromates.com/manual/en/snippets).
            % This syntax is also used to define snippets in Visual Studio Code
            % (https://code.visualstudio.com/docs/editor/userdefinedsnippets).
            %
            % Syntax:
            %   obj = Snippet(body)
            %
            % Inputs:
            %   body ... snippet definition using TextMate syntax (character
            %   vector or cell array of character vectors). Assumes that escape
            %   sequences '\n' and '\t' were already converted to their
            %   respective characters.
            %
            % Example:
            %   body = { 
            %       'for ${1:i} = ${2:1} : ${3:N}'
            %       '\t$0'
            %       'end' };
            %   body = sprintf( strjoin(body, '\n') );
            %   obj = Snippet.Snippet( body );
            %   disp(obj);
            %
            
            % --- Matlab editor tab size
            if verLessThan('matlab','9.4') % R2018a
                tabSize = 4;
            else
                matlabSettings = settings();
                tabSize = matlabSettings.matlab.editor.tab.TabSize.ActiveValue;
            end
            
            % --- Replace tabulator by spaces
            body = strrep( body, sprintf('\t'), repmat(' ',1,tabSize));
               
            % --- Convert to character vector
            if iscell(body)
                body = strjoin(body,'');
            end
            
            % --- Parse the snippet definition
            snippet = parseSnippet(body);
            
            % --- Create the snippet tree root (as a single element array)
            obj.array{1} = snippet;
        end
                        
    end
    
    
    
    methods (Static)
        
        function [snippets,fileModifiedDate] = load(jsonFileNames)
            % LOAD Loads snippets from a JSON file.
            %
            % Inputs:
            %   jsonFileNames ... a cell array of json file names
            %
            % Outputs:
            %   snippets ... an array of structures describing snippets with fields:
            %     .body ............... snippet definition
            %     .description ........ short snippet description
            %     .scope .............. snippet scope
            %     .usesSelectedText ... flag indicating a use of $TM_SELECTED_TEXT variable
            %   fileModifiedDate ... a cell array of json file creation dates
            %
            
            validateattributes(jsonFileNames,{'cell'},{});
            
            snippets = [];
            clear snippets
            cnt = 1;
            
            fileModifiedDate = {};
            
            for ifile = 1 : length(jsonFileNames)
                jsonFileName = jsonFileNames{ifile};
                % --- Read file
                fid = fopen(jsonFileName);
                if fid==-1
                    error(['Cannot open snippet definition file "' jsonFileName '".']);
                end
                str = '';
                while ~feof(fid)
                    tline = fgetl(fid);
                    str = [ str tline ];
                end
                fclose(fid);
                % --- Try to decode json
                try
                    if verLessThan('matlab','9.1') % R2016b
                        if exist('loadjson','file')
                            json = loadjson(str); % 3rd party function: https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab-a-toolbox-to-encode-decode-json-files
                        else
                            choice = questdlg('Insert Snippet requires "JSONlab" toolbox to run on Matlab R2016a and earlier.', ...
                                'Insert Snippet', ...
                                'Download JSONlab','Cancel','Download JSONlab');
                            if strcmp(choice,'Download JSONlab')
                                web('https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab-a-toolbox-to-encode-decode-json-files');
                            end
                            return
                        end
                    else
                        json = jsondecode(str);
                    end
                catch ME
                    msg = ['Snippet definition (json) file "' jsonFileName '" parsing error.'];
                    causeException = MException('InsertSnippet:jsonDecodeError',msg);
                    ME = addCause(ME,causeException);
                    rethrow(ME);
                end
                
                % --- Create an array of snippets
                fldnames = fieldnames(json);
                for i = 1 : length(fldnames)
                    snippet = json.(fldnames{i});
                    snippet.name = fldnames{i};
                    if iscell(snippet.body)
                        snippet.body = strjoin(snippet.body,'\n');
                    end
                    if ~isfield(snippet,'description')
                        snippet.description = '';
                    end
                    if ~isfield(snippet,'scope')
                        snippet.scope = '';
                    end
                    % ---
                    snippet.usesSelectedText = ...
                        ~isempty( regexp(snippet.body,'\${?\s*TM_SELECTED_TEXT','once') );
                    % ---
                    snippets(cnt) = snippet;
                    cnt = cnt + 1;
                end
                
                % --- File modification data
                listing = dir( which(jsonFileName) );
                fileModifiedDate{ifile} = listing.date;
                
            end
            
            % --- Sort by a prefix
            [~,ind] = sort({snippets.prefix});
            snippets = snippets(ind);
            
        end
        
    end
        
end



function obj = parseSnippet(body)
% PARSESNIPPET parses snippet definition to a tree of Snippet.Element objects.
%
% Inputs:
%   body ... snippet definition using TextMate syntax
%
% Outputs:
%   obj .... a tree of of Snippet.Element objects representing the snippet
%

body = replaceVariablesByValues(body);

% --- Recursive parsing
obj = parseSnippetFragment(body);

% --- Unify placeholders of tabstops with the same number
tabstopNumbers = obj.getTabstopNumbers();
for i = tabstopNumbers(:)'
    % --- Get first non-empty placeholder object (can contain embedded tabstops)
    placeholderObject = obj.getPlaceholderObject(i);
    % --- Set placeholder object to all tabstops with the same number
    if ~isempty(placeholderObject)
        obj.setPlaceholderObject(i,placeholderObject);
    end
end

end



function body = replaceVariablesByValues(body)
% REPLACEVARIABLESBYVALUES replaces variables in the snippet body $<var_name> 
% by their values.
%
variableReplacementTbl = {
    % variable                 replacement string/function handle
    'TM_SELECTED_TEXT'         @Snippet.Variable.selectedText   % currently selected text or the empty string
    'TM_CURRENT_LINE'          @getLineAtCaretPosition          % contents of the current line
    'TM_CURRENT_WORD'          @getWordAtCaretPosition          % contents of the word under cursor or the empty string
    'TM_LINE_INDEX'            @Snippet.Variable.lineIndex      % zero-index based line number
    'TM_LINE_NUMBER'           @Snippet.Variable.lineNumber     % one-index based line number
    'TM_FILENAME_BASE'         @Snippet.Variable.fileNameBase   % filename of the current document without its extensions
    'TM_FILENAME'              @Snippet.Variable.fileName       % filename of the current document
    'TM_DIRECTORY'             @Snippet.Variable.directory      % directory of the current document
    'TM_FILEPATH'              @Snippet.Variable.filePath       % full file path of the current document
    'TM_USERNAME'              @Snippet.Variable.userName       % Windows user name
    'CLIPBOARD'                @Snippet.Variable.clipBoard      % contents of the clipboard
    'CURRENT_YEAR'             @Snippet.Variable.year           % current year
    'CURRENT_YEAR_SHORT'       @Snippet.Variable.yearShort      % current year's last two digits
    'CURRENT_MONTH'            @Snippet.Variable.month          % month as two digits (example '02')
    'CURRENT_MONTH_NAME'       @Snippet.Variable.monthName      % full name of the month (example 'July')
    'CURRENT_MONTH_NAME_SHORT' @Snippet.Variable.monthNameShort % short name of the month (example 'Jul')
    'CURRENT_DATE'             @Snippet.Variable.date           % day of the month
    'CURRENT_DAY_NAME'         @Snippet.Variable.dayName        % name of day (example 'Monday')
    'CURRENT_DAY_NAME_SHORT'   @Snippet.Variable.dayNameShort   % short name of the day (example 'Mon')
    'CURRENT_HOUR'             @Snippet.Variable.hour           % current hour in 24-hour clock format
    'CURRENT_MINUTE'           @Snippet.Variable.minute         % current minute
    'CURRENT_SECOND'           @Snippet.Variable.second         % current second
    'MATLAB_VERSION'           @version                         % Matlab version
    };
   
expression = [ '\$'   '\s*'   '({?)'   '\s*'   '([a-zA-Z_]\w*)'   '(?(1)\s*|)'   '(?(1)[:/]|)' ];
%                             ^                ^                  ^              ^
%                             |                |                  |              |
%    (optional opening bracket)                |                  |              |
%                                              |                  |              |
%                                (variable name)                  |              |
%                                                                 |              |
%                  (allows space(s) if opening bracket was matched)              |
%                                                                                |
%                             (requires ':' or '/' if opening bracket was matched)

iterMax = 1e3;
for iter = 1 : iterMax
    [startIndex,endIndex,tokens] = ...
        regexp(body,expression,'start','end','tokens','once');
    if isempty(startIndex)
        break
    else
        varName = tokens{2};
        switch tokens{4}
            case ''
                tokenType = 'plain';
            case ':'
                tokenType = 'withDefaultValue';
            case '/'
                tokenType = 'regexprep';
            otherwise
                error(['Unknown token type with opening character "' tokens{4} '".']);
        end
        % --- Default value
        defaultValue = '';
        if strcmp(tokenType,'plain')            
            closingBracketIndex = endIndex; % misleading name
        else
            closingBracketIndex = ...
                endIndex + findMatchingClosingBracket(body(endIndex+1:end));
            if isempty(closingBracketIndex)
                error([ ...
                    'Cannot find matching closing bracket for variable "' ...
                    varName '".']);
            end
            if strcmp(tokenType,'withDefaultValue')
                defaultValue = body(endIndex+1:closingBracketIndex-1);
            end
        end
        % --- Find variable name
        irow = find(strcmp(variableReplacementTbl(:,1),varName),1);
        % --- Replacement string
        if isempty(irow)
            replacementString = defaultValue;
        else
            if isa( variableReplacementTbl{irow,2}, 'function_handle')
                replacementString = variableReplacementTbl{irow,2}();
            else
                replacementString = variableReplacementTbl{irow,2};
            end            
            if strcmp(tokenType,'regexprep')
                regexpTokens = decomposeRegexpPlaceholder( ...
                    body(endIndex+1:closingBracketIndex-1) );
                if length(regexpTokens)~=3
                        error(['Error in parsing token with the reqular expression "' body(endIndex+1:closingBracketIndex-1) '"']);
                end
                [expression_,format_,options_] = textMate2regexprep(regexpTokens{:});
                replacementString = regexprep( ...
                    replacementString, expression_, format_, options_{:} );
                % --- Questionable fix: char([13 10]) -> char(10)
                replacementString = strrep(replacementString,char([13 10]),char(10)); %#ok<CHARTEN>
            end
        end
    end
    body = [ body(1:startIndex-1) replacementString body(closingBracketIndex+1:end) ];
end
if iter == iterMax
    error('Maximum number of iterations reached.');
end

end



function obj = parseSnippetFragment(body)
% PARSESNIPPETFRAGMENT recursively parses snippet definition to a tree of 
% Snippet.Element objects.
%
% Inputs:
%   body ... snippet definition fragment using TextMate syntax
%
% Outputs:
%   obj .... a tree of of Snippet.Element objects representing the snippet
%   fragment
%
if isempty(body)
    obj = Snippet.Element.Text('');
else
    array = {};
    while ~isempty(body)
        
        % --- Find tabstop:
        %     * plain:             '$1','$2',... 
        %     * with placeholder:  '${1:','${2:',...
        %     * with regexp:       '${1/','${2/',...
        %     * with multi-choice: '${1|','${2|',...
        
        expression = [ '\$'   '\s*'   '({?)'   '\s*'   '(\d+)'   '(?(1)\s*|)'   '(?(1)[:/|]|)' ];
        %                             ^                ^         ^              ^
        %                             |                |         |              |
        %    (optional opening bracket)                |         |              |
        %                                              |         |              |
        %                               (tabstop number)         |              |
        %                                                        |              |
        %         (allows space(s) if opening bracket was matched)              |
        %                                                                       |
        %             (requires ':' or '/' or '|' if opening bracket was matched)
        

        [startIndex,endIndex,tokens] = ...
            regexp(body,expression,'start','end','tokens','once');
               
        if isempty(startIndex)            
            % --- Text only
            array{end+1} = Snippet.Element.Text(body); 
            % ---
            body = '';            
        else           
            % --- Process tabstop
            tokenNumberStr = tokens{2};
            tokenTypeChar  = tokens{4}; % '' or ':' or '/' or '|'
            % --- Text before tabstop
            if startIndex>1
                array{end+1} = Snippet.Element.Text(body(1:startIndex-1));
            end
            % --- Tabstop number
            tabstopNumber = str2double(tokenNumberStr);            
            % ---
            if isempty(tokenTypeChar)
                % --- Plain tabstop '$1','$2',...
                array{end+1} = Snippet.Element.Tabstop(tabstopNumber,'');
                body = body(endIndex+1:end);
            else                
                % --- Find matching closing bracket
                closingBracketIndex_ = findMatchingClosingBracket( body(endIndex+1:end) );
                if isempty(closingBracketIndex_)
                    error([ ...
                        'Cannot find matching closing bracket for the tabstop "' ...
                        body(startIndex:endIndex) '".']);
                end
                closingBracketIndex = closingBracketIndex_ + endIndex;
                % --- Placeholder
                placeholder = body(endIndex+1:closingBracketIndex-1);
                % ---
                switch tokenTypeChar
                    
                    case ':' % tabstop with placeholder: '${1:','${2:',...
                        % --- Parse the placeholder to check for embedded placeholders
                        obj_ = parseSnippetFragment(placeholder);
                        if isa(obj_,'Snippet.Element.Text')
                            % --- plain text placeholder
                            array{end+1} = Snippet.Element.Tabstop(tabstopNumber,placeholder);
                        else
                            % --- placeholder with embedded tabstops
                            array{end+1} = Snippet.Element.Tabstop(tabstopNumber,obj_);
                        end
                        
                    case '/' % tabstop with regexp: '${1/','${2/',...
                        tokens_ = decomposeRegexpPlaceholder(placeholder);
                        if length(tokens_)~=3
                            error(['Error in parsing token with the reqular expression "' placeholder '"']);
                        end                        
                        array{end+1} = Snippet.Element.Regexp(tabstopNumber,tokens_{:});
                        
                    case '|' % tabstop with multi-choice: '${1|','${2|',...
                        if isempty(placeholder) || placeholder(end)~='|'
                            error('Multi-choice placeholder parsing error.');
                        else
                            % --- Multi-choice placeholder
                            choices = strsplit( placeholder(1:end-1), ',' );
                            array{end+1} = Snippet.Element.TabstopMultiChoice(tabstopNumber,choices);
                        end
                        
                    otherwise
                        error(['Unknown token type with opening character "' tokenTypeChar '".']);
                        
                end
                % ---
                body = body(closingBracketIndex+1:end);
            end
            
        end        
    end
    
    % --- Avoid single element array
    if length(array)==1
        obj = array{1};
    else
        obj = Snippet.Element.Array( array );
    end
    
end
end




