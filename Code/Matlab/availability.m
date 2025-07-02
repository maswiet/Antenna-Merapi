% List stasiun dan kode folder
stasiun = {'RE5DE','R6940','R265F','R7D17','R0279'};
julian_start = 180; % misal, awal Agustus
julian_end   = 250; % misal, akhir September
year = 2023;

% Buat tabel hasil
has_file = false(julian_end-julian_start+1, numel(stasiun));
days_vec = julian_start:julian_end;

for i = 1:numel(stasiun)
    for j = 1:numel(days_vec)
        day = days_vec(j);
        % Path infrasonik
        fHDF = sprintf('%s/HDF.D/AM.%s.00.HDF.D.%d.%03d', stasiun{i}, stasiun{i}, year, day);
        % Path seismik (bisa tambah EHZ.D jika ingin cek juga)
        % fEHZ = sprintf('%s/EHZ.D/AM.%s.00.EHZ.D.%d.%03d', stasiun{i}, stasiun{i}, year, day);
        % Cek file infrasonik
        if exist(fHDF,'file')
            has_file(j,i) = true;
        end
    end
end

% Buat tabel hasil
T = array2table(has_file, 'VariableNames', stasiun, 'RowNames', cellstr(string(days_vec)));

% Tampilkan di command window
disp('Tabel ketersediaan data HDF.D per stasiun per hari:');
disp(T)

% Asumsikan variabel 'has_file', 'days_vec', dan 'stasiun' sudah dari script sebelumnya
% Jika belum, jalankan bagian cek file dulu

figure('Position',[200 150 850 300])
imagesc(days_vec, 1:numel(stasiun), has_file')
colormap([1 1 1; 0 0.7 0]) % 1=white (tidak ada), 0=green (ada file)
set(gca,'YTick',1:numel(stasiun),'YTickLabel',stasiun)
xlabel('Julian Day')
ylabel('Stasiun')
title('Availability Chart: Infrasound Data')
colorbar('Ticks',[0 1],'TickLabels',{'Missing','Available'})
set(gca,'FontSize',12)
grid on
