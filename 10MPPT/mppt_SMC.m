function D = mppt_SMC(Vpv, Ipv)

D_min = 0.05;
D_max = 0.90;
k     = 0.005;  

persistent Vprev Pprev Dprev

if isempty(Vprev)
    Vprev = 0;
    Pprev = 0;
    Dprev = 0.5;
end

P  = Vpv * Ipv;
dV = Vpv - Vprev;
dP = P   - Pprev;

%% Sliding surface 
if abs(dV) > 1e-6
    S = dP / dV;   
else
    S = 0;        
end

%% Control law
D = Dprev - k * sign(S);

D = min(max(D, D_min), D_max);

Vprev = Vpv;
Pprev = P;
Dprev = D;

end