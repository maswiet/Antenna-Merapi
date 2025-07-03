%------------------------------------------------------------------------
%
%            INFRASOUND PROJECT (GEOFISIKA UGM & GEMPA GMBH)
%               https://github.com/maswiet/Antenna-Merapi
%------------------------------------------------------------------------
%
% Program menampilkan seismogram atau infrasonicgram harian (dayplot)
% Sensor infrasound pada Shake&Boom biasanya adalah Mems mikrobarometer.
% Sensitivitas (gain):
% Untuk Raspberry Shake&Boom, berdasarkan datasheet resmi dan 
% dokumentasi Raspberry Shake forum:
% Sensitivitas = 0.00625 Pa/count
% (atau 1 count ≈ 0.00625 Pa; 1 Pa ≈ 160 counts)
%
%------------------------------------------------------------------------
% === PARAMETER UTAMA ===
sta = 'RE5DE';
channel = 'EHZ';  % atau 'HDF'
Fs = 100;
year = 2023;
bulan = 8;
tanggal = 25;
hari_julian = day(datetime(year,bulan,tanggal),'dayofyear');
interval_menit = 60; % GANTI: interval per baris (menit), misal 60=1 jam, 30=30 menit

if strcmpi(channel,'HDF')
    fname = sprintf('%s/HDF.D/AM.%s.00.HDF.D.%d.%03d',sta,sta,year,hari_julian);
    ylab = 'Infrasound (Pa)';
    sensitivity = 56000; % counts/Pa
else
    fname = sprintf('%s/EHZ.D/AM.%s.00.EHZ.D.%d.%03d',sta,sta,year,hari_julian);
    ylab = 'Seismic (m/s)';
    sensitivity = 3.9965e8; % counts/(m/s)
end

% === BACA DATA ===
if exist(fname,'file')
    X = rdmseed(fname);
    d = vertcat(X.d)/sensitivity;
    t_vec = vertcat(X.t);
    t_abs = datetime(t_vec,'ConvertFrom','datenum');
else
    error('File tidak ditemukan!');
end

% === DRUMPLOT ===
t0_hari = datetime(year,bulan,tanggal);
nbaris = ceil(24*60/interval_menit); % berapa baris dalam 1 hari
warna = lines(nbaris); % warna otomatis per baris
maxabs = prctile(abs(d),99); % agar visual rapi

figure('Position',[100 100 1300 800]); hold on

for b = 1:nbaris
    t1 = t0_hari + minutes((b-1)*interval_menit);
    t2 = t1 + minutes(interval_menit);
    idx = (t_abs >= t1) & (t_abs < t2);
    if ~any(idx), continue; end
    dseg = d(idx);
    tseg = t_abs(idx);
    x_plot = minutes(tseg - t1);
    y_offset = nbaris - b + 1;
    plot(x_plot, dseg/maxabs + y_offset, 'Color',warna(b,:), 'LineWidth',0.7)
    % Garis dasar setiap baris
    plot([0 interval_menit],[y_offset y_offset],'Color',[0.7 0.7 0.7])
end

% Y-axis label interval
yticks = 1:nbaris;
yticklabels = arrayfun(@(x) datestr(t0_hari+minutes((nbaris-x)*interval_menit),'HH:MM:SS'), yticks, 'UniformOutput',false);
set(gca, 'YTick', yticks, 'YTickLabel', yticklabels, 'FontSize',11)
ylim([0 nbaris+1])

% X-axis label menit
xlim([0 interval_menit])
xticks = 0:5:interval_menit;
set(gca,'XTick',xticks)
xlabel('time in minutes')
ylabel('UTC (local time = UTC + 00:00)')
title(sprintf('Drumplot %s.%s, %04d-%02d-%02d, %d menit/baris',sta,channel,year,bulan,tanggal,interval_menit),'Interpreter','none')
grid on; box on
hold off
