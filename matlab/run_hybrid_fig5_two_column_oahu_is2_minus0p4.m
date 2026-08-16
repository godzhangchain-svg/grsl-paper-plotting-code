%% Fig. 5 (corrected independent version): Oahu ICESat-2 shifted downward
% This script is a NEW, standalone Fig. 5 variant. It does not read, modify,
% or overwrite either reference-shift version or any of their outputs.
%
% Layout: 2 x 2 only.
%   Row 1 = Wanning, Row 2 = Oahu.
%   Column 1 = direct ICESat-2 versus independent-reference scatter.
%   Column 2 = residual versus independent-reference depth.
%   The former right-hand 2 m bins panels remain omitted; the binned
%   statistics are still exported to CSV.
%
% Site conventions:
%   Wanning uses the previously accepted raw pair file
%   tmp/grsl_optical_boundary/wanning_is2_reference_pairs.csv with its
%   ORIGINAL MBES -6.6 m water-surface reference datum (N = 133, 2 tracks).
%   The newer +0.5 m datum alignment is deliberately NOT applied here.
%
%   Oahu uses the original accepted pairs in
%   tmp/oahu_blue_line_audit/oahu_is2_alb_pairs_col7.csv. The independent
%   ALB reference depths remain unchanged, while every ICESat-2 depth is
%   shifted by -0.4 m. Therefore every Oahu residual and every 2 m-bin Bias
%   is the original accepted value minus 0.4 m, with unchanged x positions
%   and bin memberships.
%
% No spatial rematching, model fitting, SDB inference, or filtering occurs.
% Image outputs are PNG and MATLAB FIG only.

clear; clc; close all;
set(groot,'defaultFigureVisible','off');

projectRoot = 'C:\Users\Administrator\Documents\New project';
root = fullfile(projectRoot,'experiments','grsl_reviewer_20260810');
outDir = fullfile(root,'output','hybrid_fig3_fig4_oahu_weighted_internal');
if ~exist(outDir,'dir'), mkdir(outDir); end

wanningSource = fullfile(projectRoot,'tmp','grsl_optical_boundary', ...
    'wanning_is2_reference_pairs.csv');
oahuSource = fullfile(projectRoot,'tmp','oahu_blue_line_audit', ...
    'oahu_is2_alb_pairs_col7.csv');
assert(isfile(wanningSource),'Wanning raw pair file is missing: %s',wanningSource);
assert(isfile(oahuSource),'Oahu col7 pair file is missing: %s',oahuSource);

stem = 'fig5_two_column_oahu_is2_minus0p4';
oahuIs2Shift_m = -0.4;

W = readtable(wanningSource,'TextType','string');
O = readtable(oahuSource,'TextType','string');
required = {'track','pixel','is2_depth','reference_depth'};
assert(all(ismember(required,W.Properties.VariableNames)), ...
    'Wanning raw pair schema mismatch.');
assert(all(ismember(required,O.Properties.VariableNames)), ...
    'Oahu col7 pair schema mismatch.');

% --- Wanning: accepted pairs on the original -6.6 m MBES datum -----------
W.reference_depth_raw_minus6p6_m = W.reference_depth;
W.reference_depth = W.reference_depth_raw_minus6p6_m;   % no datum alignment
W.residual = W.is2_depth - W.reference_depth;
W.reference_water_surface_m = repmat(-6.6,height(W),1);
W.reference_shift_applied_m = zeros(height(W),1);

% --- Oahu: ALB unchanged; ICESat-2 shifted downward by 0.4 m ------------
O.reference_depth_original_m = O.reference_depth;
O.is2_depth_original_m = O.is2_depth;
O.residual_original_m = O.is2_depth_original_m - O.reference_depth_original_m;
O.reference_depth = O.reference_depth_original_m;
O.is2_depth = O.is2_depth_original_m + oahuIs2Shift_m;
O.residual = O.is2_depth - O.reference_depth;
O.is2_shift_applied_m = repmat(oahuIs2Shift_m,height(O),1);
O.reference_shift_applied_m = zeros(height(O),1);

% --- Identity and transformation guards ---------------------------------
assert(height(W)==133 && numel(unique(W.track))==2, ...
    'Wanning pair identity changed (expected N = 133, 2 tracks).');
assert(max(abs(W.reference_depth - W.reference_depth_raw_minus6p6_m))<1e-12, ...
    'Wanning reference depth must remain on the original -6.6 m datum.');
assert(height(O)==2218 && numel(unique(O.track))==31, ...
    'Oahu pair identity changed (expected N = 2218, 31 tracks).');
assert(max(abs(O.reference_depth - O.reference_depth_original_m))<1e-12, ...
    'Oahu independent ALB reference depths must remain unchanged.');
assert(max(abs((O.is2_depth - O.is2_depth_original_m) - oahuIs2Shift_m))<1e-12, ...
    'Oahu ICESat-2 shift is not the required -0.4 m.');
assert(max(abs(O.residual - (O.residual_original_m + oahuIs2Shift_m)))<1e-12, ...
    'Oahu residuals are not the original residuals minus 0.4 m.');
assert(max(abs(O.residual - (O.is2_depth - O.reference_depth)))<1e-12, ...
    'Oahu residual is not shifted ICESat-2 minus unchanged reference.');

inputs = struct( ...
    'site',{'Wanning','Oahu'}, ...
    'referenceLabel',{'Shipborne MBES','Airborne Lidar Bathymetry'}, ...
    'pairs',{W,O}, ...
    'referenceShift',{0,0}, ...
    'is2Shift',{0,oahuIs2Shift_m}, ...
    'provenance',{ ...
       'Accepted raw 133 spatial pairs / 2 tracks; MBES reference kept on its original -6.6 m water-surface datum (no +0.5 m alignment)', ...
       'Accepted 2218 spatial pairs / 31 tracks; independent ALB reference unchanged and every ICESat-2 depth shifted by -0.4 m'});

edges = (0:2:30)';
metricsRows = cell(2,1);
binRows = cell(2,1);
for i = 1:2
    T = inputs(i).pairs;
    m = overall_metrics(T.reference_depth,T.is2_depth);
    inputs(i).metrics = m;
    metricsRows{i} = table(string(inputs(i).site),height(T),numel(unique(T.track)), ...
        inputs(i).referenceShift,inputs(i).is2Shift,m.Bias_m,m.RMSE_m,m.MAE_m, ...
        m.MedianBias_m,m.P90AbsoluteError_m,m.OLS_R2,m.Predictive_R2, ...
        m.Slope,m.Intercept,string(inputs(i).referenceLabel), ...
        string(inputs(i).provenance), ...
        'VariableNames',{'Site','N','TrackN','ReferenceShift_m','ICESat2Shift_m', ...
        'Bias_m','RMSE_m','MAE_m','MedianBias_m','P90AbsoluteError_m', ...
        'OLS_R2','Predictive_R2','OLS_Slope','OLS_Intercept_m', ...
        'IndependentReference','Provenance'});
    binRows{i} = binned_metrics(T.reference_depth,T.is2_depth, ...
        string(inputs(i).site),edges,5);
end

metricsTable = vertcat(metricsRows{:});
binsTable = vertcat(binRows{:});
writetable(metricsTable,fullfile(outDir,[stem '_overall_metrics.csv']));
writetable(binsTable,fullfile(outDir,[stem '_2m_bins.csv']));
writetable(W,fullfile(outDir,[stem '_pairs_wanning_raw_minus6p6.csv']));
writetable(O,fullfile(outDir,[stem '_pairs_oahu_is2_minus0p4.csv']));

% --- Figure: 2 x 2 only --------------------------------------------------
fig = figure('Color','white','Units','pixels','Position',[40 40 1180 980]);
tl = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
for i = 1:2
    siteBins = binsTable(binsTable.Site==string(inputs(i).site),:);
    plot_site_row(tl,inputs(i),siteBins);
end
title(tl,'Direct comparison of ICESat-2 and independent bathymetric references', ...
    'FontName','Times New Roman','FontSize',16,'FontWeight','bold');
subtitle(tl,'Wanning: MBES on its original -6.6 m datum. Oahu: ICESat-2 depths shifted by -0.4 m.', ...
    'FontName','Times New Roman','FontSize',11);

pngPath = fullfile(outDir,[stem '.png']);
figPath = fullfile(outDir,[stem '.fig']);
savefig(fig,figPath);
exportgraphics_or_print(fig,pngPath);
close(fig);

% --- Notes --------------------------------------------------------------
notesPath = fullfile(outDir,[stem '_notes.txt']);
fid = fopen(notesPath,'w');
assert(fid>=0,'Cannot create Fig. 5 notes file.');
fprintf(fid,'Fig. 5 (corrected independent two-column version).\n');
fprintf(fid,'Layout is 2 x 2 only: row 1 Wanning, row 2 Oahu; column 1 direct-pair scatter, column 2 residuals.\n');
fprintf(fid,'The former right-hand 2 m bins panels are omitted from the figure; binned statistics remain in %s_2m_bins.csv.\n',stem);
fprintf(fid,'Residual and Bias = ICESat-2 depth minus independent-reference depth.\n');
fprintf(fid,'Wanning uses the accepted raw pair file tmp/grsl_optical_boundary/wanning_is2_reference_pairs.csv.\n');
fprintf(fid,'Wanning MBES reference depths stay on their ORIGINAL -6.6 m water-surface datum; the newer +0.5 m alignment is not applied.\n');
fprintf(fid,'Wanning: N = %d, tracks = %d.\n',height(W),numel(unique(W.track)));
fprintf(fid,'Oahu uses the original accepted pairs in tmp/oahu_blue_line_audit/oahu_is2_alb_pairs_col7.csv.\n');
fprintf(fid,'Oahu independent ALB reference depths are unchanged; every ICESat-2 depth was shifted by %+.1f m.\n',oahuIs2Shift_m);
fprintf(fid,'Thus every Oahu residual and every reliable 2 m-bin Bias equals its original accepted value minus 0.4 m.\n');
fprintf(fid,'Oahu residuals, overall metrics and all 2 m bins were recomputed from shifted ICESat-2 and unchanged ALB reference.\n');
fprintf(fid,'Oahu: N = %d, tracks = %d.\n',height(O),numel(unique(O.track)));
fprintf(fid,'No spatial rematching, model fitting, SDB inference, or filtering was applied at either site.\n');
fprintf(fid,'2 m reference-depth bins are lower-closed and upper-open; bins with N < 5 are reported in CSV but not plotted.\n');
fprintf(fid,'Both sites use a 0-30 m reference-depth axis. Summary and bin lines are drawn above the scatter points.\n');
fprintf(fid,'Image outputs are PNG and MATLAB FIG only; no PDF or SVG is produced.\n');
for i = 1:2
    m = inputs(i).metrics; T = inputs(i).pairs;
    fprintf(fid,'%s overall: N = %d, tracks = %d, Bias = %+.4f m, RMSE = %.4f m, MAE = %.4f m, R2 = %.4f.\n', ...
        inputs(i).site,height(T),numel(unique(T.track)),m.Bias_m,m.RMSE_m,m.MAE_m,m.OLS_R2);
end
fclose(fid);

disp(metricsTable);
fprintf('PASS: corrected ICESat-2 -0.4 m two-column Fig. 5 written to %s\n',outDir);

% ======================= helper functions ===============================
function exportgraphics_or_print(fig,pngPath)
try
    exportgraphics(fig,pngPath,'Resolution',600,'BackgroundColor','white');
catch
    print(fig,pngPath,'-dpng','-r600');
end
end

function m = overall_metrics(ref,pred)
v=isfinite(ref)&isfinite(pred); ref=ref(v); pred=pred(v); e=pred-ref;
m.Bias_m=mean(e); m.RMSE_m=sqrt(mean(e.^2)); m.MAE_m=mean(abs(e));
m.MedianBias_m=median(e); m.P90AbsoluteError_m=prctile(abs(e),90);
p=polyfit(ref,pred,1); fitPred=polyval(p,ref);
m.OLS_R2=1-sum((pred-fitPred).^2)/sum((pred-mean(pred)).^2);
m.Predictive_R2=1-sum(e.^2)/sum((ref-mean(ref)).^2);
m.Slope=p(1); m.Intercept=p(2);
end

function T = binned_metrics(ref,pred,site,edges,minN)
n=numel(edges)-1; Site=repmat(site,n,1);
DepthLower_m=edges(1:end-1); DepthUpper_m=edges(2:end);
DepthCenter_m=(DepthLower_m+DepthUpper_m)/2;
N=zeros(n,1); Reliable=false(n,1); Bias_m=nan(n,1); RMSE_m=nan(n,1); MAE_m=nan(n,1);
for b=1:n
    in=isfinite(ref)&isfinite(pred)&ref>=DepthLower_m(b)&ref<DepthUpper_m(b);
    N(b)=sum(in); Reliable(b)=N(b)>=minN;
    if Reliable(b)
        e=pred(in)-ref(in); Bias_m(b)=mean(e);
        RMSE_m(b)=sqrt(mean(e.^2)); MAE_m(b)=mean(abs(e));
    end
end
T=table(Site,DepthLower_m,DepthUpper_m,DepthCenter_m,N,Reliable,Bias_m,RMSE_m,MAE_m);
end

function plot_site_row(tl,input,bins)
T=input.pairs; m=input.metrics; siteName=input.site;
fontName='Times New Roman'; axisLimit=[0 30];
refAxisLabel = 'Independent Reference Depth (m)';

% ---- Column 1: direct-pair scatter ----
ax1=nexttile(tl); hold(ax1,'on'); box(ax1,'on'); grid(ax1,'on');
hPts=scatter(ax1,T.reference_depth,T.is2_depth,14,[0.18 0.48 0.78],'filled', ...
    'MarkerFaceAlpha',0.45,'MarkerEdgeAlpha',0.25,'DisplayName','Matched pairs');
hOne=plot(ax1,axisLimit,axisLimit,'--','Color',[0.25 0.25 0.25],'LineWidth',1.3, ...
    'DisplayName','1:1 line');
uistack(hOne,'top'); uistack(hPts,'bottom');
xlim(ax1,axisLimit); ylim(ax1,axisLimit); axis(ax1,'square');
xlabel(ax1,refAxisLabel); ylabel(ax1,'ICESat-2 Depth (m)');
title(ax1,sprintf('%s: direct pairs',siteName));
annotationText=sprintf(['N = %d; tracks = %d\nBias = %+.3f m\n' ...
    'RMSE = %.3f m; MAE = %.3f m\nR^2 = %.3f'],height(T), ...
    numel(unique(T.track)),m.Bias_m,m.RMSE_m,m.MAE_m,m.OLS_R2);
hTxt=text(ax1,0.04,0.96,annotationText,'Units','normalized','VerticalAlignment','top', ...
    'FontName',fontName,'FontSize',9,'BackgroundColor','white', ...
    'EdgeColor',[0.5 0.5 0.5],'Margin',4);
uistack(hTxt,'top');
legend(ax1,[hPts hOne],{'Matched pairs','1:1 line'}, ...
    'Location','southeast','FontSize',8,'Box','on');

% ---- Column 2: residuals ----
ax2=nexttile(tl); hold(ax2,'on'); box(ax2,'on'); grid(ax2,'on');
hPairs=scatter(ax2,T.reference_depth,T.residual,13,[0.35 0.35 0.35],'filled', ...
    'MarkerFaceAlpha',0.28,'MarkerEdgeAlpha',0.15,'DisplayName','Matched pairs');
hZero=yline(ax2,0,'--','Color',[0.15 0.15 0.15],'LineWidth',1.1, ...
    'DisplayName','Zero residual');
hMean=yline(ax2,m.Bias_m,':','Color',[0.10 0.40 0.78],'LineWidth',1.4, ...
    'DisplayName','Overall Bias');
good=bins.Reliable & isfinite(bins.Bias_m);
hBin=plot(ax2,bins.DepthCenter_m(good),bins.Bias_m(good),'-o', ...
    'Color',[0.85 0.15 0.15],'MarkerFaceColor',[0.85 0.15 0.15], ...
    'LineWidth',1.6,'MarkerSize',4.5,'DisplayName','2 m-bin Bias');
% Summary/bin lines must sit above the scatter cloud.
uistack(hPairs,'bottom'); uistack(hZero,'top'); uistack(hMean,'top'); uistack(hBin,'top');
xlim(ax2,axisLimit);
resSpan=max([abs(T.residual);abs(bins.Bias_m(good));abs(m.Bias_m);0.5],[],'omitnan');
ylim(ax2,[-1.12*resSpan 1.12*resSpan]);
xlabel(ax2,refAxisLabel); ylabel(ax2,'ICESat-2 - Reference (m)');
title(ax2,sprintf('%s: residuals',siteName));
legend(ax2,[hPairs hZero hMean hBin], ...
    {'Matched pairs','Zero residual','Overall Bias','2 m-bin Bias'}, ...
    'Location','southwest','FontSize',8,'Box','on');

set([ax1 ax2],'FontName',fontName,'FontSize',10,'LineWidth',0.9,'Layer','top');
end
