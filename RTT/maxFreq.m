%save max frequency 
matDir = 'C:\Toby\RouteDataPreProcessed\';

numberOfSample = 24 * 60 / 5; %24 hrs * 60 minutes / 5 (5 mins per tick)
hosts = char('BU','CityU', 'CU', 'HKU', 'IED', 'LN', 'PolyU', 'UST');
filelist = dir([matDir '*.mat']);

for i = 1:length(filelist)

 filename = filelist(i).name
 
 %load mat file
 load([matDir filelist(i).name]);
 
 input = data.RTT;
 t = data.t;
 
 input(isnan(input)) = 0;
 
 numberOfTick= size(input, 1);
 maxFreqHist = zeros(numberOfTick-numberOfSample, length(hosts));
 
  N = numberOfSample;

  %sampling rate, fs, is the average number of samples obtained in one second (samples per second) 
  fs = 1/(5 * 60);  %5 min per tick
  ts= 1/fs;
  tmax = (N-1)*ts;
  %t = 0:ts:tmax;
  f = -fs/2:fs/(N-1):fs/2;
    
 %for each host
  for hostIdx = 1:length(hosts)    
    signal = input(:, hostIdx);
    
    for idx = 1:size(maxFreqHist, 1)
      counter = idx;
      x = signal(idx:(idx+numberOfSample-1), 1);   
      
      %only get positive frequency
      filter = find(f>=0);
      f = f(filter);      
      
       z=fftshift(fft(x));
       z = z(filter);
       absZ = abs(z);
       midx = find(max(absZ) == absZ);
       f_max= f(midx(1)); %if more than 1 max value, select the 1st one
       
       maxFreqHist(idx, hostIdx) = f_max;      
    end
  end
  
  %pad zeros
  pad = zeros(numberOfSample, 8);
  maxFreqHist = vertcat(pad, maxFreqHist);
  figure(1,"visible","off");
  
  plot(t, maxFreqHist );
  xlabel('Unix Epoch Time')
  ylabel('Max Frequency')
  legend(hosts);
  titleStr= [strrep(strrep(filename, "_", " "), ".mat", "") ' - Max Frequency (Number of Sample: 288)'];
  title(titleStr);
  
  ofn = [strrep(filename, ".mat", "") "_MaxFreq.png"];
  saveas(1, ofn, "png");


end
