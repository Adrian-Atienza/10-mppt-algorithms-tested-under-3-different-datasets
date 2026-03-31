%% This ANN algorithm is implemented using online backpropagation. This means that its models are being trained during the simulation, which causes extra time for it to converge.
%% The researchers recommend the usage of pre-trained ANN for better reuslts.

function D = mppt_ANN(Vpv, Ipv)

D_min    = 0.05;
D_max    = 0.90;
lr       = 5e-3;
settle_N = 200;

persistent W1 b1 W2 b2 ANN_step ANN_Dsettle ANN_Psettle

if isempty(W1)
    W1 = [ 0.30, -0.20;
          -0.30,  0.40;
           0.20,  0.30;
          -0.20, -0.30;
           0.40,  0.10];
    b1 = zeros(5,1);
    W2 = [0.20, -0.20, 0.15, -0.15, 0.10];
    b2 = 0;
    ANN_step    = 0;
    ANN_Dsettle = 0.5;
    ANN_Psettle = 0;
end

P = Vpv * Ipv;

%% Forward pass
x   = [Vpv/50; Ipv/10];
z1  = W1*x + b1;
h   = tanh(z1);
z2  = W2*h + b2;
sig = 1 / (1 + exp(-z2));
D   = D_min + (D_max - D_min) * sig;

%% Settled gradient update
ANN_step = ANN_step + 1;

if ANN_step >= settle_N
    dD_ann = D - ANN_Dsettle;
    dP_ann = P - ANN_Psettle;

    if abs(dD_ann) > 1e-4
        raw_grad = -dP_ann / dD_ann;
        dL_dD    = max(min(raw_grad, 50), -50);

        dD_dz2 = (D_max - D_min) * sig * (1 - sig);
        dL_dz2 = dL_dD * dD_dz2;
        dL_dW2 = dL_dz2 * h';
        dL_db2 = dL_dz2;
        dL_dh  = W2' * dL_dz2;
        dL_dz1 = dL_dh .* (1 - h.^2);
        dL_dW1 = dL_dz1 * x';
        dL_db1 = dL_dz1;

        W2 = W2 - lr * dL_dW2;
        b2 = b2 - lr * dL_db2;
        W1 = W1 - lr * dL_dW1;
        b1 = b1 - lr * dL_db1;
    end

    ANN_Dsettle = D;
    ANN_Psettle = P;
    ANN_step    = 0;
end

D = min(max(D, D_min), D_max);
end