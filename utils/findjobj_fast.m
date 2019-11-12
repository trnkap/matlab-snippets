function jComponent = findjobj_fast(hFig,toolTipText)
% Based on Yair Altman "findjobj"
drawnow;  pause(0.02);
oldWarn = warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');                                
warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');
jframe = get(hFig,'JavaFrame');
warning(oldWarn);
jContainer = jframe.getFigurePanelContainer.getComponent(0);
jComponent = findComponent(jContainer,toolTipText);

    function jComponent = findComponent(jContainer,toolTipText)
        jComponent = [];
        containerToolTipText = '';
        try
            containerToolTipText = get(jContainer,'ToolTipText');
        catch
        end
        if strcmp(containerToolTipText,toolTipText)
            jComponent = handle(jContainer,'callbackproperties');
        else
            for i = 1 : jContainer.getComponentCount
                jComponent = findComponent(jContainer.getComponent(i-1),toolTipText);
                if ~isempty(jComponent)
                    return
                end
            end
        end
    end
end