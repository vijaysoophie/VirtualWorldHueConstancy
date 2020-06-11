function makeReflectanceForExperiment(standard, comparision1, comparision2, folderToStore)
% makeReflectanceForExperiment(standard,comparision1, comparision2, folderToStore)
%
% Usage: 
%     makeReflectanceForExperiment([0.2 0.4] ,[0.3 0.6], [0.1 0.4], 'ExampleFolderName')
%
% Description:
%     This function generates target object reflectances for the
%     psychophysics experiment. It generates one set of standard
%     reflectance spectra and two set of comparison reflectnace spectra.
%     The luminance levels at which the spectra the spectra are generated
%     is provided as the input.
%
%    The spectrum are generated using the nickerson and the 
%    vrhel libraries. These libraries should be a part of
%    RenderToolbox. To generate the spectra, we first find out the pricipal
%    components of the spectra in the library. Then we choose the
%    directions corresponding to the largest six eigenvalues. We project
%    the spectra along these six directions and find out the mean and the
%    variance of this distribution. These are then used along with a
%    multinormal random distribution to generate new random spectra. The
%    new spectra are scaled such that the luminance equals the desired
%    luminance levels. Finally, we make sure that the reflectance spectra 
%    values are between 0 and 1 at all frequencies.
%
% Input:
%   standard = luminance level values of standard spectra
%   comparision1 = luminance level values of comparison 1 spectra
%   comparision2 = luminance level values of comparison 2 spectra
%   folderToStore = folder where the spectra should be stored
%
%
% 7/28/17  VS Wrote it.

% Desired wl sampling
S = [400 5 61];
theWavelengths = SToWls(S);

%% Load surfaces
%
% These are in the Psychtoolbox.

% Munsell surfaces
load sur_nickerson
sur_nickerson = SplineSrf(S_nickerson,sur_nickerson,S);

% Vhrel surfaces
load sur_vrhel 
sur_vrhel = SplineSrf(S_vrhel,sur_vrhel,S);

% Put them together
sur_all = [sur_nickerson sur_vrhel];

sur_mean=mean(sur_all,2);
sur_all_mean_centered = bsxfun(@minus,sur_all,sur_mean);

%% Analyze with respect to a linear model
B = FindLinMod(sur_all_mean_centered,6);
sur_all_wgts = B\sur_all_mean_centered;
mean_wgts = mean(sur_all_wgts,2);
cov_wgts = cov(sur_all_wgts');

%% Load in spectral weighting function for luminance
% This is the 1931 CIE standard
theXYZData = load('T_xyz1931');
theLuminanceSensitivity = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931(2,:),theWavelengths);

%% Load in a standard daylight as our reference spectrum
%
% We'll scale this so that it has a luminance of 1, to help us think
% clearly about the scale of reference luminances we are interested in
% studying.
theIlluminantData = load('spd_D65');
theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
theIlluminant = theIlluminant/(theLuminanceSensitivity*theIlluminant);

%% Generate standard surfaces
newSurfaces = zeros(S(3),length(standard));
newIndex = 1;

if ~exist(folderToStore)
    mkdir(folderToStore);
end

for i = 1:length(standard)
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        theReflectance = B*ran_wgts+sur_mean;
        theLightToEye = theIlluminant.*theReflectance;
        theLuminance = theLuminanceSensitivity*theLightToEye;
        theLuminanceTarget = standard(i);
        scaleFactor = theLuminanceTarget / theLuminance;
        theReflectanceScaled = scaleFactor * theReflectance;
        if (all(theReflectanceScaled >= 0) & all(theReflectanceScaled <= 1))
            newSurfaces(:,newIndex) = theReflectanceScaled;
            newIndex = newIndex+1;
            OK = true;
        end
    end
    reflectanceName = sprintf('standard-%03d.spd',i);
    fid = fopen(fullfile(folderToStore,reflectanceName),'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,theReflectanceScaled]');
    fclose(fid);
end

%%
for i = 1:length(comparision1)
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        theReflectance = B*ran_wgts+sur_mean;
        theLightToEye = theIlluminant.*theReflectance;
        theLuminance = theLuminanceSensitivity*theLightToEye;
        theLuminanceTarget = comparision1(i);
        scaleFactor = theLuminanceTarget / theLuminance;
        theReflectanceScaled = scaleFactor * theReflectance;
        if (all(theReflectanceScaled >= 0) & all(theReflectanceScaled <= 1))
            newSurfaces(:,newIndex) = theReflectanceScaled;
            newIndex = newIndex+1;
            OK = true;
        end
    end
    reflectanceName = sprintf('comparision1-%03d.spd',i);
    fid = fopen(fullfile(folderToStore,reflectanceName),'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,theReflectanceScaled]');
    fclose(fid);
end

%%
for i = 1:length(comparision2)
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        theReflectance = B*ran_wgts+sur_mean;
        theLightToEye = theIlluminant.*theReflectance;
        theLuminance = theLuminanceSensitivity*theLightToEye;
        theLuminanceTarget = comparision2(i);
        scaleFactor = theLuminanceTarget / theLuminance;
        theReflectanceScaled = scaleFactor * theReflectance;
        if (all(theReflectanceScaled >= 0) & all(theReflectanceScaled <= 1))
            newSurfaces(:,newIndex) = theReflectanceScaled;
            newIndex = newIndex+1;
            OK = true;
        end
    end
    reflectanceName = sprintf('comparision2-%03d.spd',i);
    fid = fopen(fullfile(folderToStore,reflectanceName),'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,theReflectanceScaled]');
    fclose(fid);
end
