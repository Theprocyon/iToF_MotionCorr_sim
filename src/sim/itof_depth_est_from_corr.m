function depth_est = itof_depth_est_from_corr(corr_map_n, f0)
    % ITOF_DEPTH_EST_FROM_CORR Estimate depth from correlation images
    %   Uses N-phase correlation to estimate depth for each frame
    %   corr_map_n: cell array where each cell is HxWxN correlation map
    
        c = 3e8;  % speed of light
        depth_est = cell(size(corr_map_n));
        
        for i = 1:length(corr_map_n)
            cm = corr_map_n{i};  % H x W x N
            [H, W, N] = size(cm);
            psi = 2 * pi * (0:N-1) / N;
            
            % Precompute sin/cos phase terms
            sin_psi = reshape(sin(psi), 1, 1, []);
            cos_psi = reshape(cos(psi), 1, 1, []);
            
            % Compute depth using arctangent formula
            sum_sin = sum(cm .* sin_psi, 3);
            sum_cos = sum(cm .* cos_psi, 3);
            
            phi = atan2(sum_sin, sum_cos);  % Phase angle
            phi(phi < 0) = phi(phi < 0) + 2*pi;  % Wrap to [0, 2pi]
            
            % Estimate depth
            depth = (c / (4 * pi * f0)) * phi;
            
            depth_est{i} = depth;
        end
    end