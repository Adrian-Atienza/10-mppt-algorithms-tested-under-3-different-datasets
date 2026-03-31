%% Underperforming algorithm that is possibly due to implementation. Metaheuristics rely on proper N_hold and N values wherein N_hold is the population update steps and N is the population number. 
%% The researchers recommend tweaking these values where higher N can result in better accuracy and lower N_hold value can result in faster convergence.

function D = mppt_PSO(Vpv, Ipv)

D_min  = 0.05;
D_max  = 0.90;
N      = 5;
w      = 0.70;
c1     = 1.50;
c2     = 1.50;
N_hold = 2000;

D_init_lo = 0.35;
D_init_hi = 0.65;

persistent pos vel pbest pbest_P gbest gbest_P eval_idx hold_ctr in_hold

if isempty(pos)
    pos      = linspace(D_init_lo, D_init_hi, N)';
    vel      = zeros(N,1);
    pbest    = pos;
    pbest_P  = -inf(N,1);
    gbest    = 0.5;
    gbest_P  = -inf;
    eval_idx = 1;
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
    D = gbest;
    D = min(max(D, D_min), D_max);
    return;
end

%% Evaluation phase
if P > pbest_P(eval_idx)
    pbest_P(eval_idx) = P;
    pbest(eval_idx)   = pos(eval_idx);
end
if P > gbest_P
    gbest_P = P;
    gbest   = pos(eval_idx);
end

eval_idx = eval_idx + 1;

if eval_idx > N
    r1  = rand(N,1); r2 = rand(N,1);
    vel = w*vel + c1*r1.*(pbest-pos) + c2*r2.*(gbest-pos);
    v_max = 0.15*(D_max-D_min);   
    vel = min(max(vel,-v_max),v_max);
    pos = min(max(pos+vel, D_min), D_max);

    if (max(pos)-min(pos)) < 0.002
        spread = linspace(-0.1, 0.1, N)';
        pos    = min(max(gbest + spread, D_min), D_max);
        vel    = zeros(N,1);
        pbest  = pos;
        pbest_P= -inf(N,1);
    end

    eval_idx = 1;
    in_hold  = true;
    hold_ctr = 0;
end

D = pos(eval_idx);
D = min(max(D, D_min), D_max);
end