%------------------------------------------------------------------------
%
%            INFRASOUND PROJECT (GEOFISIKA UGM & GEMPA GMBH)
%               https://github.com/maswiet/Antenna-Merapi
%------------------------------------------------------------------------
%
% Program menampilkan event infrasonik pada waktu tertentu
% Sensor infrasound pada Shake&Boom biasanya adalah Mems mikrobarometer.
% Sensitivitas (gain):
% Untuk Raspberry Shake&Boom, berdasarkan datasheet resmi dan 
% dokumentasi Raspberry Shake forum:
% Sensitivitas = 0.00625 Pa/count
% (atau 1 count ≈ 0.00625 Pa; 1 Pa ≈ 160 counts)
%
%------------------------------------------------------------------------
% Parameter dasar
Fs = 100; % Sampling rate Hz
sensitivity = 0.00625;
stasiun = {'RE5DE','R6940','R265F','R7D17','R0279'};

start_dt = datenum(2023,8,25,16,0,0);
end_dt   = datenum(2023,8,25,16,30,0);

Nsta = numel(stasiun);
data_array = cell(1,Nsta);
time_array = cell(1,Nsta);

% Load dan filter data pada window waktu
for i = 1:Nsta
    fname = [stasiun{i} '/HDF.D/AM.' stasiun{i} '.00.HDF.D.2023.237'];
    disp(['Baca data : ' fname])
    X = rdmseed(fname);
    t = cat(1, X.t);
    d = cat(1, X.d);
    d = detrend(d);
    d = d * sensitivity;
    [b, a] = butter(4, [1 25]/(Fs/2), 'bandpass');
    d = filtfilt(b, a, d);
    idx = t >= start_dt & t <= end_dt;
    if ~any(idx)
        error(['Tidak ada data pada window waktu di stasiun: ' stasiun{i}])
    end
    data_array{i} = d(idx);
    time_array{i} = t(idx);
end

% Buat time reference dan matrix waveform
t_ref = time_array{1};
Nsample = length(t_ref);
waveform_mat = zeros(Nsample, Nsta);
for i = 1:Nsta
    if length(data_array{i}) ~= Nsample
        error(['Data length mismatch di stasiun: ' stasiun{i}])
    end
    waveform_mat(:,i) = data_array{i};
end

% Plot infrasoundgram (array plot)
offset = 2 * max(abs(waveform_mat(:))); % offset antar stasiun
figure;
hold on
for i = 1:Nsta
    plot((t_ref-t_ref(1))*24*3600, waveform_mat(:,i) + (i-1)*offset, 'k')
%    text(1600, (i-1)*offset, stasiun{i}, 'HorizontalAlignment','right')
end
hold off
xlabel('Waktu (detik) sejak 16:00')
ylabel('Stasiun (offset)')
yticks((0:Nsta-1)*offset)
title('Infrasoundgram 25 Agustus 2023, 16:00–16:30')
grid on
box on