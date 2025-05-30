function inten_est = itof_inten_est_from_corr(corr_map, N)
    Csp = 0;
    Ccp = 0;

    for n = 1:N
        psi_n = 2 * pi * (n - 1) / N;

        Cs = corr_map(:,:,n) * sin(psi_n);
        Csp = Csp + Cs;

        Cc = corr_map(:,:,n) * cos(psi_n);
        Ccp = Ccp + Cc;
    end

    inten_est = (1/N) * sqrt(Ccp.^2 + Csp.^2);
end