function D = mppt_IncCond(Vpv, Ipv)

D_min = 0.05;
D_max = 0.90;
deltaD = 0.002;
tol    = 0.001;   

persistent Vprev Iprev Dprev

if isempty(Vprev)
    Vprev = 0;
    Iprev = 0;
    Dprev = 0.5;
end

dV = Vpv - Vprev;
dI = Ipv - Iprev;

if abs(dV) > 1e-6
    inc_cond  = dI / dV;          
    inst_cond = -Ipv / (Vpv + eps); 
    error_val = inc_cond - inst_cond;

    if abs(error_val) < tol
        D = Dprev;                 
    elseif error_val > tol
        D = Dprev - deltaD;        
    else
        D = Dprev + deltaD;        
    end
else

    if abs(dI) < 1e-6
        D = Dprev;                 
    elseif dI > 0
        D = Dprev - deltaD;
    else
        D = Dprev + deltaD;
    end
end

D = min(max(D, D_min), D_max);

Vprev = Vpv;
Iprev = Ipv;
Dprev = D;

end