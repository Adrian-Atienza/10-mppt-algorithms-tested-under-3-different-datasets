function D = mppt_RCC(Vpv, Ipv)

D_min  = 0.05;
D_max  = 0.90;
deltaD = 0.002;

persistent Vprev Pprev Dprev

if isempty(Vprev)
    Vprev = 0;
    Pprev = 0;
    Dprev = 0.5;
end

P  = Vpv * Ipv;
dV = Vpv - Vprev;
dP = P   - Pprev;

if abs(dV) > 1e-6 && abs(dP) > 1e-6
    if sign(dP) == sign(dV)
        D = Dprev - deltaD;   
    else
        D = Dprev + deltaD;   
    end
else
    D = Dprev;
end

D = min(max(D, D_min), D_max);

Vprev = Vpv;
Pprev = P;
Dprev = D;
end