function depth_est = itof_depth_est_from_corr(corr_map, f0, N)
    
        c = 3e8;
        Csp = 0;
        Ccp = 0;
    
        for n = 1:N
            psi_n = 2 * pi * (n - 1) / N;
    
            Cs = corr_map(:,:,n) * sin(psi_n);
            Csp = Csp + Cs;
    
            Cc = corr_map(:,:,n) * cos(psi_n);
            Ccp = Ccp + Cc;
        end
    
        phi = atan2(Csp, Ccp);
        phi = mod(phi, 2*pi);
    
        depth_est = (c / (4 * pi * f0)) * phi;
    end
    