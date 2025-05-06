%240505
clear;
clc;
run('itof_sim_param_motion.m');
close all;

%CalcParams
f0          = SimParams.ModulationFreq;
T0          = 1/f0;
T           = SimParams.IntegrationTime;
Beta        = SimParams.SensorBeta;
AlphaScale  = SimParams.AlphaScale;
Pa          = SimParams.Pa;
Ps          = SimParams.Ps;
N           = SimParams.PhaseShiftNum;
StartIdx    = SimConfig.CaptureStartIdx;

%Load Library
addpath(fullfile(fileparts(mfilename('fullpath')), Directory.Library));

%Load files and generate ALBEDO map / Depth mat array
dpt_files = dir(fullfile(fileparts(mfilename('fullpath')), Directory.Res.Depth,'*.dpt'));
rgb_files = dir(fullfile(fileparts(mfilename('fullpath')), Directory.Res.RGB,'*.tif'));

n = length(dpt_files);

albedo_rawlist = cell(1, n);
dpt_rawlist = cell(1, n);

set_maxcnt  = floor(n / N);
set_cnt     = floor((n - StartIdx + 1) / N);
set_list    = cell(1, set_cnt); % Max size of Sets

for i = 1:length(dpt_files)
    dpt_file_path = fullfile(dpt_files(i).folder, dpt_files(i).name);
    rgb_file_path = fullfile(rgb_files(i).folder, rgb_files(i).name);

    temp_albedo = itof_rgb2albedo(rgb_file_path);
    temp_depth = depth_read(dpt_file_path);

    albedo_rawlist{i} = temp_albedo;
    dpt_rawlist{i} = temp_depth;
end

%whos dpt_rawlist;
%whos albedo_rawlist;

%Calc Corr Map
corr_map_n  = cell(1, N);
depth_est   = cell(1, N);
inten_est   = cell(1, N);

for i = 1:set_cnt
    frameidx        = StartIdx;
    albedo_map      = cell(1, N);
    depth_map_c     = cell(1, N);  % cell 형태 유지
    alpha_map       = cell(1, N);
    
    for j = 1:N
        albedo_map{j}   = albedo_rawlist{frameidx};
        depth_map_c{j}  = dpt_rawlist{frameidx};
        
        alpha_map{j}    = albedo_map{j} * 5e7;
        
        frameidx = frameidx + 1;
    end
    
    % 배열 크기 추정
    [H, W] = size(alpha_map{1});
    
    % es, ea, depth_map을 3D 배열로 생성
    es = zeros(H, W, N);
    ea = zeros(H, W, N);
    depth_map = zeros(H, W, N);
    
    for j = 1:N
        es(:, :, j)         = alpha_map{j} * AlphaScale * Beta * Ps;
        ea(:, :, j)         = ones(H, W) * (Beta * Pa);
        depth_map(:, :, j)  = depth_map_c{j};
    end

    % 이후 계산
    cm = itof_corr_motion(T, f0, es, ea, depth_map, N);
    
    corr_map_n{i} = cm;
    depth_est{i} = itof_depth_est_from_corr(cm, f0, N);
    inten_est{i} = itof_inten_est_from_corr(cm, N);
end
% Calc depth_est, inten_est



%whos depth_est;
%whos inten_est;



flowModel = opticalFlowRAFT;

reset(flowModel);

%for i = 1:n
%
%    rgb_img = imread(fullfile(rgb_files(i).folder, rgb_files(i).name));
%    img = im2single(rgb_img);            
%    flow = estimateFlow(flowModel, img);
%    
%    if (i > 5 && i < 10)
%    imshow(img);
%    hold on;
%    plot(flow, DecimationFactor=[10 10], ScaleFactor=0.45);
%    hold off;
%    end
%
%end


% 첫 프레임 준비
rgb_img_prev = im2single(imread(fullfile(rgb_files(1).folder, rgb_files(1).name)));
dummy = estimateFlow(flowModel, rgb_img_prev);

for i = 2:n
    rgb_img = im2single(imread(fullfile(rgb_files(i).folder, rgb_files(i).name)));
    
    flow = estimateFlow(flowModel, rgb_img);

    [H, W, ~] = size(rgb_img);
    [X, Y] = meshgrid(1:W, 1:H);

    Xq = X + flow.Vx;
    Yq = Y + flow.Vy;

    compensated = zeros(size(rgb_img), 'like', rgb_img);
    for c = 1:3
        compensated(:,:,c) = interp2(X, Y, rgb_img(:,:,c), Xq, Yq, 'linear', 0);
    end

    error_map = abs(compensated - rgb_img_prev);
    error_gray = mean(error_map, 3); 

    figure('Name', sprintf('Frame %d - Prev', i));
    imshow(rgb_img_prev);
    title(sprintf('Previous Frame (%d)', i-1));

    figure('Name', sprintf('Frame %d - Current', i));
    imshow(rgb_img);
    title(sprintf('Current Frame (%d)', i));

    figure('Name', sprintf('Frame %d - Motion Compensated', i));
    imshow(compensated);
    title(sprintf('Motion Compensated Frame (%d)', i));

    figure('Name', sprintf('Frame %d - Error Map', i));
    imagesc(error_gray);
    axis image off;
    colormap('hot');
    colorbar;
    title(sprintf('Error |Compensated - Prev| (Frame %d)', i));

    figure('Name', sprintf('Frame %d - Flow (on Current)', i));
    imshow(rgb_img); hold on;
    plot(flow, 'DecimationFactor', [10 10], 'ScaleFactor', 0.45);
    title(sprintf('Optical Flow (Frame %d)', i));
    hold off;

    rgb_img_prev = rgb_img;

    break;
end

reset(flowModel);



%Simulation result : Correlation Show
i = 1;
raw = StartIdx;
cm = corr_map_n{i};
rgb_img = imread(fullfile(rgb_files(raw).folder, rgb_files(raw).name));
depth_map = dpt_rawlist{raw};
N = size(cm, 3);

% 1. RGB
figure;
imshow(rgb_img);
title(sprintf('RGB Image (Frame %d)', raw));

% 2. Raw Depth Map
figure;
imagesc(depth_map);
axis image off;
colormap('gray');
colorbar;
title(sprintf('Raw Depth Map (Frame %d)', raw));

cm = corr_map_n{i};
figure;
for n_idx = 1:N
    subplot(1, N, n_idx);
    imagesc(cm(:, :, n_idx));  % <-- 수정된 부분
    axis image off;
    colormap('gray');
    title(sprintf('n = %d', n_idx));
end
sgtitle(sprintf('Correlation Maps (Frame %d)', i));




%Simulation result : Estimmated Show

est_depth_map = depth_est{i};     
est_inten_map = inten_est{i};     
real_depth_map = dpt_rawlist{raw};  

% 1. Estimated Depth
figure;
imagesc(est_depth_map);
axis image off;
colormap('gray');
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

