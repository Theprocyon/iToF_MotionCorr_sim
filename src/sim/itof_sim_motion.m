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
frameidx    = StartIdx;

for i = 1:set_cnt
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


%Simulation result : Correlation Show
i = 1;
raw = StartIdx;
cm = corr_map_n{i};
int_img = imread(fullfile(rgb_files(raw).folder, rgb_files(raw).name));
depth_map = dpt_rawlist{raw};
N = size(cm, 3);

%% 1. RGB
%figure;
%imshow(int_img);
%title(sprintf('RGB Image (Frame %d)', raw));%

%% 2. Raw Depth Map
%figure;
%imagesc(depth_map);
%axis image off;
%colormap('gray');
%colorbar;
%title(sprintf('Raw Depth Map (Frame %d)', raw));

cm = corr_map_n{1};
figure;
for n_idx = 1:N
    subplot(2, 2, n_idx); 
    imagesc(cm(:, :, n_idx));
    axis image off;
    colormap('gray');
    title(sprintf('n = %d', n_idx));
end
sgtitle(sprintf('Correlation Maps (Frame %d)', i));




%%Simulation result : Estimmated Show
%
%est_depth_map = depth_est{i};     
%est_inten_map = inten_est{i};     
%real_depth_map = dpt_rawlist{raw};  
%
%% 1. Estimated Depth
%figure;
%imagesc(est_depth_map);
%axis image off;
%colormap('gray');
%colorbar;
%title(sprintf('Estimated Depth (Frame %d)', i));
%
%% 2. Estimated Intensity
%figure;
%imagesc(est_inten_map);
%axis image off;
%colormap('gray');
%colorbar;
%title(sprintf('Estimated Intensity (Frame %d)', i));
%
%% 3. Difference from GT Depth
%figure;
%diff_map = abs(est_depth_map - real_depth_map);
%imagesc(diff_map);
%axis image off;
%colormap('hot');
%colorbar;
%title(sprintf('Depth Error (|Est - GT|) Frame %d', i));




%MotionCorr
flowModel = opticalFlowRAFT;

int_img = inten_est{1};
int_img = (int_img - min(int_img(:))) / (max(int_img(:)) - min(int_img(:)));
int_img = min(max(int_img, 0), 1);

dummy = estimateFlow(flowModel, int_img);

compensated = cell(1, length(inten_est) - 1);

for i = 2:length(inten_est)
    int_img = inten_est{i};
    int_img = (int_img - min(int_img(:))) / (max(int_img(:)) - min(int_img(:)));
    int_img = min(max(int_img, 0), 1);

    flow = estimateFlow(flowModel, int_img);

    if i == 2
        asdf = int_img;
        figure;
        imagesc(asdf); 
        axis image off;
        colormap('gray'); colorbar;
        hold on;
        plot(flow, 'DecimationFactor', [10 10], 'ScaleFactor', 1.0);
        title('Optical Flow on inten (Frame 2)');
        hold off;
    end

    [H, W] = size(int_img);
    [X, Y] = meshgrid(1:W, 1:H);

    Xq = X + flow.Vx;
    Yq = Y + flow.Vy;

    compensated{i - 1} = interp2(X, Y, inten_est{i}, Xq, Yq, 'linear', 0);

    break;
end

Set1_inten = inten_est{1};        
Set2_inten = inten_est{2};        
comp_inten = compensated{1};      
% 1. 기준 프레임
figure;
imagesc(Set1_inten);
axis image off; colormap('gray'); colorbar;
title('Prev (Frame 1)');

% 2. 보정 전 현재 프레임
figure;
imagesc(Set2_inten);
axis image off; colormap('gray'); colorbar;
title('Current (Frame 2) Before Warp');

% 3. 보정된 프레임
figure;
imagesc(comp_inten);
axis image off; colormap('gray'); colorbar;
title('Warped (Frame 2 → Frame 1)');

% 4. 에러맵 시각화
figure;
imagesc(abs(comp_inten - Set1_inten));
axis image off; colormap('hot'); colorbar;
title('|Warped - Prev| Error Map');

reset(flowModel);