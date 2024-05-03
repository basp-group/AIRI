function [net_pth, scaling_factor, peakMin, peakMax] = get_net_detail(shelf_pth, heuristic, alpha)

% Try to find a network with noise level smaller and closest to heuristic noise level.
% If all the noise levels of networks in the shelf are above the heuristic noise level,
% the network with lowest noise level will be returned.

% shelf_pth : Path to a csv file where the noise level & path of the network are defined
%             The format of csv file is noise_level,net_path

% scaling_factor : Defined as noise level of choosen network divided by heuristic noise level

fprintf('\n\nSHELF *** Inverse of the estimated target dynamic range: %g', heuristic/alpha);

shelf = readtable(shelf_pth, 'Format', '%f%s', 'ReadVariableNames', false);
noise_list = shelf{:, 1};
if isempty(noise_list)
    error('\nSEVERE: DNN shelf file is empty !!\n');
end

peakMin = 0;
peakMax = 0;

sigma_s = max(noise_list(noise_list <= heuristic/alpha));
if isempty(sigma_s)
    [sigma_s, idx] = min(noise_list);
    peakMin = heuristic / sigma_s;
    peakMax = realmax("double");
else
    idx = find(noise_list == sigma_s);
    peakMax = heuristic / sigma_s;

    sigma_s1 = min(noise_list(noise_list > sigma_s));
    if ~isempty(sigma_s1)
        peakMin = heuristic / sigma_s1;
    end
end

net_pth = shelf{idx, 2}{1};
if ~isfile(net_pth)
    error('\nSEVERE: DNN file path not valid !!\n noise level:%f, path:%s \n', noise_list(idx), net_pth);
end

fprintf('\nSHELF *** Using network: %s', net_pth);
fprintf('\nSHELF *** Peak value is expected in range: [%g, %g]', peakMin, peakMax);

scaling_factor = heuristic / sigma_s;

fprintf('\nSHELF *** scaling factor applied to the image: %g', scaling_factor);

end