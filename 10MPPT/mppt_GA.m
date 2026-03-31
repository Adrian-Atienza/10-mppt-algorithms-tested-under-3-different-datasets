%% Underperforming algorithm that is possibly due to implementation. Metaheuristics rely on proper N_hold and N values wherein N_hold is the population update steps and N is the population number. 
%% The researchers recommend tweaking these values where higher N can result in better accuracy and lower N_hold value can result in faster convergence.

function D = mppt_GA(Vpv, Ipv)

D_min   = 0.05;
D_max   = 0.90;
N       = 6;
BITS    = 8;
p_cross = 0.80;
p_mut   = 0.04;
tour_k  = 2;
N_hold  = 2000;

D_init_lo = 0.35;
D_init_hi = 0.65;

persistent pop fitness eval_idx best_D hold_ctr in_hold

if isempty(pop)
    d_vals   = linspace(D_init_lo, D_init_hi, N)';
    pop      = ga_encode(d_vals, D_min, D_max, BITS);
    fitness  = -inf(N,1);
    eval_idx = 1;
    best_D   = 0.5;
    hold_ctr = 0;
    in_hold  = false;
end

P = Vpv * Ipv;

%% Hold phase
if in_hold
    hold_ctr = hold_ctr + 1;
    if hold_ctr >= N_hold
        in_hold  = false;
        hold_ctr = 0;
    end
    D = best_D;
    D = min(max(D, D_min), D_max);
    return;
end

%% Evaluation phase
fitness(eval_idx) = P;

[cur_best_P, best_idx] = max(fitness);
if cur_best_P > -inf
    best_D = ga_decode(pop(best_idx,:), D_min, D_max, BITS);
end

eval_idx = eval_idx + 1;

if eval_idx > N
    elite = pop(best_idx,:);

    % Tournament selection
    mating_pool = false(N, BITS);
    for i = 1:N
        cands       = randperm(N, tour_k);
        [~, winner] = max(fitness(cands));
        mating_pool(i,:) = pop(cands(winner),:);
    end

    % Crossover
    children = mating_pool;
    for i = 1:2:N-1
        if rand < p_cross
            pt = randi(BITS-1);
            children(i,  pt+1:end) = mating_pool(i+1,pt+1:end);
            children(i+1,pt+1:end) = mating_pool(i,  pt+1:end);
        end
    end

    % Mutation
    children = xor(children, rand(N,BITS) < p_mut);

    % Elitism
    [~, worst_idx] = min(fitness);
    children(worst_idx,:) = elite;

    % Clamp decoded values
    for i = 1:N
        d = ga_decode(children(i,:), D_min, D_max, BITS);
        d = min(max(d, D_min), D_max);
        children(i,:) = ga_encode(d, D_min, D_max, BITS);
    end

    pop      = children;
    fitness  = -inf(N,1);
    eval_idx = 1;
    in_hold  = true;
    hold_ctr = 0;
end

D = ga_decode(pop(eval_idx,:), D_min, D_max, BITS);
D = min(max(D, D_min), D_max);
end

function bits = ga_encode(d_vals, D_min, D_max, BITS)
    n    = numel(d_vals);
    bits = false(n, BITS);
    ints = min(max(round((d_vals-D_min)/(D_max-D_min)*255),0),255);
    for i = 1:n
        for b = 1:BITS
            bits(i,BITS-b+1) = logical(bitand(ints(i),2^(b-1)));
        end
    end
end

function d = ga_decode(row, D_min, D_max, BITS)
    val = 0;
    for b = 1:BITS
        val = val + row(BITS-b+1)*2^(b-1);
    end
    d = D_min + (val/255)*(D_max-D_min);
end