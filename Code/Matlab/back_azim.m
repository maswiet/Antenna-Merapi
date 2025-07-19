% Daftar stasiun dan koordinat
sta = {'RE5DE','R6940','R265F','R7D17','R0279'};
lat = [-7.69225, -7.69218, -7.69429, -7.69393, -7.69126];
lon = [110.43853, 110.44111, 110.43898, 110.44132, 110.44003];

% Parameter waktu event
evt_time = datetime(2023,9,5,18,33,29);   % UTC
duration = 60; % detik
thn = 2023;
doy = day(evt_time, 'dayofyear');

% Penampung data
data_all = cell(1, numel(sta));
t_event  = cell(1, numel(sta));

for i = 1:numel(sta)
    folder = sta{i};
    pattern = sprintf('AM.%s.00.EHZ.D.%04d.%03d*', sta{i}, thn, doy);
    filelist = dir(fullfile(folder, pattern));
    if isempty(filelist)
        fprintf('No miniseed file for %s: %s\n', sta{i}, pattern);
        data_all{i} = [];
        t_event{i} = [];
        continue
    end
    fname = fullfile(folder, filelist(1).name);

    % Baca miniseed
    X = rdmseed(fname);
    data = cat(1, X.d);
    t = cat(1, X.t);
    t_dt = datetime(t, 'ConvertFrom', 'datenum');

    % Ambil window event
    idx_event = t_dt >= evt_time & t_dt < (evt_time + seconds(duration));
    data_all{i} = data(idx_event);
    t_event{i}  = t_dt(idx_event);

    fprintf('%s: %d sample event\n', sta{i}, numel(data_all{i}));
end

% Plot overlay seismogram (offset antar stasiun)
figure; hold on
offset = 0;
for i = 1:numel(sta)
    if isempty(data_all{i}), continue; end
    plot(t_event{i}, data_all{i} + offset, 'k');
    offset = offset + max(abs(data_all{i}))*2;
end
xlabel('Waktu');
ylabel('Amplitudo (offset)');
title('Seismogram 5 Stasiun: Event 5 September 2023 18:33:29');
legend(sta, 'Location','northeast');
datetick('x','HH:MM:SS','keeplimits')

% Koordinat array
sta = {'RE5DE','R6940','R265F','R7D17','R0279'};
lat_sta = [-7.69225, -7.69218, -7.69429, -7.69393, -7.69126];
lon_sta = [110.43853, 110.44111, 110.43898, 110.44132, 110.44003];

% Episenter gempa
lat_epi = -8.60;
lon_epi = 111.06;

% Pusat array
lat0 = mean(lat_sta); lon0 = mean(lon_sta);
[dx, dy] = latlon2xy(lat_sta, lon_sta, lat0, lon0); % meter

% Vektor episenter relatif pusat array (untuk validasi azimuth)
[dxe, dye] = latlon2xy(lat_epi, lon_epi, lat0, lon0);
az_true = atan2d(dxe, dye); 
if az_true<0, az_true = az_true+360; end
fprintf('Azimuth pusat array ke episenter: %.1f deg\n', az_true);

% Ambil window event dari data_all
idx_valid = find(~cellfun(@isempty, data_all));
Nsta = numel(idx_valid);
Nsam = min(cellfun(@numel, data_all(idx_valid)));

% Susun matriks array
data_matrix = zeros(Nsta, Nsam);
for i = 1:Nsta
    data_matrix(i,:) = data_all{idx_valid(i)}(1:Nsam);
end
fs = 1/seconds(median(diff(t_event{idx_valid(1)})));

% Parameter FK
slmax = 1; ns = 100;
ux = linspace(-slmax, slmax, ns); uy = linspace(-slmax, slmax, ns);
f_target = 5; omega = 2*pi*f_target;

% FFT per stasiun
FFT_data = fft(data_matrix, [], 2);
freq = (0:Nsam-1)*fs/Nsam;
[~, idx_f] = min(abs(freq-f_target));
Xf = FFT_data(:, idx_f);

Pfk = zeros(ns, ns);
for ix = 1:ns
    for iy = 1:ns
        slx = ux(ix); sly = uy(iy);
        delay = (slx*dx(idx_valid) + sly*dy(idx_valid))/1000;
        steering = exp(-1i*omega*delay(:));
        Pfk(ix,iy) = abs(sum(Xf .* conj(steering)))^2;
    end
end

% --- Plot FK spectrum (dengan grid, pusat, dan azimuth) ---
figure;
imagesc(ux, uy, Pfk'); axis xy; hold on; colorbar;
xlabel('Slowness X (s/km)');
ylabel('Slowness Y (s/km)');
title('FK Spectrum');

% Grid putih
xt = ux(1:10:end); yt = uy(1:10:end);
for i = 1:length(xt)
    plot([xt(i) xt(i)], [uy(1) uy(end)], 'w:', 'LineWidth', 0.5)
end
for i = 1:length(yt)
    plot([ux(1) ux(end)], [yt(i) yt(i)], 'w:', 'LineWidth', 0.5)
end

% Pusat array (slowness=0,0)
plot(0, 0, 'yo', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'y');

% Puncak FK
[maxval, idx_max] = max(Pfk(:));
[ix_max, iy_max] = ind2sub(size(Pfk), idx_max);
sx_est = ux(ix_max); sy_est = uy(iy_max);
s_est = sqrt(sx_est^2 + sy_est^2);
az_est = atan2d(sx_est, sy_est); if az_est<0, az_est=az_est+360; end

% Garis hasil beamforming (arah array)
plot([0 sx_est], [0 sy_est], 'r-', 'LineWidth', 2);
plot(sx_est, sy_est, 'rp', 'MarkerSize',12,'MarkerFaceColor','r');
text(sx_est, sy_est, sprintf(' \\leftarrow Peak (%.2f, %.2f)', sx_est, sy_est), ...
    'Color','r','FontWeight','bold','HorizontalAlignment','left');

% Garis hasil teoritik (arah ke episenter)
s_true = 0.75; % 1/4 Perkiraan slowness, misal 6 km/s (ganti sesuai model crust)
sx_true = s_true * sind(az_true); sy_true = s_true * cosd(az_true);
plot([0 sx_true], [0 sy_true], 'g--', 'LineWidth', 2);
plot(sx_true, sy_true, 'gp', 'MarkerSize',10,'MarkerFaceColor','g');
text(sx_true, sy_true, sprintf(' \\leftarrow Theory azimuth (%.1f)', az_true), ...
    'Color','g','FontWeight','bold','HorizontalAlignment','left');

hold off;

fprintf('Estimasi hasil array:\n');
fprintf('  Backazimuth = %.1f deg, Slowness = %.3f s/km\n', az_est, s_est);
fprintf('Teoritis dari pusat ke episenter:\n');
fprintf('  Azimuth = %.1f deg, Slowness input (asumsi Vp=6 km/s) = %.3f s/km\n', az_true, s_true);

% --- Fungsi pembantu latlon2xy ---
function [dx, dy] = latlon2xy(lat, lon, lat0, lon0)
    R = 6371000; % m
    dlat = deg2rad(lat - lat0);
    dlon = deg2rad(lon - lon0);
    dx = R * dlon .* cos(deg2rad(lat0));
    dy = R * dlat;
end
