clear
clc
%save all time series plot

matDir = 'C:\Toby\RouteDataPreprocessed\';
hosts = char('BU','CityU', 'CU', 'HKU', 'IED', 'LN', 'PolyU', 'UST');
graphics_toolkit gnuplot;
filelist = dir([matDir '*.mat']);

%for each mat file
for i = 1:length(filelist)

 filename = filelist(i).name
 
 %load mat file
 load([matDir filename]);
 
 set (0, "defaultaxesfontname", "Helvetica") % this is the line to add BEFORE plotting
 figure(1,"visible","off");
 plot(data.t, data.RTT);
 xlabel('Timestamp');
 ylabel('RTT');
 legend(cellstr(hosts)); 
 title(strrep(strrep(filename, "_", " "), ".mat", ""));
 
 ofn = [strrep(filename, ".mat", "") ".png"];
 saveas(1, ofn, "png");
 close all; 
end