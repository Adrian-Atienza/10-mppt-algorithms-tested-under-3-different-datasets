clear; clc;

load('All_Results.mat');   % contains structure "results"

numRuns = length(results);

Metrics = struct();

for i = 1:numRuns
    
    time = results(i).time;
    Vpv  = results(i).Vpv;
    Ipv  = results(i).Ipv;
    Ppv  = Vpv .* Ipv;
    Vout = results(i).Vout;
    
    % ===============================
    % 1️⃣ Energy
    % ===============================
    Energy = trapz(time, Ppv);
    
    % ===============================
    % 2️⃣ Average Power
    % ===============================
    AvgPower = mean(Ppv);
    
    % ===============================
    % 3️⃣ Tracking Accuracy
    % ===============================
    Pmax = max(Ppv);
    Accuracy = (AvgPower / Pmax) * 100;
    
    % ===============================
    % 4️⃣ Convergence Time (95%)
    % ===============================
    threshold = 0.95 * Pmax;
    idx = find(Ppv >= threshold, 1, 'first');
    
    if isempty(idx)
        ConvTime = NaN;
    else
        ConvTime = time(idx);
    end
    
    % ===============================
    % 5️⃣ Dynamic Stability
    % ===============================
    steady_idx = round(length(time)*0.7):length(time);
    Stability = std(Ppv(steady_idx));
    
    % ===============================
    % 6️⃣ Efficiency
    % ===============================
    Pout = Vout .* Ipv;
    Efficiency = mean(Pout ./ (Ppv + 1e-6)) * 100;
    
    % ===============================
    % 7️⃣ CTRT (outside ±2% band)
    % ===============================
    band_low  = 0.98 * Pmax;
    band_high = 1.02 * Pmax;
    
    outside = (Ppv < band_low) | (Ppv > band_high);
    CTRT = sum(outside) * (time(2) - time(1));
    
    % ===============================
    % 8️⃣ ARS (Average Ripple Size)
    % ===============================
    ARS = mean(abs(diff(Ppv)));
    
    % ===============================
    % Store Results
    % ===============================
    Metrics(i).Dataset = results(i).Dataset;
    Metrics(i).Scenario = results(i).Scenario;
    Metrics(i).Algorithm = results(i).Algorithm;
    
    Metrics(i).Energy = Energy;
    Metrics(i).AvgPower = AvgPower;
    Metrics(i).Accuracy = Accuracy;
    Metrics(i).ConvTime = ConvTime;
    Metrics(i).Stability = Stability;
    Metrics(i).Efficiency = Efficiency;
    Metrics(i).CTRT = CTRT;
    Metrics(i).ARS = ARS;
    
end

save('Performance_Metrics.mat','Metrics');

disp('All performance metrics calculated.');
