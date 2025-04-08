run('itof_sim_param.m');

%CalcParams
f0 = ModulationFreq;
T0 = 1/f0;

%Load Library
addpath(fullfile(fileparts(mfilename('fullpath')), Directory.Library));
dpt_files = dir(fullfile(fileparts(mfilename('fullpath')), Directory.Res.Depth,'*.dpt'));
rgb_files = dir(fullfile(fileparts(mfilename('fullpath')), Directory.Res.RGB,'*.tif'));

n = length(dpt_files);

dpt_rawlist = cell(1, n);
rgb_rawlist = cell(1, n);


parfor i = 1:length(dpt_files)
    file_path = fullfile(dpt_files(i).folder, dpt_files(i).name);

    disp(['Opened file: ', file_path]);
    test = depth_read(file_path);

    dpt_rawlist{i} = test;
end
%disp(dpt_rawlist);

%whos dpt_rawlist;
temp = dpt_rawlist{1};
whos temp;
%disp(temp(1:20,1:20))

fp = fullfile(dpt_files(1).folder, dpt_files(1).name);

dm = depth_read(fp);

es = 5e7;         
ea = 0.5 * es;    
T = 2e-3;         

cm = itof_corr(T,f0,es,ea,dm,4);
whos cm
cm0 = cm(:,:,1);
whos cm0
disp(cm0(1:10,1:10));