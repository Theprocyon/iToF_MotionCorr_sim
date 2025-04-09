function inten_est = itof_inten_est_from_corr(corr_map_n)
    % ITOF_INTEN_EST_FROM_CORR Estimate intensity from correlation images
    %   corr_map_n: cell array where each cell is HxWxN correlation map
    
        inten_est = cell(size(corr_map_n));
        
        for i = 1:length(corr_map_n)
            cm = corr_map_n{i};  % H x W x N
            [~, ~, N] = size(cm);
            psi = 2 * pi * (0:N-1) / N;
            
            % Precompute sin/cos phase terms
            sin_psi = reshape(sin(psi), 1, 1, []);
            cos_psi = reshape(cos(psi), 1, 1, []);
            
            % Compute intensity estimate (magnitude of vector)
            sum_sin = sum(cm .* sin_psi, 3);
            sum_cos = sum(cm .* cos_psi, 3);
            
            inten = sqrt(sum_sin.^2 + sum_cos.^2) / N;
            inten_est{i} = inten;
        end
    end