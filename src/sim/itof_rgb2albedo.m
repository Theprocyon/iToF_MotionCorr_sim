function albedo = itof_rgb2albedo(filename)
% itof_rgb2albedo - Reads an RGB tif image and converts it to a normalized albedo map (0~1)
%   albedo = itof_rgb2albedo(filename)
%
%   Input:
%       filename - Path to the RGB tif image file
%
%   Output:
%       albedo - 2D grayscale array normalized between 0 and 1
%
%   Programmed by hyeonseok 🦊

    if isempty(filename) == 1
        error('depth_read: empty filename');
    end

    rgb_frame = imread(filename);

    bitDepth = class(rgb_frame);

    grayImage = rgb2gray(rgb_frame);

    switch bitDepth
        case 'uint8'
            albedo = double(grayImage) / 255;
        case 'uint16'
            albedo = double(grayImage) / 65535;
        case {'single', 'double'}
            albedo = min(max(double(grayImage), 0), 1);
        otherwise
            error('지원하지 않는 이미지 데이터 타입입니다: %s', bitDepth);
    end

