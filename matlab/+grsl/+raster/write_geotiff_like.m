function write_geotiff_like(path, data, R, info)
% Preserve GeoTIFF keys when available.
try
    geotiffwrite(path, data, R, 'GeoKeyDirectoryTag', ...
        info.GeoTIFFTags.GeoKeyDirectoryTag);
catch
    geotiffwrite(path, data, R);
end
end
