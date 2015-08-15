clear
clc
%load the data
rawDir = 'C:\Toby\RouteData\'

hosts = char('BU','CityU', 'CU', 'HKU', 'IED', 'LN', 'PolyU', 'UST')

filenames = char('-Harnet-apan-jp_data',
'-Harnet-applestore_data',
'-Harnet-atnext_data',
'-Harnet-ausnews_data',
'-Harnet-barclays_uk_data',
'-Harnet-bbc_data',
'-Harnet-beijing-gov_data',
'-Harnet-berlin_data',
'-Harnet-bom_au_data',
'-Harnet-citibank_data',
'-Harnet-CityU2_data',
'-Harnet-clp_hk_data',
'-Harnet-cpan_data',
'-Harnet-culib_data',
'-Harnet-eng2_data',
'-Harnet-eng3_data',
'-Harnet-eng4_data',
'-Harnet-fosu_data',
'-Harnet-fujitsu_data',
'-Harnet-gov_hk_data',
'-Harnet-hangseng_hk_data',
'-Harnet-hkelectric_data',
'-Harnet-hkex_data',
'-Harnet-hkix_data',
'-Harnet-hko_data',
'-Harnet-hkp_data',
'-Harnet-hktv_1_data',
'-Harnet-hktv_2_data',
'-Harnet-HKU_data',
'-Harnet-hk_apple1_hkakamai_data',
'-Harnet-hk_apple2_pccw_data',
'-Harnet-hk_apple4_nttjp_data',
'-Harnet-hmrc_gov_uk_data',
'-Harnet-hsbc_de_data',
'-Harnet-hsbc_hk_data',
'-Harnet-hsbc_uk_data',
'-Harnet-IED_data',
'-Harnet-internet2_data',
'-Harnet-iqua_ece_toronto_data',
'-Harnet-jnu_data',
'-Harnet-kreonet_data',
'-Harnet-lenovo_data',
'-Harnet-LN_data',
'-Harnet-mit_data',
'-Harnet-mtr_hk_data',
'-Harnet-ncu_data',
'-Harnet-nissan_data',
'-Harnet-nla_data',
'-Harnet-NYTimes_data',
'-Harnet-oclp_data',
'-Harnet-orange_uk_data',
'-Harnet-pccw_data',
'-Harnet-pku_data',
'-Harnet-plnode_chinanet_data',
'-Harnet-rovio_data',
'-Harnet-sfc_hk_data',
'-Harnet-shnet_data',
'-Harnet-sina-cn_data',
'-Harnet-stanford_data',
'-Harnet-statlayout_apple1_hkakamai_data',
'-Harnet-statlayout_apple2_nttjp_data',
'-Harnet-statlayout_apple3_sbjp_data',
'-Harnet-stat_apple1_pccw_data',
'-Harnet-stat_apple2_nttjp_data',
'-Harnet-stat_apple3_nttasia_data',
'-Harnet-subway_de_data',
'-Harnet-tein2_data',
'-Harnet-telecom_na_data',
'-Harnet-telstra_nz_data',
'-Harnet-tomita_data',
'-Harnet-towngas_data',
'-Harnet-tp1rc_data',
'-Harnet-twgrid_data',
'-Harnet-univ-rennes2_data',
'-Harnet-ust1_data',
'-Harnet-virginm_uk_data',
'-Harnet-xinhua_data',
'-Harnet-ytimg_hk_data');

%check the dimension
%nRows = zeros(size(filenames,1) * size(hosts, 1), 1);
%data = zeros(size(filenames,1) * size(hosts, 1), 3);
%idx = 1;

%for each route
for i = 1:size(filenames,1),
  %for each host, check timestamp (time_actual: column index 4)
  startRTT = [];
  endRTT = [];
  for hIdx = 1:size(hosts, 1),
    rttData = load([rawDir strtrim(hosts(hIdx, :)) strtrim(filenames(i, :))]);
	  %[nr, nc] = size(rttData);
	  startRTT = [startRTT, min(rttData(:, 4))];
	  endRTT = [endRTT, max(rttData(:, 4))];
    %data(idx, 1) = i;
    %data(idx, 2) = hIdx;
    %data(idx, 3) = nr;
    %disp([num2str(idx) ' out of ' num2str(size(nRows, 1)) ' DONE!']);
    %idx = idx + 1;    
  end;

  %determine the start and end time (use the longest range)
  startRTT = min(startRTT);
  endRTT = max(endRTT);
  
  t = startRTT:300:endRTT; %tick - 5 minutes
  
  %create a matrix for storage
  RTT = zeros(size(t, 2), size(hosts, 1));
  
  %reload the file again
  for hIdx = 1:size(hosts, 1),
  
    rttData = load([rawDir strtrim(hosts(hIdx, :)) strtrim(filenames(i, :))]);     
    #align data with the correct timestamp by using interpolation
    rttData_align = interp1(rttData(:, 4), rttData(:, 5), t);    
    #replace na with value 0
    rttData_align(isnan(rttData_align)) = 0;    
    #store it
    RTT(:, hIdx) = rttData_align;    
  end;  
  
  #save the RTT data as mat file
  data.RTT = RTT;
  data.t = t;
  save(["./RouteDataPreprocessed/"  strtrim(filenames(i, 2:end)) ".mat"], "data", "-v7"); 
end;

