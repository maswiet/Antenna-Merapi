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

'2023-08-18','13:41:07',-8.83,111.09,4.7,10;

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
