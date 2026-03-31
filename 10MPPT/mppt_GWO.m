%% Underperforming algorithm that is possibly due to implementation. Metaheuristics rely on proper N_hold and N values wherein N_hold is the population update steps and N is the population number. 
%% The researchers recommend tweaking these values where higher N can result in better accuracy and lower N_hold value can result in faster convergence.

function D = mppt_GWO(Vpv, Ipv)

D_min    = 0.05;
D_max    = 0.90;
N        = 5;
max_iter = 500;
N_hold   = 2000;

D_init_lo = 0.35;
D_init_hi = 0.65;

persistent pos fitness eval_idx iter alpha_pos beta_pos delta_pos hold_ctr in_hold

if isempty(pos)
    pos       = linspace(D_init_lo, D_init_hi, N)';
    fitness   = -inf(N,1);
    eval_idx  = 1;
    iter      = 1;
    alpha_pos = 0.5;
    beta_pos  = 0.45;
    delta_pos = 0.55;
    hold_ctr  = 0;
    in_hold   = false;
end

P = Vpv * Ipv;

%% Hold phase
if in_hold
    hold_ctr = hold_ctr + 1;
    if hold_ctr >= N_hold
        in_hold  = false;
        hold_ctr = 0;
    end
    D = alpha_pos;
    D = min(max(D, D_min), D_max);
    return;
end

%% Evaluation phase
fitness(eval_idx) = P;
eval_idx = eval_idx + 1;

if eval_idx > N
    [~, sidx] = sort(fitness,'descend');
    alpha_pos = pos(sidx(1));
    beta_pos  = pos(sidx(2));
    delta_pos = pos(sidx(3));

    a = max(2*(1 - iter/max_iter), 0);

    for i = 1:N
        A1=2*a*rand-a; C1=2*rand;
        X1=alpha_pos-A1*abs(C1*alpha_pos-pos(i));
        A2=2*a*rand-a; C2=2*rand;
        X2=beta_pos -A2*abs(C2*beta_pos -pos(i));
        A3=2*a*rand-a; C3=2*rand;
        X3=delta_pos-A3*abs(C3*delta_pos-pos(i));
        pos(i)=min(max((X1+X2+X3)/3,D_min),D_max);
    end

    pos(sidx(1)) = alpha_pos;
    pos(sidx(2)) = beta_pos;
    pos(sidx(3)) = delta_pos;

    fitness  = -inf(N,1);
    eval_idx = 1;
    iter     = iter + 1;

    if (max(pos)-min(pos)) < 0.002
        spread   = linspace(-0.1, 0.1, N)';
        pos      = min(max(alpha_pos + spread, D_min), D_max);
        pos(1)   = alpha_pos;
        iter     = 1;
    end

    in_hold  = true;
    hold_ctr = 0;
end

D = pos(eval_idx);
D = min(max(D, D_min), D_max);
end