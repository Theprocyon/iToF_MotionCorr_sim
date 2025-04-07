run('itof_sim_param.m');

%Load Library
addpath(fullfile(fileparts(mfilename('fullpath')), Directory.Library));
dpt_files = dir(fullfile(fileparts(mfilename('fullpath')), Directory.Res.Depth,'*.dpt'));
rgb_files = dir(fullfile(fileparts(mfilename('fullpath')), Directory.Res.RGB,'*.tif'));

n = length(dpt_files);
dpt_rawlist = cell(1, n);
rgb_rawlist = cell(1, n);

parfor i = 1:length(dpt_files)
    file_path = fullfile(dpt_files(i).folder, dpt_files(i).name);

    disp(['열고 있는 파일: ', file_path]);
    test = depth_read(file_path);

    dpt_rawlist{i} = test;
end

disp(dpt_rawlist);