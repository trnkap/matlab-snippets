function addToFavorites
% Add "insertSnippet();" to the favorites commands and adds it to the Quick
% Access Toolbar so it can be triggered by a keyboard shortcut (e.g. ALT+1)

if verLessThan('matlab','9.3')
    f = warndlg('The quick lunch icon can be automatically added only in Matlab 2017b and later. Please add it manually with a callback "insertSnippet();".');
    uiwait(f);
    return
end

basePath = fileparts(which('insertSnippet.m'));
iconPath = [ basePath filesep 'graphics' filesep ];
iconFileName = 'insertSnippet_16.png';

try
    fc = com.mathworks.mlwidgets.favoritecommands.FavoriteCommands.getInstance();
    
    newFavoriteCommand = com.mathworks.mlwidgets.favoritecommands.FavoriteCommandProperties();
    newFavoriteCommand.setLabel('Insert Snippet');
    newFavoriteCommand.setCategoryLabel('MATLAB SNIPPETS');
    newFavoriteCommand.setCode('insertSnippet();');
    newFavoriteCommand.setIsOnQuickToolBar(true);
    newFavoriteCommand.setIconName(iconFileName);
    newFavoriteCommand.setIconPath(iconPath);
    fc.addCommand(newFavoriteCommand);
    %msgbox('Quick lunch icon successfully added. Try to trigger it by ALT+1.','Matlab Snippets');
catch
    f = warndlg('Adding Quick lunch icon failed. Please add it manually with a callback "insertSnippet();".');
    uiwait(f);
end
end