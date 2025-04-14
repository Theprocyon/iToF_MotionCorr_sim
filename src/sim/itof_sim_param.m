Directory.Library = '../../lib/TAU/';
Directory.Res.Depth = '../../resources/City_L/Depth/';
Directory.Res.RGB = '../../resources/City_L/Images/';

SimConfig.SingleFrameMode = 1;
SimConfig.SingleFrameModeTargetFrameIdx = 100;

SimParams.ModulationFreq    = 10e6; %1MHz
SimParams.IntegrationTime   = 2e-3;
SimParams.SensorBeta        = 1.0; %Sensor Dependent  Scale factor, Considering Gain / Sensitivity
SimParams.AlphaScale        = 1.0; %scale factor encapsulating light fall-off, scene albedo, and reflectance properties
SimParams.Pa                = 0.1; % 빛 많은 환경은 0.1~0.3 정도라고 함
SimParams.Ps                = 1; %Source Power
SimParams.PhaseShiftNum     = 4; % N