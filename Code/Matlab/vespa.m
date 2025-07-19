% -- Setup array & data event --
sta = {'RE5DE','R6940','R265F','R7D17','R0279'};
lat = [-7.69225, -7.69218, -7.69429, -7.69393, -7.69126];
lon = [110.43853, 110.44111, 110.43898, 110.44132, 110.44003];
lat0 = mean(lat); lon0 = mean(lon);
[dx, dy] = latlon2xy(lat, lon, lat0, lon0);

idx_valid = find(~cellfun(@isempty, data_all));
Nsta = numel(idx_valid);
Nsam = min(cellfun(@numel, data_all(idx_valid)));
data_matrix = zeros(Nsta, Nsam);
for i = 1:Nsta
    data_matrix(i,:) = data_all{idx_valid(i)}(1:Nsam);
end
fs = 1/seconds(median(diff(t_event{idx_valid(1)})));

% --- Vespagram parameter ---
t_win = 6;      % durasi window (detik)
t_step = 1.0;   % langkah window (detik)
wlen = round(t_win*fs);
wstep = round(t_step*fs);
nwin = floor((Nsam-wlen)/wstep)+1;

sl_grid = linspace(0.1,2,80);   % grid slowness (s/km)
theta = atan2d(mean(dx), mean(dy)); % arah datang diambil ke arah rata-rata array (atau set manual)
tvespa = NaT(nwin,1);
VESPA = zeros(numel(sl_grid), nwin);

for iw = 1:nwin
    idx = (1:wlen) + (iw-1)*wstep;
    seg = data_matrix(:, idx);
    tvespa(iw) = t_event{idx_valid(1)}(idx(round(end/2)));

    for is = 1:numel(sl_grid)
        s = sl_grid(is);
        % Arah beam (pilih sesuai minat, atau ulangi untuk banyak azimuth)
        az = theta;  % bisa juga sweep azimuth jika ingin vespagram 2D
        sx = s * sind(az);
        sy = s * cosd(az);
        % Delay tiap stasiun
        delay = (sx*dx(idx_valid) + sy*dy(idx_valid))/1000; % s/km * m -> s
        % Interpolasi dan stack
        stack = zeros(1, wlen);
        for n = 1:Nsta
            t_shift = ((1:wlen)/fs) - delay(n); % waktu t - delay
            stack = stack + interp1((1:wlen)/fs, seg(n,:), t_shift, 'linear', 0);
        end
        % Simpan power (RMS stack, atau max abs)
        VESPA(is, iw) = rms(stack);  % bisa juga max(abs(stack)) atau energy
    end
end

% --- Plot Vespagram ---
figure;
imagesc(datenum(tvespa), sl_grid, VESPA);
axis xy; colorbar;
xlabel('Time (UTC)'); ylabel('Slowness (s/km)');
datetick('x','HH:MM:SS','keeplimits');
title('Vespagram (time-slowness, delay-and-sum)');
set(gca, 'YDir','normal');

figure;

% --- Plot 1: Seismogram array ---
subplot(2,1,1)
offset = 0;
for i = 1:Nsta
    trace = data_matrix(i,:) / max(abs(data_matrix(i,:)));  % normalisasi
    plot(tvespa(1) + seconds((0:Nsam-1)/fs), trace + offset, 'k');
    hold on
    offset = offset + 2; % offset antar stasiun
end
xlabel('Time (UTC)');
ylabel('Trace + offset');
title('Seismogram Array (normalized, offset)');
datetick('x','HH:MM:SS','keeplimits')
set(gca,'XLim',[tvespa(1), tvespa(end)]);

% --- Plot 2: Vespagram ---
subplot(2,1,2)
imagesc(datenum(tvespa), sl_grid, VESPA);
axis xy; colorbar;
xlabel('Time (UTC)'); ylabel('Slowness (s/km)');
datetick('x','HH:MM:SS','keeplimits');
title('Vespagram (time-slowness, delay-and-sum)');
set(gca, 'YDir','normal');
set(gca,'XLim',[datenum(tvespa(1)), datenum(tvespa(end))]);

% --- 1. Setup dan FK analysis: (seperti sebelumnya, pastikan data_all, t_event, dsb sudah ada) ---
sta = {'RE5DE','R6940','R265F','R7D17','R0279'};
lat = [-7.69225, -7.69218, -7.69429, -7.69393, -7.69126];
lon = [110.43853, 110.44111, 110.43898, 110.44132, 110.44003];

lat0 = mean(lat); lon0 = mean(lon);
[dx, dy] = latlon2xy(lat, lon, lat0, lon0);

idx_valid = find(~cellfun(@isempty, data_all));
Nsta = numel(idx_valid);
Nsam = min(cellfun(@numel, data_all(idx_valid)));
data_matrix = zeros(Nsta, Nsam);
for i = 1:Nsta
    data_matrix(i,:) = data_all{idx_valid(i)}(1:Nsam);
end
fs = 1/seconds(median(diff(t_event{idx_valid(1)})));

% --- FK moving window analysis ---
twlen = 6;    % detik window
twstep = 0.5; % detik step
wlen = round(twlen*fs);
wstep = round(twstep*fs);
nwin = floor((Nsam-wlen)/wstep)+1;

slmax = 1; ns = 80;
ux = linspace(-slmax, slmax, ns);
uy = linspace(-slmax, slmax, ns);
f_target = 5; omega = 2*pi*f_target;

tcenter = NaT(nwin,1);
power_abs = zeros(nwin,1);
power_rel = zeros(nwin,1);
baz = zeros(nwin,1);
slowness = zeros(nwin,1);

for iw = 1:nwin
    idx = (1:wlen) + (iw-1)*wstep;
    dseg = data_matrix(:, idx);

    FFT_data = fft(dseg, [], 2);
    freq = (0:wlen-1)*fs/wlen;
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

    [pkval, idx_max] = max(Pfk(:));
    [ix_max, iy_max] = ind2sub(size(Pfk), idx_max);
    sx = ux(ix_max); sy = uy(iy_max);

    slowness(iw) = sqrt(sx^2 + sy^2);
    az = atan2d(sx, sy); if az<0, az=az+360; end
    baz(iw) = az;
    power_abs(iw) = pkval;
    tcenter(iw) = t_event{idx_valid(1)}(idx(round(end/2)));
end

power_rel = (power_abs - min(power_abs))./(max(power_abs)-min(power_abs)+eps);

% --- 2. Plotting 5 panel, paling atas seismogram satu stasiun ---
figure('Position',[100 100 700 1000]);

% 1. Seismogram satu stasiun (misal stasiun pertama yang valid)
subplot(5,1,1)
data_matriks = data_matrix(1,:)-mean(data_matrix(1,:)); 
trace = data_matriks / max(abs(data_matriks)); % normalisasi
plot(t_event{idx_valid(1)}, trace, 'k');
ylabel([sta{idx_valid(1)}]);
title('Sample Seismogram (normalized)');
datetick('x','HH:MM:SS','keeplimits')
set(gca,'XLim',[t_event{idx_valid(1)}(1), t_event{idx_valid(1)}(end)]);
set(gca,'XTickLabel',[]); grid on;

% 2. Relative Power
subplot(5,1,2)
scatter(tcenter, power_rel, 50, power_rel, 'filled');
colormap('jet'); colorbar;
ylabel('rel. power');
title('Vespagram - Relative Power (Obspy style)');
set(gca,'XTickLabel',[]); box on; grid on;

% 3. Absolute Power
subplot(5,1,3)
scatter(tcenter, power_abs, 50, power_rel, 'filled');
colormap('jet'); colorbar;
ylabel('abs. power');
set(gca,'XTickLabel',[]); box on; grid on;

% 4. Backazimuth
subplot(5,1,4)
scatter(tcenter, baz, 50, power_rel, 'filled');
colormap('jet'); colorbar;
ylabel('baz (deg)');
set(gca,'XTickLabel',[]); box on; grid on;

% 5. Slowness
subplot(5,1,5)
scatter(tcenter, slowness, 50, power_rel, 'filled');
colormap('jet'); colorbar;
ylabel('slow (s/km)');
datetick('x','HH:MM:SS','keeplimits','keepticks');
set(gca,'XTickLabelRotation',30);
xlabel('Time (UTC)'); box on; grid on;

linkaxes(findall(gcf,'Type','axes'),'x');

% --- Fungsi bantu ---
function [dx, dy] = latlon2xy(lat, lon, lat0, lon0)
    R = 6371000; % m
    dlat = deg2rad(lat - lat0);
    dlon = deg2rad(lon - lon0);
    dx = R * dlon .* cos(deg2rad(lat0));
    dy = R * dlat;
end
