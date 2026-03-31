clear; clc;
warning('off','Simulink:Engine:AccelBuildCleanup')


model = 'pv_environment';
load_system(model);

datasets = {'mid_latitude','cloud_transient','tropical'};
scenarios = {'clear','ramp','step','mixed'};
algorithms = {'PO','IncCond','SMC','RCC','Fibonacci','FLC','ANN','PSO','GA','GWO'};

results_folder = 'results';

if ~exist(results_folder,'dir')
    mkdir(results_folder);
end
clc

sim_time = 60;

for d = 1:length(datasets)
    for s = 1:length(scenarios)
        
        dataset_name = [datasets{d} '_' scenarios{s}];
        load([dataset_name '.mat']);   
        assignin('base','data',data);
        
        for a = 1:length(algorithms)
            
            filename = fullfile(results_folder, ...
                [dataset_name '_' algorithms{a} '.mat']);
            
            if exist(filename,'file')
                fprintf('Skipping (already done): %s\n', filename);
                continue;
            end
            
            fprintf('Running: %s | Algo: %s\n', ...
                dataset_name, algorithms{a});
            
            assignin('base','algo_id',a);
            
            simOut = sim(model,'StopTime',num2str(sim_time));
            
            Vpv  = simOut.logsout.get('Vpv').Values.Data;
            Ipv  = simOut.logsout.get('Ipv').Values.Data;
            Ppv  = simOut.logsout.get('Ppv').Values.Data;
            Duty = simOut.logsout.get('Duty').Values.Data;
            Vout = simOut.logsout.get('Vout').Values.Data;
            Time = simOut.logsout.get('Vpv').Values.Time;
            
            result.time  = single(Time);
            result.Vpv   = single(Vpv);
            result.Ipv   = single(Ipv);
            result.Ppv   = single(Ppv);
            result.Duty  = single(Duty);
            result.Vout  = single(Vout);
            
            save(filename,'result','-v7');
            
            clear simOut result Vpv Ipv Ppv Duty Vout Time
            
        end
    end
end

disp('ALL 120 SIMULATIONS COMPLETED SUCCESSFULLY.');
