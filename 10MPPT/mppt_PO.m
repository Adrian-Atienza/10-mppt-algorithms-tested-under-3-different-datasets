function D = mppt_PO(Vpv, Ipv)

D_min = 0.05;
D_max = 0.9;
deltaD = 0.002;

persistent Vprev Pprev Dprev

if isempty(Vprev)
    Vprev = 0;
    Pprev = 0;
    Dprev = 0.5;
end

P = Vpv * Ipv;
dP = P - Pprev;
dV = Vpv - Vprev;

if dP > 0
    if dV > 0
        D = Dprev - deltaD;
    else
        D = Dprev + deltaD;
    end
else
    if dV > 0
        D = Dprev + deltaD;
    else
        D = Dprev - deltaD;
    end
end

D = min(max(D, D_min), D_max);

Vprev = Vpv;
Pprev = P;
Dprev = D;

end