run('itof_sim_param.m');

%CalcParams
f0          = SimParams.ModulationFreq;
T0          = 1/f0;
T           = SimParams.IntegrationTime;
Beta        = SimParams.SensorBeta;
AlphaScale  = SimParams.AlphaScale;
Pa          = SimParams.Pa;
Ps          = SimParams.Ps;
N           = SimParams.PhaseShiftNum;

%Load Library
addpath(fullfile(fileparts(mfilename('fullpath')), Directory.Library));

%Load files and generate ALBEDO map / Depth mat array
dpt_files = dir(fullfile(fileparts(mfilename('fullpath')), Directory.Res.Depth,'*.dpt'));
rgb_files = dir(fullfile(fileparts(mfilename('fullpath')), Directory.Res.RGB,'*.tif'));

n = length(dpt_files);

dpt_rawlist = cell(1, n);
albedo_rawlist = cell(1, n);


parfor i = 1:length(dpt_files)
    dpt_file_path = fullfile(dpt_files(i).folder, dpt_files(i).name);
    rgb_file_path = fullfile(rgb_files(i).folder, rgb_files(i).name);

    temp_albedo = itof_rgb2albedo(rgb_file_path);
    temp_depth = depth_read(dpt_file_path);

    albedo_rawlist{i} = temp_albedo;
    dpt_rawlist{i} = temp_depth;
end

whos dpt_rawlist;
whos albedo_rawlist;

proc_flags = false(1, n);

if SimConfig.SingleFrameMode == 1 %Single frame mode의 경우 한 프레임만 출력
    target_frame_idx = SimConfig.SingleFrameModeTargetFrameIdx;
    proc_flags(target_frame_idx) = true;
else
    proc_flags(:) = true;  % 
end



%Calc Corr Map
corr_map_n = cell(1, n);

parfor i = 1:n
    if ~proc_flags(i)
        continue;   %to Skip unwanted frames
    end

    albedo_map = albedo_rawlist{i};
    depth_map = dpt_rawlist{i};

    alpha_map = albedo_map * 5e7;

    es = alpha_map * AlphaScale * Beta * Ps;
    ea = ones(size(alpha_map)) * (Beta * Pa);

    cm = itof_corr(T,f0,es,ea,depth_map,N);

    corr_map_n{i} = cm;
end

% Calc depth_est, inten_est

depth_est = itof_depth_est_from_corr(corr_map_n);
inten_est = itof_inten_est_from_corr(corr_map_n);


%Simulation result : Correlation Show

if SimConfig.SingleFrameMode == 1  % Show Single Frame image and Corr map
    i = SimConfig.SingleFrameModeTargetFrameIdx;
    cm = corr_map_n{i};            % Correlation map (HxWxN)
    rgb_img = imread(fullfile(rgb_files(i).folder, rgb_files(i).name));
    depth_map = dpt_rawlist{i};
    N = size(cm, 3);

    figure;

    % 1. RGB 
    subplot(3, N, 1);
    imshow(rgb_img);
    title('RGB Image');

    % 2. Depth Map
    subplot(3, N, N+1);
    imagesc(depth_map);
    axis image off;
    colormap('turbo');
    colorbar;
    title('Raw Depth');

    % 3. Correlation Map (n = 1~N)
    for n_idx = 1:N
        subplot(3, N, 2*N + n_idx);
        imshow(cm(:,:,n_idx), []);
        colormap('gray');
        title(sprintf('n = %d', n_idx));
    end

    sgtitle(sprintf('Frame %d Summary View', i));
end

%Simulation result : Estimmated Show

if SimConfig.SingleFrameMode == 1
    i = SimConfig.SingleFrameModeTargetFrameIdx;

    est_depth_map = depth_est{i};     
    est_inten_map = inten_est{i};     
    real_depth_map = dpt_rawlist{i};  

    % 1. Estimated Depth
    figure;
    imagesc(est_depth_map);
    axis image off;
    colormap('turbo');
    colorbar;
    title(sprintf('Estimated Depth (Frame %d)', i));

    % 2. Estimated Intensity
    figure;
    imagesc(est_inten_map);
    axis image off;
    colormap('gray');
    colorbar;
    title(sprintf('Estimated Intensity (Frame %d)', i));

    % 3. Difference from GT Depth
    figure;
    diff_map = abs(est_depth_map - real_depth_map);
    imagesc(diff_map);
    axis image off;
    colormap('hot');
    colorbar;
    title(sprintf('Depth Error (|Est - GT|) Frame %d', i));
end