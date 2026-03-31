clear; clc;

%% ALGORITHM RANK STABILITY (ARS)
%% Entropy Weight Method Implementation

disp('Starting Algorithm Rank Stability (ARS) Computation...');

% Create output folder

output_folder = 'Algorithm_rank_stability_results';

if ~exist(output_folder,'dir')
    mkdir(output_folder);
end

% Load averaged algorithm data

load(fullfile('analysis_results','algorithm_average_table.mat'));


% Build Decision Matrix

StabilityBenefit = 1 ./ (alg_avg.mean_DynamicStability + eps);

X = [
    alg_avg.mean_ConvergenceTime, ...
    alg_avg.mean_Efficiency_percent, ...
    StabilityBenefit, ...
    alg_avg.mean_EnergyYield_Wh, ...
    alg_avg.mean_CTRT
];

% Normalize Matrix

R = zeros(size(X));

% Cost criteria
R(:,1) = min(X(:,1)) ./ X(:,1);   % Convergence Time
R(:,5) = min(X(:,5)) ./ X(:,5);   % Recovery Time

% Benefit criteria
R(:,2) = X(:,2) ./ max(X(:,2));   % Efficiency
R(:,3) = X(:,3) ./ max(X(:,3));   % Stability
R(:,4) = X(:,4) ./ max(X(:,4));   % Energy

% Probability Matrix

P = R ./ (sum(R) + eps);

% Entropy Calculation

n = size(R,1);
k = 1 / log(n);

E = -k * sum(P .* log(P + eps));

% Diversification Degree

d = 1 - E;

% Entropy Weights

w = d ./ sum(d);

entropy_weights = table( ...
    ["ConvergenceTime"; "Efficiency"; "Stability"; "Energy"; "RecoveryTime"], ...
    w', ...
    'VariableNames', {'Metric','Weight'});

writetable(entropy_weights, ...
    fullfile(output_folder,'Entropy_Weights.csv'));

% Compute ARS

ARS = R * w';

ARS_table = table( ...
    alg_avg.Algorithm, ...
    ARS, ...
    'VariableNames', {'Algorithm','ARS'});

% Ranking

[~, idx] = sort(ARS,'descend');

ranking_table = ARS_table(idx,:);
ranking_table.Rank = (1:height(ranking_table))';

writetable(ranking_table, ...
    fullfile(output_folder,'Algorithm_Rank_Stability_Ranking.csv'));

save(fullfile(output_folder,'Algorithm_Rank_Stability.mat'), ...
    'ranking_table','entropy_weights','R','X');

disp('Algorithm Rank Stability Computation Completed Successfully.');

%% PLOTTING SECTION

disp('Generating ARS Plots...');

% Entropy Weights Plot

figure;
bar(w);
set(gca,'XTickLabel',entropy_weights.Metric);
xtickangle(45);
ylabel('Weight Value');
title('Entropy Weight Distribution');
grid on;

saveas(gcf, fullfile(output_folder,'Entropy_Weights_Plot.png'));

% ️ ARS Score Plot 

figure;
bar(ranking_table.ARS);
set(gca,'XTickLabel',ranking_table.Algorithm);
xtickangle(45);
ylabel('ARS Score');
title('Algorithm Rank Stability (ARS) Scores');
grid on;

saveas(gcf, fullfile(output_folder,'ARS_Score_Plot.png'));

% Ranked Order Plot

figure;
plot(1:height(ranking_table), ranking_table.ARS, '-o');
xticks(1:height(ranking_table));
xticklabels(ranking_table.Algorithm);
xtickangle(45);
ylabel('ARS Score');
xlabel('Rank Position');
title('Sorted ARS Ranking Curve');
grid on;

saveas(gcf, fullfile(output_folder,'ARS_Ranking_Curve.png'));

disp('ARS Plots Generated Successfully.');