function tokens = decomposeRegexpPlaceholder(placeholder)
indSlash = find(placeholder=='/');
% --- Indicate slashes that are enclosed in the { } brackets
isEnclosed = false(size(indSlash));
for i = 1 : length(indSlash)
    nLeftOpeningBrackets  = sum( placeholder(1:indSlash(i)-1) == '{' );
    nLeftClosingBrackets  = sum( placeholder(1:indSlash(i)-1) == '}' );
    isEnclosed(i) = (nLeftOpeningBrackets~=nLeftClosingBrackets);
end
% --- Select non-enclosed slashes only
indSlash = indSlash(~isEnclosed);
% --- Split to tokens
tokens = {};
i1 = 1;
for i = 1 : length(indSlash)
    i2 = indSlash(i)-1;
    tokens{end+1} = placeholder(i1:i2);
    i1 = indSlash(i)+1;
end
i2 = length(placeholder);
tokens{end+1} = placeholder(i1:i2);
end