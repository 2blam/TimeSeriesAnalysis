#install.packages("devtools")
#devtools::install_github("twitter/AnomalyDetection")

Sys.setlocale("LC_ALL","English") #ensure the plot output is in English

library(AnomalyDetection)
library(R.matlab)
library(ggplot2) #for saving the graphs
setwd("C://Toby//")
hosts = c('BU','CityU', 'CU', 'HKU', 'IED', 'LN', 'PolyU', 'UST');

getAnomaly = function(timestamp, RTT, max_anoms, fn){
  df <- data.frame(matrix(timestamp),stringsAsFactors=FALSE)
  colnames(df) = c("timestamp")
  df$count = RTT;
  
  #replace nan with 0
  idx = which(is.na(df$count));
  if (length(idx) > 0){
    df$count[idx] = 0;
  }
  
  res = AnomalyDetectionTs(df, max_anoms=max_anoms, direction='both', longterm=T, plot=TRUE)

  ofn = paste0(getwd(), "/Twitter_Anomaly_plots/", fn, '.png');
  #save the plot
  ggsave(ofn, plot=res[["plot"]]);
}


#get list of mat file
filelist = dir(paste0(getwd(), '/RouteDataPreprocessed/', sep=""), pattern="*.mat");

for (i in 1:length(filelist)){

  #get the filename
  ifn = filelist[i];
  
  #read the mat data
  data = readMat(paste0(getwd(), '/RouteDataPreprocessed/', ifn , sep=''));
  RTT = as.data.frame(data$data[1]);
  t = unlist(data$data[2]);
  
  #
  colnames(RTT) = hosts;
  start = t[1];
  finish = tail(t, n=1); #get the last element
  
  t = seq(start, finish, 300);#tick - 5 minutes
  
  #for each hosts
  for (hostIdx in 1:length(hosts)){
    #20% anomalies
    getAnomaly(t, RTT[, hostIdx], 0.2, paste0(hosts[hostIdx], "-", gsub(".mat", "", ifn), sep=""));
  }

}