function insertSnippet()
% INSERTSNIPPET is the entry point to the MATLAB Snippets App.
%

% ------------------------------------------------------------------------------
% Author: Pavel Trnka (pavel@trnka.name)
% Feb 2019
% ------------------------------------------------------------------------------

%#ok<*AGROW>

windowTag       = 'insertSnippetWindow';
optionsFileName = 'insertSnippetOptions.mat';
versionStr      = '1.0';

% --- Search for the hidden App window and show it if it exists ----------------
if showHiddenWindow(windowTag)
    return
end

% --- Initialize "nested" variables --------------------------------------------
snippets             = []; % snippets subset
canDeleteWordAtCaret = []; % indicates if the word at caret can be deleted (logical)
isTextSelected       = []; % indicates if user has selected some text (logical)
wordAtCaretPosition  = []; % current word at the caret postion (char)
lastValidText        = []; % last valid text from the code pane
h                    = struct(); % ui handles
current              = struct();
parsedSnippet        = [];

% --- Load options -------------------------------------------------------------
opt = loadOptions(optionsFileName);

% --- Ask to add to favorites --------------------------------------------------
askToAddToFavorites();

% --- Load snippets ------------------------------------------------------------
[snippets0,fileModifiedDate] = ...
    Snippet.Snippet.load( opt.jsonFileNames(opt.isJsonFileEnabled) );

% --- Create figure ------------------------------------------------------------
createFigure();

% --- Initialize and show the GUI ----------------------------------------------
initializeGUI;


% ==============================================================================
    

    function createFigure()        
        % Creates the main figure and all UI components. Component dimensions
        % and positions are not set, this is done in the figureSizeChangedFcn
        % function.
        %
        screenSize = get(0, 'ScreenSize');
        h.Fig = figure( ...
            'WindowStyle', 'modal', ...
            'Position', [ 0.5*screenSize(3:4)-0.5*opt.figureSize opt.figureSize ], ...
            'DockControls', 'off', ...
            'MenuBar', 'none', ...
            'IntegerHandle', 'off', ...
            'NextPlot', 'new', ...
            'NumberTitle', 'off', ...
            'Name', 'Insert Snippet', ...
            'Tag', windowTag, ...
            'Visible', 'off', ...
            'KeyPressFcn', @figureKeyPressFcn, ...
            'DeleteFcn', @figureDeleteFcn, ...
            'SizeChangedFcn', @figureSizeChangedFcn, ...
            'CloseRequestFcn', @figureCloseRequestFcn );        
        h.EditBox = uicontrol( ...
            'Style','edit', ...
            'HorizontalAlignment', 'left', ...            
            'Tooltip','Snippet filter', ...
            ...'Interruptible','off', ...
            'KeyPressFcn',@editBoxKeyPressFcn );
        h.ListBox = uicontrol( ...            
            'Style','listbox', ...
            'Tooltip','Snippet list', ...
            'Callback', @listBoxCallback);
        h.Hint = uicontrol( ...
            'Style','text', ...
            'Enable','inactive', ...
            'HorizontalAlignment', 'left', ...
            'FontSize', 10 );
        updateHint('EditBox');
        h.ButtonConfig = uicontrol( ...
            'Style','pushbutton', ...
            'TooltipString','Configuration', ...
            'Callback',@buttonConfigCallback);
        h.ButtonAbout = uicontrol( ...
            'Style','pushbutton',...
            'TooltipString','About MATLAB Snippets', ...
            'Callback',@buttonAboutCallback);        
        h.ButtonHelp = uicontrol( ...
            'Style','pushbutton',...
            'TooltipString','Open documentation in the web browser.', ...
            'Callback',@buttonHelpCallback);                
        
        % --- Code pane
        h.CodePane = com.mathworks.widgets.SyntaxTextPane;
        codeType = com.mathworks.widgets.text.mcode.MLanguage.M_MIME_TYPE;
        h.CodePane.setContentType(codeType);
        jScrollPane = com.mathworks.mwswing.MJScrollPane(h.CodePane);
        [~,h.CodePaneContainer] = javacomponent(jScrollPane,[0 0 0 0],h.Fig);        
        % --- Add code pane to the <TAB> cycle
        h.CodePane.setFocusable(true);
        h.CodePane.putClientProperty('TabCycleParticipant', true);        
        % --- Move code pane right after edit box in the <TAB> cycle
        uistack(h.ListBox,'bottom');                
        uistack(h.ButtonConfig,'bottom');
        uistack(h.ButtonAbout,'bottom');
        uistack(h.ButtonHelp,'bottom');
        % --- Code pane callbacks
        h.jhCodePane = handle(h.CodePane,'CallbackProperties');
        set(h.jhCodePane, 'KeyPressedCallback',@codePaneKeyPressedCallback);        
        set(h.jhCodePane, 'KeyTypedCallback',@codePaneKeyTypedCallback); % printable characters only
        set(h.jhCodePane, 'FocusGainedCallback',@codePaneFocusGainedCallback);
        % --- !!!
        h.CodePaneContainer.Interruptible = 'off';        
        % --- Unify editbox and listbox font with the CodePane
        fnt = h.CodePane.getFont;
        fontName = get(fnt,'Name');
        fontExist = any(strcmp(listfonts,fontName));
        if fontExist
            h.ListBox.FontName = fontName;
            h.EditBox.FontName = fontName;
        end
        pxFontSize = fnt.getSize;
        ptFontSize = pxFontSize * 72 / get(0,'ScreenPixelsPerInch');
        h.ListBox.FontSize = ptFontSize;
        h.EditBox.FontSize = ptFontSize;        
        % --- Unify editbox and listbox colors with the CodePane
        jbcol = h.CodePane.getBackground;
        bcol = [jbcol.getRed jbcol.getGreen jbcol.getBlue]/255;
        jfcol = h.CodePane.getCaretColor;
        fcol = [jfcol.getRed jfcol.getGreen jfcol.getBlue]/255;
        h.EditBox.BackgroundColor = bcol;
        h.EditBox.ForegroundColor = fcol;
        h.ListBox.BackgroundColor = bcol;
        h.ListBox.ForegroundColor = fcol;
        
        % --- Config button image
        [~,~,transparency]=imread('configure_16_16.png');
        bgcol = [];
        bgcol(1,1,:) = h.ButtonConfig.BackgroundColor;
        img = repmat(bgcol,size(transparency,1),size(transparency,2));
        transparency = repmat(transparency,1,1,3);
        img = uint8(img.*double(255-transparency));
        h.ButtonConfig.CData = img;
        
        % --- About button image
        [A,map]=imread('about_16_16.png');
        map(A(1,1)+1,:) = h.ButtonConfig.BackgroundColor; 
        img = ind2rgb(A,map);
        h.ButtonAbout.CData = img;        
        
        % --- Help button image
        img=imread('help_16_16.png');
        img = replaceWhiteColor(img,250,255*0.95*h.ButtonConfig.BackgroundColor);
        h.ButtonHelp.CData = img;                
               
        % --- Userdata
        ud = struct( ...
            'showWindowFH',@showWindow);
        set(h.Fig,'Userdata',ud);        
        
    end


% ==============================================================================

    
    function figureSizeChangedFcn(src,~)
        margin = 5;
        editBoxHeight = 25;
        lPanelRatio = 3/8;
        hintHeight = 17+3;
        figSize = src.Position(3:4);
        buttonSize = 16+6;        

        h.EditBox.Position = [
            margin
            figSize(2)-editBoxHeight-margin
            lPanelRatio*figSize(1)-1.5*margin
            editBoxHeight ]';
        h.ListBox.Position = [
            margin
            hintHeight+2*margin
            lPanelRatio*figSize(1)-1.5*margin
            figSize(2)-editBoxHeight-hintHeight-4*margin
            ]';
        hintWidth = figSize(1)-3*margin-4.00*buttonSize;
        h.Hint.Position = [
            margin
            margin - 1
            hintWidth
            hintHeight
            ]';
        h.CodePaneContainer.Position = [
            lPanelRatio*figSize(1)+0.5*margin
            hintHeight+2*margin
            (1-lPanelRatio)*figSize(1)-1.5*margin
            figSize(2)-hintHeight-3*margin
            ];
        h.ButtonConfig.Position = [
            sum(h.CodePaneContainer.Position([1 3]))-3.75*buttonSize
            margin
            1.25*buttonSize
            buttonSize
            ]';
        h.ButtonAbout.Position = [
            sum(h.CodePaneContainer.Position([1 3]))-2.5*buttonSize
            margin
            1.25*buttonSize
            buttonSize
            ]';
        h.ButtonHelp.Position = [
            sum(h.CodePaneContainer.Position([1 3]))-1.25*buttonSize
            margin
            1.25*buttonSize
            buttonSize
            ]';
        
    end


% ==============================================================================


    function figureCloseRequestFcn(~,~)
        if opt.keepWindowLoaded
            h.Fig.Visible = 'off';
        else
            delete(h.Fig);
        end
    end


% ==============================================================================        


    function figureDeleteFcn(~,~)
        % --- Store current figure size to the options
        opt.figureSize = h.Fig.Position(3:4);        
        % --- Save options
        filePath = fileparts(mfilename('fullpath'));
        fullFileName = [ filePath filesep optionsFileName ];
        save(fullFileName,'opt');
    end


% ==============================================================================        


    function initializeGUI
        % INITIALIZEGUI resets the GUI to the default state
        %
        
        canDeleteWordAtCaret = true;
        
        % --- User has selected some text in the active editor -> show only
        % --- snippets that include the selected text variable and vice versa.
        isTextSelected = ~isempty(Snippet.Variable.selectedText);
        filterByWordAtCaretPosition = true;
        if opt.filterSnippetsIfTextSelected
            if isTextSelected
                filterByWordAtCaretPosition = false;
                canDeleteWordAtCaret = false;
                sel = [snippets0.usesSelectedText];
            else
                sel = ~[snippets0.usesSelectedText];
            end
            snippets = snippets0( sel );
        else
            snippets = snippets0;
        end
                
        % --- Test the word at the caret position for an exact match with some 
        % --- snippet prefix.
        wordAtCaretPosition = getWordAtCaretPosition();
        [isPerfectMatch, hasTabstops, noMatch] = ...
            checkForPerfectPrefixMatch(wordAtCaretPosition);
        if isPerfectMatch && ~hasTabstops
            % --- Perfect prefix match for a snippet without tabstops
            parsedSnippetText = parsedSnippet.toChar();
            insertToEditor(parsedSnippetText,true);
            return
        end
        if noMatch
            % --- Try again partial match 
            list = {snippets.prefix};        
            ind = filterList(wordAtCaretPosition,list,opt.filterMode);        
            if isempty(ind)
                % --- Do not filter by word at the caret if there is no match with snippet prefixes
                filterByWordAtCaretPosition = false;
            end
        end
        
        % --- Initialize the snippet filter
        if filterByWordAtCaretPosition
            h.EditBox.String = wordAtCaretPosition;
        else
            h.EditBox.String = '';
        end
        h.EditBox.Value = 1;

        % --- Focus the edit box (it will also select the edit box text)
        uicontrol(h.EditBox); % it will also make the hidden window visible
        % --- Disable the edit box text selection so that the user can
        % --- continue to type the snippet prefix
        h.jEditBox = findjobj_fast(h.Fig,'Snippet filter');
        h.jEditBox.SelectionEnd   = h.jEditBox.CaretPosition;
        h.jEditBox.SelectionStart = h.jEditBox.CaretPosition;        
        
        % --- Update the list box and the code pane
        updateListBox();
        updateCodePane();
        
        lastValidText = [];
        current = struct();
        parsedSnippet = [];        
        
        if isPerfectMatch
            % --- Select the perfectly matched snippet in the list
            list = h.ListBox.UserData;
            ilist = find(strcmp(list,wordAtCaretPosition),1);
            if ~isempty(ilist)
                h.ListBox.Value = ilist(1);
            end
            % --- Perfect match for a snippet with tabstops - switch focus to the code pane
            requestFocus(h.jhCodePane);
        end
    
    end


% ==============================================================================        


    function askToAddToFavorites()
        if opt.askToAddToFavorites            
            answer = questdlg('Do you want to create a shortcut on the Quick Access Toolbar so you can insert snippets by using the keyboard shortcut ALT+1? The app will be more or less useless without a keyboard shortcut.', ...
                'Matlab Snippets', ...
                'Yes','No','Yes');
            if strcmp(answer,'Yes')            
                addToFavorites();
            end
            % --- Do not ask again
            opt.askToAddToFavorites = false;
            % --- Save options
            filePath = fileparts(mfilename('fullpath'));
            fullFileName = [ filePath filesep optionsFileName ];
            save(fullFileName,'opt');
        end
    end


% ==============================================================================        


    function figureKeyPressFcn(~,keyData)
        switch keyData.Key
            case 'escape'
                close(h.Fig);
                return
        end
    end
                       
        
% ==============================================================================


    function editBoxKeyPressFcn(~,keyData)
        switch keyData.Key
            case 'escape'
                close(h.Fig);
                return
            case 'uparrow'
                h.ListBox.Value = max( h.ListBox.Value-1, 1 );
            case 'downarrow'
                h.ListBox.Value = min( h.ListBox.Value+1, length(h.ListBox.String) );
            case 'pageup'
                if isempty(keyData.Modifier)
                    nSkip = pageUpDownSkipSize();
                    h.ListBox.Value = max( h.ListBox.Value-nSkip, 1 );
                elseif all(strcmp(keyData.Modifier,'control'))
                    h.ListBox.Value = 1;
                end
            case 'pagedown'
                if isempty(keyData.Modifier)
                    nSkip = pageUpDownSkipSize();
                    h.ListBox.Value = min( h.ListBox.Value+nSkip, length(h.ListBox.String) );
                elseif all(strcmp(keyData.Modifier,'control'))
                    h.ListBox.Value = length(h.ListBox.String);
                end
            case 'return'
                iSnippet = getSelectedSnippetIndex();
                if ~isempty(iSnippet)
                    parsedSnippet = Snippet.Snippet( snippets(iSnippet).body );                    
                    parsedSnippetText = parsedSnippet.toChar();
                    insertToEditor(parsedSnippetText);
                    close(h.Fig);
                    return
                end
            otherwise
                updateListBox();
        end        
        updateCodePane();
        
        function nSkip = pageUpDownSkipSize()
            itemSizePx = 1.3*h.ListBox.FontSize/72*96+2; % +/-
            nSkip = round(h.ListBox.Position(4) / itemSizePx);
        end
    end


% ==============================================================================


    function updateListBox()
        % Updates a list of snippets in the list box according to the filter.
        %
        filter = h.jEditBox.Text; % h.EditBox.String is not updated until <ENTER>
        list   = {snippets.prefix};        
        description = {snippets.description};
        
        lastItem = '';
        if ~isempty(h.ListBox.UserData)
            lastItem = h.ListBox.UserData{h.ListBox.Value};
        end
        
        [ind,pattern] = filterList(filter,list,opt.filterMode);        
        filteredList = list(ind);
        filteredDescription = description(ind);
        
        if isempty(ind)
            h.ListBox.Value = 1;
            h.ListBox.String = {'<html><i>&lt;no match&gt;</i></html>'};  
            h.ListBox.UserData = {};
        else        
            listBoxValue = 1;
            % --- try to keep the last item selected
            ilastItem = find(strcmp(filteredList,lastItem));
            if ~isempty(ilastItem)
                listBoxValue = ilastItem;
            end
            % --- Emphasize characters matched by the filter
            switch 3
                case 1
                    prefix  = '<b>';
                    postfix = '</b>';
                case 2
                    prefix  = '<font color="rgb(255,255,0)"><b>';
                    postfix = '</b></font>';
                case 3
                    prefix  = '<font color="rgb(0,200,0)"><b>';
                    postfix = '</b></font>';
            end
            filteredListTokens = ...
                regexpi(filteredList,['(.*?)(' pattern ')(.*)'],'tokens');
            filteredListHTML = cellfun( ...
                @(c1,c2) ...
                ['<html>' c1{1}{1} prefix c1{1}{2} postfix c1{1}{3} ...
                ' <font color="rgb(135,135,135)"><i>(' c2 ')</font></i>' ...
                '</html>'], ...
                filteredListTokens, ...
                filteredDescription, ...
                'UniformOutput',false);
            % ---           
            h.ListBox.String = filteredListHTML;
            h.ListBox.UserData = filteredList;            
            if ~isempty(h.ListBox.String)
                h.ListBox.Value = listBoxValue;
            end
        end                       
    end


% ==============================================================================


    function updateCodePane()
        % --- Previewes the currently selected snippet in the code pane
        iSnippet = getSelectedSnippetIndex();
        codePaneText = '';
        if ~isempty(iSnippet)
            switch opt.previewMode
                case 'RAW'                   
                    codePaneText = snippets(iSnippet).body;
                case {'PARSED','EMPHASIZE_PLACEHOLDERS'}                                        
                    parsedSnippet = Snippet.Snippet( snippets(iSnippet).body );
                    % --- Emphasize editable tabstops
                    if strcmp(opt.previewMode,'EMPHASIZE_PLACEHOLDERS')
                        tabstopNumbers = parsedSnippet.getTabstopNumbers();
                        for tabstopNumber = tabstopNumbers(:)'
                            if tabstopNumber==0
                                continue
                            end
                            tabstop = parsedSnippet.getTabstopObject(tabstopNumber);
                            if isprop(tabstop,'value') && ~isa(tabstop,'Snippet.Element.Regexp')
                                if ~ischar(tabstop.value)
                                    tabstop.value = Snippet.Element.Array( { ...
                                        Snippet.Element.Text('`') ...
                                        tabstop.value ...
                                        Snippet.Element.Text('´') ...
                                        });
                                elseif ischar(tabstop.value)
                                    tabstop.value = ['`' tabstop.value '´'];
                                end
                            end
                        end
                    end
                    % ---
                    codePaneText = parsedSnippet.toChar();
                otherwise
                    error(['Unkown snippet preview mode "' opt.previewMode '".']);
            end
        end
        h.CodePane.setText(codePaneText);
    end


% ==============================================================================


    function iSnippet = getSelectedSnippetIndex()
        % Returns the index of the currently selected snippet.
        % Outputs:
        %   iSnippet ... currently selected snippet as an index in the 
        %                "snippets" array
        %
        iSnippet = [];
        if ~isempty(h.ListBox.UserData)
            snippetPrefix = h.ListBox.UserData{h.ListBox.Value};
            iSnippet = find(strcmp(snippetPrefix,{snippets.prefix}));
            if isempty(iSnippet)
                error(['Cannot find snippet with prefix "' sbuooetPrefix '".']);
            end
            if length(iSnippet)>1
                warning(['There are multiple snippets with the same prefix "' snippetPrefix '".']);
                iSnippet = iSnippet(1);
            end            
        end
    end


% ==============================================================================


    function listBoxCallback(~,~)
        uicontrol(h.EditBox);
        updateHint('EditBox');
        updateCodePane();        
    end


% ==============================================================================


    function codePaneFocusGainedCallback(~,~)
        % Code pane focus callback - starts snippet tabstop editing mode
        iSnippet = getSelectedSnippetIndex();        
        if ~isempty(iSnippet)
            parsedSnippet = Snippet.Snippet( snippets(iSnippet).body );
            
            parsedSnippetText = parsedSnippet.toChar();
            parsedSnippetTabstopNumbers = parsedSnippet.getTabstopNumbers();

            if isempty(parsedSnippetTabstopNumbers) || isequal(parsedSnippetTabstopNumbers,0)
                % --- snippet without tabstops
                insertToEditor( parsedSnippetText );
                close(h.Fig);
                return
            end
            
            tabstopNumbers = parsedSnippetTabstopNumbers( parsedSnippetTabstopNumbers>0 );
            tabstopNumber = tabstopNumbers(1);            
            
            tabstopObject = parsedSnippet.getTabstopObject(tabstopNumber);
            tabstopObjectClass = class(tabstopObject);
                       
            h.CodePane.setText( parsedSnippetText );
            lastValidText = parsedSnippetText;            
            
            [iStart,iEnd] = parsedSnippet.getPlaceholderPosition(tabstopNumber);
            
            h.CodePane.setSelectionStart( iStart(1)-1 );
            h.CodePane.setSelectionEnd( iEnd(1) );
            
            current.tabstopNumber = tabstopNumber;
            current.tabstopObject = tabstopObject;
            current.tabstopObjectClass = tabstopObjectClass;
            current.prefix  = parsedSnippetText( 1 : iStart(1)-1 );
            current.postfix = parsedSnippetText( iEnd(1)+1 : end );
            current.lastValidCaretPosition = h.CodePane.getCaretPosition;            
            current.parameterValue = parsedSnippet.getPlaceholder(tabstopNumber);
            
            updateHint('CodePane');
            
        else
            % --- no snippet selected - return focus to the edit box
            uicontrol(h.EditBox);
        end
    end


% ==============================================================================


    function codePaneKeyPressedCallback(~,keyData)                
        % Code pane key typed callback for all keys
        if isstruct(current) && isfield(current,'tabstopObjectClass') ...
                && strcmp(current.tabstopObjectClass,'Snippet.Element.TabstopMultiChoice')
            choice = [];
            switch char(keyData.getKeyText(keyData.getKeyCode))
                case 'Up'
                    choice = current.tabstopObject.getPreviousChoice();
                case 'Down'
                    choice = current.tabstopObject.getNextChoice();
            end           
            if ~isempty(choice)
                tabstopNumber = current.tabstopNumber;
                parsedSnippet.setPlaceholder(tabstopNumber,choice);
                
                parsedSnippetText = parsedSnippet.toChar();
                h.CodePane.setText( parsedSnippetText );
                lastValidText = parsedSnippetText;
                
                [iStart,iEnd] = parsedSnippet.getPlaceholderPosition(tabstopNumber);
                h.CodePane.setSelectionStart( iStart(1)-1 );
                h.CodePane.setSelectionEnd( iEnd(1) );
                
                current.prefix  = parsedSnippetText( 1 : iStart(1)-1 );
                current.postfix = parsedSnippetText( iEnd(1)+1 : end );
                current.lastValidCaretPosition = h.CodePane.getCaretPosition;
                current.parameterValue = parsedSnippet.getPlaceholder(tabstopNumber);
            end
        end    
    end


% ==============================================================================


    function codePaneKeyTypedCallback(~,keyData)
        % Code pane key typed callback for printable characters
        
        switch double(keyData.getKeyChar)
            
            case  9 % TAB
                h.CodePane.setText(lastValidText); % undo tab key action in the editor

                parsedSnippetText = parsedSnippet.toChar();
                tabstopNumbers = parsedSnippet.getTabstopNumbers();                
                
                % --- Select next tabstop number
                keyModifiers = char( keyData.getKeyModifiersText(keyData.getModifiers) );                                
                if isempty(keyModifiers)
                    % --- TAB                                        
                    selectedTabstopNumbers = ...
                        tabstopNumbers( tabstopNumbers>current.tabstopNumber );
                    if isempty(selectedTabstopNumbers)
                        insertToEditor(parsedSnippetText);
                        close(h.Fig);
                        return                        
                    else
                        tabstopNumber = selectedTabstopNumbers(1);
                    end                    
                elseif strcmpi(keyModifiers,'Shift')
                    % --- Shift+TAB
                    selectedTabstopNumbers = ...
                        tabstopNumbers( 0<tabstopNumbers & tabstopNumbers<current.tabstopNumber );
                    if isempty(selectedTabstopNumbers)
                        %tabstopNumber = current.tabstopNumber;
                        uicontrol(h.EditBox);                        
                        % --- Disable edit box text selection
                        drawnow;
                        h.jEditBox.SelectionEnd   = h.jEditBox.CaretPosition;
                        h.jEditBox.SelectionStart = h.jEditBox.CaretPosition;
                        % ---
                        updateCodePane();
                        updateHint('EditBox');
                        return
                    else
                        tabstopNumber = selectedTabstopNumbers(end);
                    end                    
                else
                    % --- Unkown key modifier
                    return
                end
                                
                if ~isempty(tabstopNumber)
                    [iStart,iEnd] = parsedSnippet.getPlaceholderPosition(tabstopNumber);
                    
                    tabstopObject = parsedSnippet.getTabstopObject(tabstopNumber);
                    tabstopObjectClass = class(tabstopObject);                    
                    
                    h.CodePane.setSelectionStart(iStart(1)-1);
                    h.CodePane.setSelectionEnd(iEnd(1));                    
                    
                    current.tabstopNumber = tabstopNumber;
                    current.tabstopObject = tabstopObject;
                    current.tabstopObjectClass = tabstopObjectClass;                    
                    current.prefix  = parsedSnippetText( 1 : iStart(1)-1 );
                    current.postfix = parsedSnippetText( iEnd(1)+1 : end );
                    current.lastValidCaretPosition = h.CodePane.getCaretPosition;
                    current.parameterValue = parsedSnippet.getPlaceholder(tabstopNumber);                                                            
                    
                    updateHint('CodePane');
                    return
                    
                end
                
            case 10 % ENTER
                keyModifiers = char( keyData.getKeyModifiersText(keyData.getModifiers) );                                
                if isempty(keyModifiers) 
                    % ENTER without modifiers only (Shift+ENTER can be used to separate lines)
                    h.CodePane.setText(lastValidText); % undo enter key action in the editor
                    parsedSnippetText = parsedSnippet.toChar();
                    insertToEditor(parsedSnippetText);
                    close(h.Fig);
                    return
                end
                
            case 27 % ESCAPE
                close(h.Fig);
                return
                
        end
        
        % --- (!) Disable edit mode for a moment so that a fast type user does not
        % --- change the text while we are mirroring tabstops.
        h.CodePane.setEditable(false); 
        
        % --- 
        text = char( h.CodePane.getText );
        
        % --- Fix: sometimes (?) getText returns char([13 10]) instead of char(10)
        text = strrep(text,char([13 10]),char(10)); %#ok<*CHARTEN>
        current.prefix = strrep(current.prefix,char([13 10]),char(10));
        current.postfix = strrep(current.postfix,char([13 10]),char(10));
        
        % --- Check user input validity        
        parameterLength = ...
            length(text) - ( length(current.prefix) + length(current.postfix) );
        isValid = startsWith_(text,current.prefix) ...
            && endsWith_(text,current.postfix) ...
            && parameterLength>=0;
        
        if strcmp(current.tabstopObjectClass,'Snippet.Element.TabstopMultiChoice')
            isValid = false;
        end                
        if isValid
            % --- Update parameter(s)
            parameterValue = text( ...
                length(current.prefix)+1 ...
                : ...
                length(text)-length(current.postfix) );
            parsedSnippet.setPlaceholder(current.tabstopNumber,parameterValue);
            %if length(parsedSnippet.getPlaceholderPosition(current.tabstopNumber))>1
            if parsedSnippet.isMirrored(current.tabstopNumber)
                % --- Update text for multiple tabstops with the same number
                parsedSnippetText = parsedSnippet.toChar();
                caretPosition = h.CodePane.getCaretPosition;                                
                h.CodePane.setText(parsedSnippetText); 
                % ---
                [iStart,iEnd] = parsedSnippet.getPlaceholderPosition(current.tabstopNumber);
                caretPosition = caretPosition + (iStart(1)-1) - length(current.prefix); % compensate prefix length change
                current.prefix  = parsedSnippetText( 1 : iStart(1)-1 );
                current.postfix = parsedSnippetText( iEnd(1)+1 : end );                
                % ---
                h.CodePane.setCaretPosition(caretPosition);                
            end
            % ---
             current.parameterValue = parameterValue;
        else
            % --- Return to the previous valid input
            h.CodePane.setText(lastValidText);
            h.CodePane.setCaretPosition(current.lastValidCaretPosition);
        end
        if strcmp(current.tabstopObjectClass,'Snippet.Element.TabstopMultiChoice')
            [iStart,iEnd] = parsedSnippet.getPlaceholderPosition(current.tabstopNumber);
            h.CodePane.setSelectionStart( iStart(1)-1 );
            h.CodePane.setSelectionEnd( iEnd(1) );
        end
        % --- (!) Enable the edit mode
        h.CodePane.setEditable(true);
        % --- 
        lastValidText = h.CodePane.getText;
        current.lastValidCaretPosition = h.CodePane.getCaretPosition;
        % ---
        updateHint('CodePane');
    end


% ==============================================================================

    
    function updateHint(currentFocus)
        switch currentFocus
            case 'EditBox'
                h.Hint.String = 'Start typing to filter snippets, <UP/DOWN> select a snippet, <TAB> edit snippet tabstops, <ENTER> insert to the editor.';
            case 'CodePane'
                tabstopNumbers = parsedSnippet.getTabstopNumbers();
                tabstopNumbers = tabstopNumbers( tabstopNumbers>0 );
                tabstopNumber = current.tabstopNumber;
                switch current.tabstopObjectClass
                    case 'Snippet.Element.TabstopMultiChoice'
                        str = '<UP/DOWN> select placeholder choice';
                    otherwise
                        str = 'Start typing to modify tabstop placeholder';
                end
                if any( tabstopNumbers > tabstopNumber )
                    str = [ str ...
                        ', <TAB> next tabstop' ];
                else
                    str = [ str ...
                        ', <TAB> insert to the editor' ];
                end
                if any( tabstopNumbers < tabstopNumber )
                    str = [ str ...
                        ', <Shift+TAB> previous tabstop' ];
                else
                    str = [ str ...
                        ', <Shift+TAB> snippet selection' ];
                end
                str = [ str ...
                    ', <ENTER> insert to the editor' ];
                h.Hint.String = [ str '.' ];
        end
    end


% ==============================================================================


    function [isPerfectMatch,hasTabstops,noMatch] = checkForPerfectPrefixMatch(prefix)
        isPerfectMatch = false;
        hasTabstops = true;
        noMatch = false;
        % --- Test perfect match
        prefixes = {snippets.prefix};
        ind = find(strcmp(prefixes,prefix));
        if length(ind)==1
            isPerfectMatch = true;
            % ---
            parsedSnippet = Snippet.Snippet( snippets(ind).body );
            tabstopNumbers = parsedSnippet.getTabstopNumbers();
            if isempty( tabstopNumbers(tabstopNumbers>0) )
                hasTabstops = false;                
            end
        end
        % --- Test that at least the first character matches some snippet
        ind = find(strncmp(prefixes,prefix,1),1);
        if isempty(ind)
            noMatch = true;
        end
    end


% ==============================================================================


    function insertToEditor(text,alwaysDeleteWordAtCaret)
        if isa(text,'java.lang.String')
            text = char(text);
        end
        if nargin<2
            alwaysDeleteWordAtCaret = false;
        end        
        % --- Indentation string
        if isTextSelected
            % --- Do not add extra indentation if text is selected (needed for
            % --- alignment commands)
            indentationStr = '';
        else
            % --- Use indentation from the line at caret position
            lineAtCaret = getLineAtCaretPosition();
            tokens = regexp(lineAtCaret,'^([ ]*)','tokens','once');
            if isempty(tokens)
                indentationStr = '';
            else
                indentationStr = tokens{1};
            end
        end
        % --- Indent all lines except the first one
        indNewLine = regexp(text,'\n');
        text = regexprep(text,'\n',['$0' indentationStr]);
        
        if canDeleteWordAtCaret
            if alwaysDeleteWordAtCaret
                clearWordAtCaretPosion();
            else
                % --- Delete word at caret position only if it matches with the
                % --- begining of the selected snippet prefix and if this function
                % --- is enabled
                if opt.deletePartiallyMatchingWordAtCaret
                    iSnippet = getSelectedSnippetIndex();
                    if ~isempty(iSnippet)
                        snippetFrefix = snippets(iSnippet).prefix;
                        if startsWith_(snippetFrefix,wordAtCaretPosition)
                            clearWordAtCaretPosion();
                        end
                    end
                end
            end
        end
        
        
        activeEditor = getActiveEditor();
        if ~isempty(activeEditor)
            
            % --- Get tabstop $0 position
            caretPosition = activeEditor.JavaEditor.getCaretPosition;
            indCaret = parsedSnippet.getPlaceholderPosition(0);
            if ~isempty(indCaret)
                indCaret = indCaret(1);
                % --- Shift caret postion by additional indentation
                indCaret = indCaret + sum(indNewLine<indCaret) * length(indentationStr);
            end
            
            % --- Insert text to the editor
            activeEditor.JavaEditor.insertTextAtCaret(text);
            
            % --- Move the caret to the $0 tabstop
            if ~isempty(indCaret)
                activeEditor.JavaEditor.setCaretPosition( caretPosition + indCaret - 1 );
            end
            
        end
    end


% ==============================================================================


    function buttonConfigCallback(~,~)
        opt_ = opt;       
        [opt,closeRequest] = insertSnippetOptionsDlg(opt);
        if ~isequal(opt,opt_)
            % --- Save options
            filePath = fileparts(mfilename('fullpath'));
            fullFileName = [ filePath filesep optionsFileName ];
            save(fullFileName,'opt');
            % --- Load snippets
            [snippets0, fileModifiedDate] = ...
                Snippet.Snippet.load( opt.jsonFileNames(opt.isJsonFileEnabled) );
            % --- Re-initialize GUI
            initializeGUI();
        end
        if closeRequest
            close(h.Fig);
        end
    end


% ==============================================================================


    function buttonAboutCallback(~,~)
        insertSnippetAboutDlg(versionStr);
    end


% ==============================================================================


    function buttonHelpCallback(~,~)
        web('matlabSnippets.html');
    end


% ==============================================================================


    function showWindow
        % --- Load snippets definition file if modified
        fileModifiedDate_ = {};
        for ifile = 1 : length(opt.jsonFileNames)
            if opt.isJsonFileEnabled(ifile)
                jsonFileName = opt.jsonFileNames{ifile};
                listing = dir( which(jsonFileName) );
                fileModifiedDate_{ifile} = listing.date;
            end
        end
        if ~isequal(fileModifiedDate,fileModifiedDate_)
            [snippets0, fileModifiedDate] = ...
                Snippet.Snippet.load( opt.jsonFileNames(opt.isJsonFileEnabled) );
        end
        % --- Initialize GUI
        initializeGUI;
    end


end


% ==============================================================================


function [ind,pattern] = filterList(filter,list,filterMode)
% FILTERLIST returns indexes of items in the list that have the best match with
% the filter. First tries to matches the complete pattern, then pattern(1:end-1)
% and so on until some match is achieved.
%
% Inputs:
%   filter ....... filter (character vector)
%   list ......... list (a cell array of character vectors)
%   filterMode ... switches filter matching mode:
%                  'MATCH_START' - matches leading characters only
%                  'MATCH_ANYWHERE' - matches anywhere
% Outputs:
%   ind .......... indexes of items with the best match
%   pattern ...... the best match pattern
%
pattern = [];
if isempty(list)
    ind = [];
elseif isempty(filter)
    ind = 1 : length(list);
else
    % --- Case insensitive
    filter = lower(filter);
    list   = lower(list);
    % ---
    ind = [];
    for n = length(filter):-1:1
        % --- try to match filter(1:n)
        switch filterMode
            case 'MATCH_START'
                res = strncmp(filter,list,n);
            case 'MATCH_ANYWHERE'
                res = strfind(list,filter(1:n),'ForceCellOutput',true);
                res = cellfun(@(c)~isempty(c),res);                
            otherwise
                error(['Uknown search mode "' filterMode '".']);
        end
        % --- return the longest match
        if any(res)
            ind = find(res);
            pattern = filter(1:n);
            return
        end        
    end
end
end


% ==============================================================================


function opt = loadOptions(fileName)
% LOADOPTIONS loads a structure with options from a MAT file.
% Returns the default options if anything fails.
% Inputs:
%   fileName ... MAT file name containing the structure opt with options
% Outputs:
%   opt ... structure with options
%
opt_default = struct( ...
    'jsonFileNames', {{ ...
    'matlab-basic.json',...
    'matlab-custom.json',...
    'matlab-miscellaneous.json',...
    'matlab-plot.json',...
    'matlab-separators.json',...
    'matlab-textformatting.json',...
    'matlab-uicontrol.json',...
    'matlab-variables.json'}}, ...
    'isJsonFileEnabled', [true(1,7) false], ...
    'filterSnippetsIfTextSelected', true, ...
    'keepWindowLoaded', true, ...
    'deletePartiallyMatchingWordAtCaret' , true, ...
    'figureSize', [ 900 420 ], ...
    'askToAddToFavorites', true, ...
    'filterMode', 'MATCH_ANYWHERE', ... {'MATCH_START','MATCH_ANYWHERE'}
    'previewMode', 'EMPHASIZE_PLACEHOLDERS' ... {'RAW','PARSED','EMPHASIZE_PLACEHOLDERS'}
    );
opt = [];
% --- Try to load options from the MAT file
filePath = fileparts(mfilename('fullpath'));
fullFileName = [ filePath filesep fileName ];
try
    S = load(fullFileName);
    opt = S.opt;
catch ME
    switch ME.identifier
        case 'MATLAB:load:couldNotReadFile'
            warning(['Cannot find MAT file "' fileName '" with options. Using default options.']);
        case 'MATLAB:nonExistentField'
            warning(['Options MAT file "' fileName '" is invalid. Using default options.']);
        otherwise
            rethrow(ME);
    end
end
% ---
if ~isempty(opt)
    % --- Are there all expected options?
    optDiff = setdiff( fieldnames(opt_default), fieldnames(opt));
    if ~isempty(optDiff)
        warning(['Options MAT file does not contain expected option(s): ' strjoin(optDiff,',') '.']);
        opt = [];
    end
end
% --- Use default options if anything was wrong
if isempty(opt)
    opt = opt_default;
end
end

    
% ==============================================================================    


function isShown = showHiddenWindow(windowTag)
% Search for the hidden App window and show it if it exists.
%
% Outputs:
%   isShown ... windows was found ans shown (logical)
%
isShown = false;
hFig = findobj('Type','figure','Tag',windowTag);
if ~isempty(hFig)
    %delete(hFig); return; % uncomment to delete the hidden window and create a new one
    ud = get(hFig,'Userdata');
    if isfield(ud,'showWindowFH') && isa(ud.showWindowFH,'function_handle')
        ud.showWindowFH();
        isShown = true;
    end
end
end


% ==============================================================================


function TF = startsWith_(str,pattern)
if verLessThan('matlab','9.1') % R2016b
    % Basic functionality of startsWith
    TF = strncmp(str,pattern,length(pattern));
else
    TF = startsWith(str,pattern);
end
end


% ==============================================================================


function TF = endsWith_(str,pattern)
if verLessThan('matlab','9.1') % R2016b
    % Basic functionality of endsWith
    if length(str)>=length(pattern)
        TF = strncmp( ...
            str(length(str)-length(pattern)+1:end),...
            pattern,length(pattern));
    else
        TF = false;
    end
else
    TF = endsWith(str,pattern);
end
end


% ==============================================================================


function img = replaceWhiteColor(img,thr,replacementCol)
% Replaces RGB image light background by a slected color
for i = 1 : size(img,1)
    for j = 1 : size(img,2)
        if all(squeeze(img(i,j,:))>=thr*ones(3,1))
            img(i,j,:) = replacementCol;
        end
    end
end
end