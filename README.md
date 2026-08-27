# GRSL bathymetry reproducibility code

This repository contains the MATLAB source code used to train the site-specific
FCNN models, generate satellite-derived bathymetry, perform internal and
independent validation, and reproduce the revised GRSL figures.

Only source code is tracked. Raw Sentinel-2, ICESat-2, MBES, ALB, model, raster,
table, log, and figure files are intentionally excluded.

## Locked processing constants

- Wanning FCNN optical-depth boundary: `Hmax = 18.78 m`.
- Oahu FCNN optical-depth boundary: `Hmax = 21.10 m`.
- Wanning ICESat-2 training-label water surface: `-7.1 m`.
- Wanning shipborne-reference water surface: `-6.1 m`.
- Bias is `prediction - reference`; negative Bias denotes underestimation.
- Wanning independent validation uses `wncz1.tif` only.

## MATLAB requirements

- Statistics and Machine Learning Toolbox
- Mapping Toolbox
- Image Processing Toolbox

The code retains `geotiffread`, `geotiffinfo`, and `map2pix` where needed to
match the original processing path.

## Data layout

Call `grsl_config(DATA_ROOT, OUTPUT_ROOT)` and edit the returned fields if your
files use a different layout. The default expected layout is:

```text
DATA_ROOT/
  wanning/
    wanning730.tif
    wanning731.tif
    wncz1.tif
    icesat2_mat/*.mat
    icesat2_kml/*.kml
  oahu/
    hawaiipart.tif
    hawaiipart2.tif
    HAWAIIBathy2.tif
    hawaii_laz_bathy.mat
    icesat2_mat/*.mat
    icesat2_kml/*.kml
  direct_pairs/
    wanning_is2_reference_pairs_minus6p6.csv
    oahu_is2_alb_pairs_col7.csv
```

The Wanning direct-pair source is the archived `-6.6 m` table. The Fig. 5
workflow applies the locked `+0.5 m` reference-depth update to obtain the
current `-6.1 m` shipborne datum before calculating residuals and metrics.

## Run order

```matlab
addpath('matlab');
cfg = grsl_config('D:\path\to\grsl_data', 'D:\path\to\grsl_outputs');

run_wanning_fcnn_training(cfg);
run_wanning_fcnn_sdb_validation(cfg);
run_oahu_weighted_fcnn_training(cfg);
run_current_fig3_depth_binned_rmse_bias_2m(cfg);
run_p1_depth_binned_mae_bias(cfg);
plot_fig1_revised_with_independent_validation(cfg);
run_hybrid_fig5_two_column_oahu_is2_minus0p4(cfg);
```

The Wanning training workflow rebuilds the accepted per-track/per-Sentinel-pixel
sample pool directly from the input raster and ICESat-2 MAT files. It does not
depend on an unpublished intermediate model MAT file.

`run_current_fig3_depth_binned_rmse_bias_2m` is the latest two-site 2 m
RMSE/Bias diagnostic. The earlier reviewer-package MAE/Bias entrypoint is kept
for traceability.

## Tests

```matlab
addpath('matlab');
results = runtests('matlab/tests');
assertSuccess(results);
```

The included tests cover deterministic helper behavior without requiring raw
study data. Full end-to-end reproduction requires the external datasets listed
above.
