clear; clc;
results_folder  = 'results';
analysis_folder = 'analysis_results';

if ~exist(analysis_folder,'dir')
    mkdir(analysis_folder);
end

files = dir(fullfile(results_folder,'*.mat'));

Rload = 20;      

metrics = {};   

for k = 1:length(files)

    load(fullfile(results_folder,files(k).name)); 

    time = double(result.time(:));
    Vpv  = double(result.Vpv(:));
    Ipv  = double(result.Ipv(:));
    Ppv  = double(result.Ppv(:));
    Vout = double(result.Vout(:));

    if isempty(time) || length(time) < 10
        warning('Skipping short/empty result: %s', files(k).name);
        continue;
    end

    dt = mean(diff(time));

    Iout = Vout ./ Rload;
    Pout = Vout .* Iout;

    %% 1. Tracking Accuracy
    Pref = movmax(Ppv, min(500, length(Ppv)));
    tracking_accuracy = mean(Ppv ./ (Pref + eps)) * 100;

    %% 2. Convergence Speed
    win = min(2000, length(Ppv));
    steady_value = mean(Ppv(end-win+1:end));
    idx_conv = find(Ppv >= 0.95 * steady_value, 1);
    if isempty(idx_conv)
        conv_time = NaN;
    else
        conv_time = time(idx_conv);
    end

    %% 3. Dynamic Stability
    win = min(5000, length(Ppv));
    steady = Ppv(end-win+1:end);
    denom = mean(steady);
    if abs(denom) < eps
        stability = NaN;
    else
        stability = std(steady) / denom;
    end

    %% 4. Energy Yield (Wh)
    energy = sum(Pout) * dt / 3600;

    %% 5. Efficiency (%)
    energy_in  = sum(Ppv)  * dt;
    energy_out = sum(Pout) * dt;
    if energy_in < eps
        efficiency = NaN;
    else
        efficiency = (energy_out / energy_in) * 100;
    end

    %% 6. CTRT (Cumulative Tracking Recovery Time)
    Pref2 = movmax(Ppv, min(500, length(Ppv)));
    below = Ppv < 0.95 * Pref2;
    ctrt  = sum(below) * dt;

    %% Store row
    metrics = [metrics;
        {files(k).name, tracking_accuracy, conv_time, stability, ...
         energy, efficiency, ctrt}];

end

%% Convert to Table
metrics_table = cell2table(metrics, ...
    'VariableNames', {'Case','TrackingAccuracy','ConvergenceTime', ...
    'DynamicStability','EnergyYield_Wh','Efficiency_percent','CTRT'});

save(fullfile(analysis_folder,'metrics_table.mat'),'metrics_table');
writetable(metrics_table, fullfile(analysis_folder,'metrics_table.csv'));
disp('Metrics Computed Successfully.');

%% Ranking
data_only = metrics_table{:,2:end};
norm_data = zeros(size(data_only));

for i = 1:size(data_only,2)
    col = data_only(:,i);
    rng = max(col) - min(col) + eps;
    if i==2 || i==3 || i==6 
        norm_data(:,i) = (max(col) - col) / rng;
    else
        norm_data(:,i) = (col - min(col)) / rng;
    end
end

score = mean(norm_data, 2);
metrics_table.Score = score;

[~,sidx] = sort(score,'descend');
ranking_table = metrics_table(sidx,:);

save(fullfile(analysis_folder,'ranking_table.mat'),'ranking_table');
writetable(ranking_table, fullfile(analysis_folder,'ranking_table.csv'));
disp('Ranking Generated.');

%% Parse Algorithm & Dataset Names
cases           = metrics_table.Case;
algorithms      = strings(height(metrics_table),1);
datasets        = strings(height(metrics_table),1);
scenarios       = strings(height(metrics_table),1);
known_scenarios = {'clear','ramp','step','mixed'};

for i = 1:length(cases)
    fname   = erase(cases{i}, '.mat');
    matched = false;
    for sc = known_scenarios
        pat = ['_' sc{1} '_'];
        if contains(fname, pat)
            p             = strfind(fname, pat);
            p             = p(1);
            datasets(i)   = string(fname(1:p-1));
            scenarios(i)  = upper(string(sc{1}));
            algorithms(i) = string(fname(p+length(pat):end));
            matched       = true;
            break;
        end
    end
    if ~matched
        warning('Could not parse scenario from: %s', cases{i});
        datasets(i)   = "unknown";
        scenarios(i)  = "UNKNOWN";
        algorithms(i) = string(fname);
    end
end

metrics_table.Algorithm = algorithms;
metrics_table.Dataset   = datasets;
metrics_table.Scenario  = scenarios;      

%% Per-Algorithm Average
numericVars  = varfun(@isnumeric, metrics_table, 'OutputFormat','uniform');
numericNames = metrics_table.Properties.VariableNames(numericVars);
alg_avg      = groupsummary(metrics_table, "Algorithm", "mean", numericNames);

writetable(alg_avg, fullfile(analysis_folder,'algorithm_average_table.csv'));
save(fullfile(analysis_folder,'algorithm_average_table.mat'),'alg_avg');

%% Plots
figure;
bar(categorical(alg_avg.Algorithm), alg_avg.mean_Efficiency_percent);
ylabel('Average Efficiency (%)'); title('Efficiency Comparison');
grid on; set(gcf,'Position',[100 100 1000 500]);
exportgraphics(gcf, fullfile(analysis_folder,'Efficiency_Comparison.png'),'Resolution',300);

figure;
bar(categorical(alg_avg.Algorithm), alg_avg.mean_EnergyYield_Wh);
ylabel('Average Energy Yield (Wh)'); title('Energy Yield Comparison');
grid on; set(gcf,'Position',[100 100 1000 500]);
exportgraphics(gcf, fullfile(analysis_folder,'Energy_Yield_Comparison.png'),'Resolution',300);

figure;
bar(categorical(alg_avg.Algorithm), alg_avg.mean_ConvergenceTime);
ylabel('Average Convergence Time (s)'); title('Convergence Speed Comparison');
grid on; set(gcf,'Position',[100 100 1000 500]);
exportgraphics(gcf, fullfile(analysis_folder,'Convergence_Comparison.png'),'Resolution',300);

figure;
bar(categorical(alg_avg.Algorithm), alg_avg.mean_DynamicStability);
title('Dynamic Stability'); grid on;
set(gcf,'Position',[100 100 1000 500]);
exportgraphics(gcf, fullfile(analysis_folder,'Stability.png'),'Resolution',300);

figure;
subplot(2,2,1); bar(categorical(alg_avg.Algorithm), alg_avg.mean_Efficiency_percent); title('Efficiency');
subplot(2,2,2); bar(categorical(alg_avg.Algorithm), alg_avg.mean_EnergyYield_Wh);     title('Energy Yield');
subplot(2,2,3); bar(categorical(alg_avg.Algorithm), alg_avg.mean_ConvergenceTime);    title('Convergence');
subplot(2,2,4); bar(categorical(alg_avg.Algorithm), alg_avg.mean_TrackingAccuracy);   title('Tracking Accuracy');
set(gcf,'Position',[100 100 1200 800]);
exportgraphics(gcf, fullfile(analysis_folder,'MultiPanel_Performance.png'),'Resolution',300);

metrics_names = {'TrackingAccuracy','EnergyYield_Wh','Efficiency_percent',...
                 'ConvergenceTime','DynamicStability','CTRT'};
meanVars  = contains(alg_avg.Properties.VariableNames,'mean_');
data      = alg_avg{:,meanVars};
data_norm = (data - min(data)) ./ (max(data) - min(data) + eps);
theta     = linspace(0, 2*pi, size(data_norm,2)+1);

figure;
pax = polaraxes; hold(pax,'on');
for i = 1:size(data_norm,1)
    polarplot(pax, theta, [data_norm(i,:) data_norm(i,1)], 'LineWidth',1.5);
end
thetaticks(rad2deg(theta(1:end-1)));
thetaticklabels(metrics_names);
legend(alg_avg.Algorithm,'Location','eastoutside');
title('Multi-Metric Radar Comparison');
exportgraphics(gcf, fullfile(analysis_folder,'Radar_Comparison.png'),'Resolution',300);

figure;
bar(ranking_table.Score(1:min(10,height(ranking_table))));
xticklabels(ranking_table.Case(1:min(10,height(ranking_table))));
xtickangle(45); ylabel('Performance Score');
title('Top 10 MPPT Performance Ranking'); grid on;
saveas(gcf, fullfile(analysis_folder,'Top10_Ranking.png'));

disp('All plots saved successfully.');



%% TOP 10 PER DATASET x SCENARIO

disp('Generating Top 10 rankings per Dataset x Scenario...');

unique_datasets  = unique(metrics_table.Dataset);
unique_scenarios = {'CLEAR','RAMP','STEP','MIXED'};

all_top10_tables = {};

for d = 1:length(unique_datasets)
    ds = unique_datasets(d);
    for s = 1:length(unique_scenarios)
        sc = string(unique_scenarios{s});

        mask   = (metrics_table.Dataset == ds) & (metrics_table.Scenario == sc);
        subset = metrics_table(mask, :);
        if height(subset) == 0, continue; end

        sub_data = subset{:, 2:7};  
        sub_norm = zeros(size(sub_data));
        for i = 1:size(sub_data,2)
            col = sub_data(:,i);
            rng = max(col) - min(col) + eps;
            if ismember(i, [2 3 6])   
                sub_norm(:,i) = (max(col) - col) / rng;
            else
                sub_norm(:,i) = (col - min(col)) / rng;
            end
        end
        sub_score = mean(sub_norm, 2);

        [~, sidx]  = sort(sub_score, 'descend');
        top_n      = min(10, height(subset));
        top10      = subset(sidx(1:top_n), :);
        top10.SubsetScore = sub_score(sidx(1:top_n));
        top10.Rank        = (1:top_n)';

        safe_ds  = strrep(char(ds), ' ', '_');
        safe_sc  = lower(char(sc));
        out_csv  = fullfile(analysis_folder, sprintf('top10_%s_%s.csv', safe_ds, safe_sc));
        writetable(top10, out_csv);

        all_top10_tables{end+1} = top10; 

        fh = figure('Visible','off');
        bh = bar(top10.SubsetScore, 'FaceColor','flat');
        cmap = parula(top_n);
        for ci = 1:top_n
            bh.CData(ci,:) = cmap(ci,:);
        end
        set(gca, 'XTick', 1:top_n, ...
                 'XTickLabel', top10.Algorithm, ...
                 'XTickLabelRotation', 45);
        ylabel('Performance Score (within subset)');
        title(sprintf('Top %d  —  Dataset: %s  |  Scenario: %s', top_n, ds, sc), ...
              'Interpreter','none');
        grid on;
        set(fh,'Position',[100 100 1000 520]);
        exportgraphics(fh, fullfile(analysis_folder, ...
            sprintf('top10_%s_%s.png', safe_ds, safe_sc)), 'Resolution',300);
        close(fh);
    end
end

if ~isempty(all_top10_tables)
    combined = vertcat(all_top10_tables{:});
    writetable(combined, fullfile(analysis_folder,'top10_all_dataset_scenario.csv'));
end

n_ds      = length(unique_datasets);
n_sc      = length(unique_scenarios);
sc_colors = lines(n_sc);

fov = figure('Visible','off','Position',[100 100 1400 max(300*n_ds, 600)]);
sp_idx = 0;
for d = 1:n_ds
    ds = unique_datasets(d);
    for s = 1:n_sc
        sc   = string(unique_scenarios{s});
        mask = (metrics_table.Dataset == ds) & (metrics_table.Scenario == sc);
        subset = metrics_table(mask, :);

        sp_idx = sp_idx + 1;
        ax = subplot(n_ds, n_sc, sp_idx);

        if height(subset) == 0
            title(ax, sprintf('%s | %s\n(no data)', ds, sc), ...
                  'FontSize',7,'Interpreter','none');
            axis(ax,'off');
            continue;
        end

        sub_data = subset{:,2:7};
        sub_norm = zeros(size(sub_data));
        for i = 1:size(sub_data,2)
            col = sub_data(:,i);
            rng = max(col)-min(col)+eps;
            if ismember(i,[2 3 6])
                sub_norm(:,i)=(max(col)-col)/rng;
            else
                sub_norm(:,i)=(col-min(col))/rng;
            end
        end
        sub_score = mean(sub_norm,2);
        [~,sidx]  = sort(sub_score,'descend');
        top_n     = min(10, height(subset));
        top10     = subset(sidx(1:top_n),:);
        top10.SubsetScore = sub_score(sidx(1:top_n));

        bar(ax, top10.SubsetScore, 'FaceColor', sc_colors(s,:));
        set(ax, 'XTick',1:top_n, 'XTickLabel', top10.Algorithm, ...
            'XTickLabelRotation',40, 'FontSize',6);
        ylabel(ax,'Score','FontSize',6);
        title(ax, sprintf('%s | %s', ds, sc),'FontSize',7,'Interpreter','none');
        grid(ax,'on');
    end
end
sgtitle(fov, 'Top 10 Algorithm Rankings — per Dataset × Scenario','FontSize',13);
exportgraphics(fov, fullfile(analysis_folder,'Top10_Dataset_Scenario_Overview.png'), ...
    'Resolution',300);
close(fov);

disp('Top 10 per Dataset x Scenario rankings saved.');
disp('Done.');



%% EXCEL REPORT GENERATOR

disp('Generating Excel report...');

excel_output = fullfile(analysis_folder, 'PRELIMINARY_DATA_FILLED.xlsx');

%% Algorithm name mapping 
alg_display_map = containers.Map( ...
    {'PO','PandO','po','pandO','P_O', ...
     'InCond','incond','IncCond','inccond','IC', ...
     'SMC','smc', ...
     'RCC','rcc', ...
     'FSB','fsb','Fibonacci','fibonacci','FIBONACCI','FibonacciSearch','fibonacci_search', ...
     'FLC','flc', ...
     'ANN','ann', ...
     'PSO','pso', ...
     'GA','ga', ...
     'GWO','gwo'}, ...
    {'P&O','P&O','P&O','P&O','P&O', ...
     'IncCond','IncCond','IncCond','IncCond','IncCond', ...
     'SMC','SMC', ...
     'RCC','RCC', ...
     'FSB','FSB','FSB','FSB','FSB','FSB','FSB', ...
     'FLC','FLC', ...
     'ANN','ANN', ...
     'PSO','PSO', ...
     'GA','GA', ...
     'GWO','GWO'} ...
);

canonical_alg_order = {'P&O','IncCond','SMC','RCC','FSB','FLC','ANN','PSO','GA','GWO'};

%% Map Algorithm column to display names 
display_algs = strings(height(metrics_table), 1);
for i = 1:height(metrics_table)
    raw = char(metrics_table.Algorithm(i));
    if isKey(alg_display_map, raw)
        display_algs(i) = alg_display_map(raw);
    else
        display_algs(i) = string(raw);
    end
end
metrics_table.DisplayAlgorithm = display_algs;

%% Build Sheet 1 data 
sheet1_headers = {'Algorithm','Dataset','Scenario', ...
    'Convergence Speed (s)', ...
    'Tracking Efficiency (%) ', ...
    'Tracking Accuracy (Stability)', ...
    'Harvested Energy (Wh)', ...
    'Cloud Transient Recovery Time (s)'};

sheet1_rows = cell(0, 8);

for a = 1:length(canonical_alg_order)
    alg_name = canonical_alg_order{a};
    mask_alg = strcmp(metrics_table.DisplayAlgorithm, alg_name);
    subset   = metrics_table(mask_alg, :);

    if height(subset) == 0
        for r = 1:12
            sheet1_rows(end+1, :) = {alg_name, '', '', NaN, NaN, NaN, NaN, NaN}; 
        end
        continue;
    end

    try
        subset = sortrows(subset, {'Dataset','Scenario'});
    catch
    end

    for r = 1:height(subset)
        sheet1_rows(end+1, :) = { ...
            alg_name, ...
            char(subset.Dataset(r)), ...
            char(subset.Scenario(r)), ...
            subset.ConvergenceTime(r), ...
            subset.Efficiency_percent(r), ...
            subset.DynamicStability(r), ...
            subset.EnergyYield_Wh(r), ...
            subset.CTRT(r) ...
        }; 
    end
end

sheet1_data = [sheet1_headers; sheet1_rows];

%% Build Sheet 2 data 
alg_avg_display = strings(height(alg_avg), 1);
for i = 1:height(alg_avg)
    raw = char(alg_avg.Algorithm(i));
    if isKey(alg_display_map, raw)
        alg_avg_display(i) = alg_display_map(raw);
    else
        alg_avg_display(i) = string(raw);
    end
end

sheet2_title   = {'AVERAGE PERFORMANCE PER ALGORITHM', '', '', '', ''};
sheet2_headers = {'Algorithm', ...
    'Average Tc (Convergence Time)', ...
    'Average Efficiency', ...
    'Average Energy', ...
    'Average Recovery'};

sheet2_rows = cell(height(alg_avg), 5);
for i = 1:height(alg_avg)
    sheet2_rows{i,1} = char(alg_avg_display(i));
    sheet2_rows{i,2} = alg_avg.mean_ConvergenceTime(i);
    sheet2_rows{i,3} = alg_avg.mean_Efficiency_percent(i);
    sheet2_rows{i,4} = alg_avg.mean_EnergyYield_Wh(i);
    sheet2_rows{i,5} = alg_avg.mean_CTRT(i);
end

sheet2_data = [sheet2_title; sheet2_headers; sheet2_rows];

%% Write to Excel 
if exist(excel_output, 'file')
    delete(excel_output);
end

writecell(sheet1_data, excel_output, 'Sheet', 'Master Dataset');
writecell(sheet2_data, excel_output, 'Sheet', 'Average Performance');

disp(['Excel report saved to: ' excel_output]);
disp('Excel generation complete.');