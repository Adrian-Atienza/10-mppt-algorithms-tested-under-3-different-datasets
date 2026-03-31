function D = mppt_FLC(Vpv, Ipv)

D_min  = 0.05;
D_max  = 0.90;
dD_max = 0.015;  

persistent Vprev Pprev Eprev Dprev

if isempty(Vprev)
    Vprev = 0; Pprev = 0; Eprev = 0; Dprev = 0.5;
end

P  = Vpv * Ipv;
dV = Vpv - Vprev;
dP = P   - Pprev;

%% Crisp inputs
if abs(dV) > 1e-6
    E = dP / dV;
else
    E = 0;
end
CE = E - Eprev;

%% Normalise 
E_scale  = 15;
CE_scale = 8;
E_n  = max(min(E  / E_scale,  1), -1);
CE_n = max(min(CE / CE_scale, 1), -1);

%% Fuzzification
c    = [-1, -0.5, 0, 0.5, 1];
mu_E  = flc_mf(E_n,  c);
mu_CE = flc_mf(CE_n, c);

%% 25-rule Mamdani (min t-norm, max aggregation)
rules = [5 5 4 4 3;
         5 4 4 3 2;
         4 4 3 2 2;
         4 3 2 2 1;
         3 2 2 1 1];

out_mu = zeros(1,5);
for re = 1:5
    for rce = 1:5
        oi = rules(re,rce);
        out_mu(oi) = max(out_mu(oi), min(mu_E(re), mu_CE(rce)));
    end
end

%% Centroid defuzzification
out_c = [-1, -0.5, 0, 0.5, 1] * dD_max;
if sum(out_mu) < 1e-9
    deltaD = 0;
else
    deltaD = sum(out_mu .* out_c) / sum(out_mu);
end

%% Integrate
D = Dprev + deltaD;
D = min(max(D, D_min), D_max);

Vprev = Vpv; Pprev = P; Eprev = E; Dprev = D;
end

function mu = flc_mf(x, c)
    n  = length(c);
    mu = zeros(1,n);
    w  = c(2) - c(1);
    for i = 1:n
        if i == 1
            if     x <= c(i),      mu(i) = 1;
            elseif x <  c(i)+w,    mu(i) = (c(i)+w-x)/w;
            end
        elseif i == n
            if     x >= c(i),      mu(i) = 1;
            elseif x >  c(i)-w,    mu(i) = (x-(c(i)-w))/w;
            end
        else
            if     x >= c(i-1) && x <= c(i),   mu(i) = (x-c(i-1))/w;
            elseif x >  c(i)   && x <= c(i+1), mu(i) = (c(i+1)-x)/w;
            end
        end
    end
end