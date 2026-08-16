% RUN_P1_DEPTH_BINNED_MAE_BIAS
% Build the reviewer-ready 2 m depth-binned MAE/Bias figure from the exact
% source tables corresponding to the currently locked Fig. 3 panels.

clear; clc; close all;
set(groot,'defaultFigureVisible','off');

experimentRoot = fileparts(fileparts(mfilename('fullpath')));
outDir = fullfile(experimentRoot,'output','p1_depth_binned_new_sdb');
logDir = fullfile(experimentRoot,'logs');
if ~exist(outDir,'dir'), mkdir(outDir); end
if ~exist(logDir,'dir'), mkdir(logDir); end
diary(fullfile(logDir,'p1_depth_binned_mae_bias_new_sdb.log'));
diary on;
diaryCleanup = onCleanup(@() diary('off'));

v6TablePath = 'C:\Users\Administrator\.openclaw\workspace\paper_figures_v6_boundaries\depth_binned_metrics_2m.csv';
v5OahuTablePath = 'C:\Users\Administrator\.openclaw\workspace\paper_figures_v5_2\depth_binned_metrics_2m.csv';
wanningFinalPairsPath = 'C:\Users\Administrator\Documents\New project\tmp\wanning_v21\output\validation_predictions_clean10.csv';
boundarySummaryPath = 'C:\Users\Administrator\.openclaw\workspace\paper_figures_v6_boundaries\training_depth_support_summary.csv';

assert(isfile(v6TablePath),'Missing V6 2 m table.');
assert(isfile(v5OahuTablePath),'Missing locked Oahu 2 m table.');
assert(isfile(wanningFinalPairsPath),'Missing final Wanning validation pairs.');
assert(isfile(boundarySummaryPath),'Missing boundary summary.');

Tv6 = readtable(v6TablePath,'TextType','string');
Toahu = readtable(v5OahuTablePath,'TextType','string');
T = [Tv6(Tv6.Site=="Wanning",:); Toahu(Toahu.Site=="Oahu",:)];

% N < 5 is retained as a count-only bin and never interpreted.
unreliable = T.N<5;
metricNames = {'RMSE_m','Bias_m','R2','MAE_m','BiasCI95Low_m','BiasCI95High_m'};
for k = 1:numel(metricNames)
    if ismember(metricNames{k},T.Properties.VariableNames)
        T.(metricNames{k})(unreliable) = NaN;
    end
end
T.Reliable = T.N>=5;

expected = table([1355;9954;5022;166369], ...
    'RowNames',{'Wanning_Self','Wanning_Independent','Oahu_Self','Oahu_Independent'}, ...
    'VariableNames',{'N'});
actual = [sum(T.N(T.Site=="Wanning" & T.Validation=="Self-Validation")); ...
    sum(T.N(T.Site=="Wanning" & T.Validation=="Independent Validation")); ...
    sum(T.N(T.Site=="Oahu" & T.Validation=="Self-Validation")); ...
    sum(T.N(T.Site=="Oahu" & T.Validation=="Independent Validation"))];
assert(isequal(actual,expected.N), ...
    'Panel-matched 2 m totals changed: actual=%s expected=%s', ...
    mat2str(actual'),mat2str(expected.N'));

Tw = readtable(wanningFinalPairsPath);
wP99 = prctile(Tw.ReferenceDepth_m,99);
Tb = readtable(boundarySummaryPath,'TextType','string');
oP99 = Tb.pooled_P99_m(Tb.Site=="Oahu");
assert(isscalar(oP99),'Oahu P99 was not uniquely identified.');

boundaries = table(["Wanning";"Oahu"],[18.78;22.53],[wP99;oP99], ...
    [height(Tw);Tb.pooled_N(Tb.Site=="Oahu")], ...
    ["final v21 clean-10 reference labels";"locked Oahu training-depth pool"], ...
    'VariableNames',{'Site','Hmax_m','Dtrain99_m','TrainingPoolN','P99Source'});

writetable(T,fullfile(outDir,'panel_matched_depth_binned_metrics_2m.csv'));
writetable(boundaries,fullfile(outDir,'panel_matched_boundaries.csv'));

fig = figure('Color','white','Position',[50 40 1120 850]);
tl = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
plot_site_metric(nexttile(tl),T,"Wanning",'MAE_m','MAE (m)',18.78,wP99,true);
plot_site_metric(nexttile(tl),T,"Oahu",'MAE_m','MAE (m)',22.53,oP99,true);
plot_site_metric(nexttile(tl),T,"Wanning",'Bias_m','Bias (m)',18.78,wP99,false);
plot_site_metric(nexttile(tl),T,"Oahu",'Bias_m','Bias (m)',22.53,oP99,false);
title(tl,'Depth-binned internal and independent validation (2 m reference-depth bins)', ...
    'FontName','Times New Roman','FontSize',16,'FontWeight','bold');

stem = fullfile(outDir,'combined_depth_binned_mae_bias_2m_new_sdb');
exportgraphics(fig,[stem '.png'],'Resolution',600);
print(fig,[stem '.svg'],'-dsvg');
exportgraphics(fig,[stem '.pdf'],'ContentType','vector');
savefig(fig,[stem '.fig']);
close(fig);

notesPath = fullfile(outDir,'depth_binned_mae_bias_notes.txt');
fid = fopen(notesPath,'w');
assert(fid>=0,'Cannot open notes file.');
fprintf(fid,'Bins are lower-closed and upper-open 2 m reference-depth bins.\n');
fprintf(fid,'Bias = prediction minus reference. MAE has no sign.\n');
fprintf(fid,'N < 5 bins retain N but have blank metrics and are not interpreted.\n');
fprintf(fid,'Wanning rows come from current V6 (v21 internal plus newly rerun Wanning independent panel using the January SDB).\n');
fprintf(fid,'Oahu rows come from paper_figures_v5_2, matching the locked Oahu Fig. 3 panels.\n');
fprintf(fid,'Wanning Dtrain99 was recomputed from the final 1355 v21 clean-10 labels: %.12f m.\n',wP99);
fprintf(fid,'Oahu Dtrain99 was read from and checked against the locked training-depth pool: %.12f m.\n',oP99);
fclose(fid);

fprintf('Wanning Dtrain99 = %.12f m\n',wP99);
fprintf('Oahu Dtrain99 = %.12f m\n',oP99);
fprintf('Outputs written to %s\n',outDir);

function plot_site_metric(ax,T,site,metricName,yLabel,hmax,p99,isMae)
siteRows = T(T.Site==site,:);
self = siteRows(siteRows.Validation=="Self-Validation",:);
indep = siteRows(siteRows.Validation=="Independent Validation",:);
hold(ax,'on'); box(ax,'on'); grid(ax,'on');

selfGood = self.Reliable & isfinite(self.(metricName));
indGood = indep.Reliable & isfinite(indep.(metricName));
xSelf = (self.DepthLower_m+self.DepthUpper_m)/2;
xInd = (indep.DepthLower_m+indep.DepthUpper_m)/2;
hSelf = plot(ax,xSelf(selfGood),self.(metricName)(selfGood),'-o', ...
    'Color',[0.48 0.20 0.72],'MarkerFaceColor',[0.48 0.20 0.72], ...
    'LineWidth',1.6,'MarkerSize',4);
hInd = plot(ax,xInd(indGood),indep.(metricName)(indGood),'-s', ...
    'Color',[0.08 0.52 0.38],'MarkerFaceColor',[0.08 0.52 0.38], ...
    'LineWidth',1.6,'MarkerSize',4);
hH = xline(ax,hmax,'-','Color',[0 0.45 0.85],'LineWidth',1.8);
hP = xline(ax,p99,'-','Color',[0.85 0.10 0.10],'LineWidth',1.8);
if ~isMae, yline(ax,0,'--','Color',[0.25 0.25 0.25],'LineWidth',1); end

xMax = max([self.DepthUpper_m;indep.DepthUpper_m]);
xlim(ax,[0 xMax]);
xlabel(ax,'Reference Depth (m)');
ylabel(ax,yLabel);
title(ax,sprintf('%s: %s',site,strrep(metricName,'_m','')));
legend(ax,[hSelf hInd hH hP], ...
    {'Internal Validation','Independent Validation','H_{max}','D_{train,99}'}, ...
    'Location','best','FontSize',8);
set(ax,'FontName','Times New Roman','FontSize',10,'LineWidth',0.9);
end
