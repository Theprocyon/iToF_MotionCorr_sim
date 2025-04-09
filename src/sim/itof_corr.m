function corr = itof_corr(T, f0, es, ea, depth_map, N)

    c = 3e8;
    [H, W] = size(depth_map); 
    corr = zeros(H, W, N);    

    for n = 1:N
        psi_n = 2*pi*(n-1)/N;

        cos_term = cos((4 * pi * f0 .* depth_map) / c - psi_n);

        Cn = (T/2) * (es + ea + 0.5 .* es .* cos_term);
        
        corr(:,:,n) = Cn;
    end
end