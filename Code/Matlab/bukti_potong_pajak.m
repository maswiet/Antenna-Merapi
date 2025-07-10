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
sta = 'RE5DE';
Fs = 100;
durasi = 90; % detik
window_rms = Fs; % 1 detik window
sensitivity_infra = 56000;    % counts/Pa
sensitivity_seis  = 3.9965e8; % counts/(m/s)

% Katalog BMKG (ganti/extend sesuai kebutuhanmu)
bmkg = {

'2023-08-01','12:28:21',-8.72,111.06,3.2,36;
'2023-08-05','17:33:01',-7.96,110.40,1.5,17;
'2023-08-11','01:35:43',-9.02,109.83,3.7,10;
'2023-08-17','17:44:12',-7.86,109.93,2.8,126;
'2023-08-18','13:41:07',-8.83,111.09,4.7,10;
'2023-08-18','18:29:15',-8.90,111.08,5.1,10;
'2023-08-19','08:28:34',-8.83,111.12,3.7,10;
'2023-08-20','22:18:17',-8.24,111.51,3.1,121;
'2023-08-23','06:20:04',-8.70,111.01,3.2,13;
'2023-08-23','19:52:53',-8.75,111.52,5.0,26;
'2023-08-25','10:50:59',-7.86,110.55,2.5,13;
'2023-08-26','17:09:04',-8.03,111.22,2.7,10;
'2023-08-26','16:59:59',-8.74,110.44,3.0,10;
'2023-08-29','18:16:36',-9.20,110.53,3.1,10;
'2023-09-01','04:58:58',-9.22,110.39,3.3,10;
'2023-09-03','10:21:41',-8.63,110.06,3.1,30;
'2023-09-05','18:33:29',-8.60,110.06,4.3,25;
'2023-09-11','12:40:10',-8.39,109.26,3.5,39;
'2023-09-18','15:54:45',-8.75,111.07,3.4,39;
'2023-09-25','09:16:33',-8.90,111.32,3.4,10;
'2023-09-26','22:28:24',-8.70,111.07,3.6,32;
'2023-09-27','14:44:50',-8.56,110.64,2.8,4;
'2023-10-04','16:30:25',-8.97,110.83,4.0,66;
'2023-10-05','23:38:52',-8.69,110.87,3.6,34;
'2023-10-05','03:15:46',-8.89,109.99,3.2,10;
'2023-10-06','21:17:16',-7.84,111.56,3.5,7;
'2023-10-06','21:37:20',-7.87,111.57,2.8,10;
'2023-10-09','23:26:51',-8.67,110.38,3.0,26;
'2023-10-09','14:30:36',-8.73,110.40,2.6,28;
'2023-10-09','13:11:16',-8.85,111.14,3.5,10;
'2023-10-09','21:57:26',-8.98,111.19,3.0,33;
'2023-10-12','12:38:22',-7.87,110.71,2.8,10;
'2023-10-12','21:08:42',-8.53,110.74,3.1,52;
'2023-10-13','12:12:58',-8.31,110.27,2.7,10;
'2023-10-19','18:02:30',-9.06,110.75,3.2,30;
'2023-10-20','02:16:57',-7.75,110.34,1.8,10;
'2023-10-22','16:51:00',-8.16,109.82,2.9,68;
'2023-10-22','11:21:39',-8.93,110.80,3.0,10;
'2023-10-23','05:24:07',-8.51,109.14,3.4,25;
'2023-10-26','17:31:21',-7.94,109.78,3.5,97;
'2023-10-31','01:00:03',-7.92,109.79,3.5,95;

% dst...
};
bmkg_tbl = cell2table(bmkg, 'VariableNames',{'Date','Time','Lat','Lon','Mag','Depth'});
bmkg_tbl.DateTime = datetime(strcat(bmkg_tbl.Date,{' '},bmkg_tbl.Time), 'InputFormat','yyyy-MM-dd HH:mm:ss');

h = waitbar(0,'Analisis event...');

for i_event = 1:height(bmkg_tbl)
    waitbar(i_event/height(bmkg_tbl), h, sprintf('Event %d/%d...', i_event, height(bmkg_tbl)));
    t_event = bmkg_tbl.DateTime(i_event);
    doy = day(t_event,'dayofyear');
    yr  = year(t_event);

    % === INFRA ===
    fname_infra = sprintf('%s/HDF.D/AM.%s.00.HDF.D.%d.%03d',sta,sta,yr,doy);
    t_infra = []; s_infra = []; rms_infra = [];
    if exist(fname_infra,'file')
        X = rdmseed(fname_infra);
        t_vec = vertcat(X.t);
        d_infra = vertcat(X.d) / sensitivity_infra; % ke Pa
        t_abs = datetime(t_vec, 'ConvertFrom', 'datenum');
        idx = (t_abs >= t_event) & (t_abs <= t_event + seconds(durasi));
        if any(idx)
            t_infra = t_abs(idx);
            s_infra = d_infra(idx);
            rms_infra = sqrt(movmean(s_infra.^2, window_rms));
        end
    end

    % === SEISMIC ===
    fname_seis = sprintf('%s/EHZ.D/AM.%s.00.EHZ.D.%d.%03d',sta,sta,yr,doy);
    t_seis = []; s_seis = [];
    if exist(fname_seis,'file')
        X = rdmseed(fname_seis);
        t_vec = vertcat(X.t);
        d_seis = vertcat(X.d) / sensitivity_seis; % ke m/s
        t_abs = datetime(t_vec, 'ConvertFrom', 'datenum');
        idx = (t_abs >= t_event) & (t_abs <= t_event + seconds(durasi));
        if any(idx)
            t_seis = t_abs(idx);
            s_seis = d_seis(idx);
        end
    end

    % --- Waktu detik sejak event ---
    x_infra = seconds(t_infra - t_event);
    x_seis  = seconds(t_seis  - t_event);

    % === CWT Infrasound ===
    if ~isempty(s_infra)
        [wt_infra,f_infra] = cwt(s_infra,Fs);
        t_cwt_infra = seconds(0:length(s_infra)-1)/Fs;
    else
        wt_infra = nan(128,1); f_infra = nan(128,1); t_cwt_infra = [];
    end

    % === CWT Seismic ===
    if ~isempty(s_seis)
        [wt_seis,f_seis] = cwt(s_seis,Fs);
        t_cwt_seis = seconds(0:length(s_seis)-1)/Fs;
    else
        wt_seis = nan(128,1); f_seis = nan(128,1); t_cwt_seis = [];
    end

    % === PLOT 4 PANEL ===
    figure('Position',[100 100 1200 700])
    tiledlayout(4,1,'TileSpacing','tight')

    % Panel 1: RMS Infra
    nexttile
    if ~isempty(x_infra)
        plot(x_infra, rms_infra, 'b')
      %  xlim([0 durasi])
    end
    ylabel('RMS Infra (Pa)')
    title(sprintf('Infrasound RMS, %s', datestr(t_event)))
    grid on

    % Panel 2: Sinyal Seismik
    nexttile
    if ~isempty(x_seis)
        plot(x_seis, s_seis, 'k')
       % xlim([0 durasi])
    end
    ylabel('Seismic (m/s)')
    title('Seismic Signal')
    grid on

    % Panel 3: CWT Infrasound
    nexttile
    if ~isempty(t_cwt_infra)
        imagesc(t_cwt_infra, f_infra, 10*log10(abs(wt_infra)))
        axis xy
        set(gca,'YScale','log')
       % xlim([0 durasi])
        ylabel('Freq (Hz)')
        title('CWT Infrasound (log scale)')
        colormap(jet)
        colorbar
    end

    % Panel 4: CWT Seismic
    nexttile
    if ~isempty(t_cwt_seis)
        imagesc(t_cwt_seis, f_seis, 10*log10(abs(wt_seis)))
        axis xy
        set(gca,'YScale','log')
       % xlim([0 durasi])
        ylabel('Freq (Hz)')
        xlabel('Time after event (s)')
        title('CWT Seismic (log scale)')
        colormap(jet)
        colorbar
    end

    sgtitle(sprintf('REKAMAN EVENT: %s, M%.1f, Depth=%skm', ...
        datestr(t_event), bmkg_tbl.Mag(i_event), num2str(bmkg_tbl.Depth(i_event))))
end
close(h)
