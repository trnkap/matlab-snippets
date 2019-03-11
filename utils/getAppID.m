function id = getAppID(appName)
% GETAPPID returns Matlab App ID from its name.
%
% Inputs:
%   appName ... App name (character vector)
%
% Outputs:
%   id ........ unique App ID (character vector)
%
id = [];
appinfo = matlab.apputil.getInstalledAppInfo;
if ~isempty(appinfo)
    ind = find(strcmp({appinfo.name},appName));
    if length(ind)==1
        id = appinfo(ind).id;
    else
        % --- multiple matches - return the last ID from a sorted list
        ID = {appinfo(ind).id};
        ID = sort(ID);
        id = ID(end);
    end
end

