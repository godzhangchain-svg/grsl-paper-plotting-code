function T = input_audit(paths)
% Record path, size, and modification time for reproducibility logs.
paths = string(paths(:));
bytes = zeros(numel(paths), 1);
modified = strings(numel(paths), 1);
for i = 1:numel(paths)
    d = dir(paths(i));
    bytes(i) = d.bytes;
    modified(i) = string(d.date);
end
T = table(paths, bytes, modified, ...
    'VariableNames', {'Path', 'Bytes', 'Modified'});
end
