function D = mppt_FSB(Vpv, Ipv)

D_min = 0.05;
D_max = 0.90;
phi   = (sqrt(5) - 1) / 2;
reset_width = 0.01;

persistent D_lo D_hi d1 d2 P1 phase

if isempty(D_lo)
    D_lo  = D_min;
    D_hi  = D_max;
    d1    = D_lo + (1-phi)*(D_hi-D_lo);
    d2    = D_lo +    phi *(D_hi-D_lo);
    phase = 1;
    P1    = 0;
end

P = Vpv * Ipv;

if phase == 1
    P1    = P;
    D     = d2;
    phase = 2;
else
    P2 = P;
    if P1 >= P2
        D_hi = d2;
        d2   = d1;
        d1   = D_lo + (1-phi)*(D_hi-D_lo);
        D    = d1;
    else
        D_lo = d1;
        d1   = d2;
        d2   = D_lo + phi*(D_hi-D_lo);
        D    = d2;
    end
    phase = 1;
    P1    = 0;

    if (D_hi - D_lo) < reset_width
        D_lo  = D_min;
        D_hi  = D_max;
        d1    = D_lo + (1-phi)*(D_hi-D_lo);
        d2    = D_lo +    phi *(D_hi-D_lo);
    end
end

D = min(max(D, D_min), D_max);
end