function depth_est = itof_depth_est_from_corr(itof_corr,f0,N)
    c = 3e8;
    Csp=0;
    Ccp=0;
     for n = 1:N
         psi_n=2*pi*(n-1)/N;
    
        Cs = itof_corr(:,:,N) * sin(psi_n);
        Csp= Csp+Cs;
     
        Cc = itof_corr(:,:,N) * cos(psi_n);
        Ccp= Ccp+Cc;
     end
    
     depth_est= c/(4 * pi * f0) * atan(Csp/Ccp);
    end