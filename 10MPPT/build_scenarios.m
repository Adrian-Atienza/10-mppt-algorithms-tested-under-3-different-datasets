%% Scenario Builder
clear; clc;

datasets = {'mid_latitude','cloud_transient','tropical'};

for d = 1:length(datasets)

    load([datasets{d} '.mat']);

    t = data.time;
    G = data.irradiance;
    T = data.temperature;
    N = length(t);

    %% 1. CLEAR SKY SCENARIO

    window = 2000; 
    G_var = movvar(G,window);

    [~,idx_min] = min(G_var);
    idx_range = idx_min : min(idx_min+N-1,length(G));

    G_clear = G;
    G_clear = smoothdata(G_clear,'movmean',500);

    G_clear(G_clear < 0) = 0;

    save_scenario(datasets{d},'clear',t,G_clear,T);

    %% 2. RAMP SCENARIO

    G_ramp = G;

    ramp_start = round(N*0.2);
    ramp_end   = round(N*0.6);

    ramp_profile = linspace(0.7,1.0,ramp_end-ramp_start+1)';

    G_ramp(ramp_start:ramp_end) = ...
        G_ramp(ramp_start:ramp_end).*ramp_profile;

    G_ramp(G_ramp < 0) = 0;

    save_scenario(datasets{d},'ramp',t,G_ramp,T);

    %% 3. STEP SCENARIO

    G_step = G;

    step_idx = round(N/2);
    ramp_dur = round(0.3 * 1000); 

    drop_ratio = 0.6;

    ramp_down = linspace(1,drop_ratio,ramp_dur)';

    G_step(step_idx:step_idx+ramp_dur-1) = ...
        G_step(step_idx:step_idx+ramp_dur-1).*ramp_down;

    G_step(step_idx+ramp_dur:end) = ...
        G_step(step_idx+ramp_dur:end)*drop_ratio;

    G_step(G_step < 0) = 0;

    save_scenario(datasets{d},'step',t,G_step,T);

    %% 4. MIXED WEATHER SCENARIO

    G_mix = G;

    idx1 = round(N*0.25):round(N*0.35);
    G_mix(idx1) = G_mix(idx1) * 0.5;

    idx2 = round(N*0.6):round(N*0.8);
    recovery = linspace(0.8,1.0,length(idx2))';
    G_mix(idx2) = G_mix(idx2).*recovery;

    G_mix(G_mix < 0) = 0;

    save_scenario(datasets{d},'mixed',t,G_mix,T);

end

disp('All scenarios created successfully.');

function save_scenario(name,sc,t,G,T)

data.time = t;
data.irradiance = G;
data.temperature = T;

fname = [name '_' sc];

save([fname '.mat'],'data');

fid = fopen([fname '.csv'],'w');
fprintf(fid,'time,irradiance,temperature\n');

for i = 1:length(t)
    fprintf(fid,'%.6f,%.2f,%.2f\n',t(i),G(i),T(i));
end

fclose(fid);

fprintf('Saved %s\n',fname);

end
