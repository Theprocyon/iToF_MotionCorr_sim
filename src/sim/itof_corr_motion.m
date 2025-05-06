function corr = itof_corr_motion(T, f0, es, ea, depth_map, N)
    
    [H, W, ~] = size(depth_map);
    
    assert(all(size(es) == [H, W, N]),          'es 크기가 (H, W, N)이어야 합니다.');
    assert(all(size(ea) == [H, W, N]),          'ea 크기가 (H, W, N)이어야 합니다.');
    assert(all(size(depth_map) == [H, W, N]),   'depth_map 크기가 (H, W, N)이어야 합니다.');

    c = 3e8;

    corr = zeros(H, W, N);

    for n = 1:N
        psi_n = 2*pi*(n-1)/N;

        d   = depth_map(:,:,n);
        esn = es(:,:,n);
        ean = ea(:,:,n);

        cos_term = cos((4 * pi * f0 .* d) / c - psi_n);
        Cn = (T/2) * (esn + ean + 0.5 .* esn .* cos_term);

        corr(:,:,n) = Cn;
    end
end