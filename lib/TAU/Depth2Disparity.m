%Create by Harel Haim (Jan 2019)
% Create a disparity map from a stereo depth pair
%======================================================
% This script will create the following inside the 'left' folder:
% 'Disparity' - saved as a '.png' file using 'disparity_write.m' function from the Sintel dataset.
% 'DisparityVisual' - visual disparity images.
% 'Occlusions' - binary mask of pixels in the left image that are occluded from the right one.
% 'OutOfFrame' - binary mask of pixels in the left image that are outside the field of view of the right image.
%======================================================
%!!!!! make sure you have the following functions inside the same folder:
% depth_read.m
% depth_write.m
% disparity_read.m
% disparity_write.m

clear
dirname = cd;
addpath(dirname)

% folder name
scene_name = 'City'; 
scene_folder =  fullfile('Data',scene_name); % change this to your scene folder location


save_disp = 1; % save disparity map
save_vis = 1;% save '.png' files of the visual disparity maps
save_occ = 1; % save Occlusions map
save_oof = 1; % save out of frame map


% camera params
f = 24; %focal length in mm
sensor_w = 32; % sensor width in mm
num_of_pixels = 1024; % number of pixels in horizontal direction
pixel_sz = sensor_w/num_of_pixels; 
B = 100; % distance between the two sensors in mm

% image plane 
imSZ = [512, 1024];
cnt = floor(imSZ/2) +1 ;
offset = [0 0];
xi = -((1:imSZ(2)) - cnt(2) + offset(2));
yi = -((1:imSZ(1)) - cnt(1) + offset(1));

[Xi,Yi] = meshgrid(xi,yi);
Ri = pixel_sz * sqrt( Xi.^2 + Yi.^2 + (f/pixel_sz)^2);
f_Ri = f./Ri;

% left image pixel location;
pix_L = reshape(1:prod(imSZ),imSZ);


scene_folder_L = fullfile(scene_folder,strcat(scene_name,'_L'));
scene_folder_R = fullfile(scene_folder,strcat(scene_name,'_R'));

Depth_folder_L = fullfile(scene_folder_L,'Depth');
Depth_folder_R = fullfile(scene_folder_R,'Depth');
Depth_ext = 'dpt';

Disp_folder = fullfile(scene_folder_L,'Disparity');
Disp_ext = 'png';
vis_folder = fullfile(scene_folder_L,'DisparityVisual');
Occ_folder = fullfile(scene_folder_L,'Occlusions');
OOF_folder = fullfile(scene_folder_L,'OutOfFrame');

if ~isfolder(Disp_folder)
    mkdir(Disp_folder);
end
if ~isfolder(Occ_folder)
    mkdir(Occ_folder);
end
if ~isfolder(OOF_folder)
    mkdir(OOF_folder);
end
if ~isfolder(vis_folder)
    mkdir(vis_folder);
end


Frames_name = dir([Depth_folder_L,strcat('*/*.',Depth_ext)]);
Frames_name_R = dir([Depth_folder_R,strcat('*/*.',Depth_ext)]);

f_num = length(Frames_name);


for k = 1:f_num
%     file_namc = Frames_name(k).name;
    file_location = fullfile(Frames_name(k).folder,Frames_name(k).name);
    depth = 1e3 * depth_read( file_location );
    
    Z = depth .* f_Ri;
    Dis = f .* B ./ Z;
    % disparity in pixels
    Dis_px = Dis ./ pixel_sz; 
    
    % right camera depth map
    file_location_R = fullfile(Frames_name_R(k).folder,Frames_name_R(k).name);
    
     % check that file name match the left image
     name_R = strrep(Frames_name_R(k).name,'_R','');
     if ~strcmp(name_R,Frames_name(k).name)
         error(['right image name does not math left image name: ', name_R])
         break
     end
    
    depth_R = 1e3 * depth_read( file_location_R );
    Z_R = depth_R .* f_Ri;
    pix_map = pix_L - round(Dis_px) * imSZ(1);
    OutOfFrame_map = pix_map<1;
    pix_map(OutOfFrame_map) = 1;
    Z_R_t = Z_R(pix_map);
    Occlusions_map = double(abs(Z_R_t - Z)>10); % 
    Occlusions_map = Occlusions_map.* (1-OutOfFrame_map);
    
    
 % save disparity
     if save_disp
         map_location = fullfile(Disp_folder,Frames_name(k).name);
         map_location = strcat(map_location(1:end-length(Depth_ext)),Disp_ext); % replace extension
         disparity_write(map_location, Dis_px); % save disparity
     end
    % save Visual Disparity
    if save_vis
        Dis_px(Dis_px > num_of_pixels) = num_of_pixels;
        Dis_px = log10(Dis_px);
        Dis_px = (Dis_px-min(Dis_px(:)))./(max(Dis_px(:))-min(Dis_px(:)));
        map_location = fullfile(vis_folder,Frames_name(k).name);
        map_location = strcat(map_location(1:end-length(Depth_ext)),Disp_ext); % replace extension
        imwrite(Dis_px,map_location);
    end
    % save Occlusions map
     if save_occ
        map_location = fullfile(Occ_folder,Frames_name(k).name);
        map_location = strcat(map_location(1:end-length(Depth_ext)),Disp_ext); % replace extension
        imwrite(Occlusions_map,map_location);
     end
        % save Occlusions map
     if save_oof
        map_location = fullfile(OOF_folder,Frames_name(k).name);
        map_location = strcat(map_location(1:end-length(Depth_ext)),Disp_ext); % replace extension
        imwrite(OutOfFrame_map,map_location);
     end
    
end
