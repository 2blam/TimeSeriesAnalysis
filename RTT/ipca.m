clear
clc

dataDir = 'C:\Toby\RouteDataPreProcessed\';
hosts = char('BU','CityU', 'CU', 'HKU', 'IED', 'LN', 'PolyU', 'UST');
graphics_toolkit gnuplot;
set (0, "defaultaxesfontname", "Helvetica") % this is the line to add BEFORE plotting

filelist = dir([dataDir '*.mat']);

%for each mat file
for i = 1:length(filelist)

 filename = filelist(i).name
 
 %load mat file
 load([dataDir filelist(i).name]);
 
 input = data.RTT;
 t = data.t;
 
 input(isnan(input)) = 0;

  dt = 300; % AUSNEWS tick 5 minutes
  m = 60; % m - 60 seconds
  spike_threshold = 3;
  last_change_at = 1;
  holdOffTime = 2;

  RC = m * dt / pi;
  alpha = dt / (RC + dt);

  lof = zeros(size(input));
  %for each col
  for col = 1:size(input, 2)
      lof(1, col) = input(1, col); %set the 1st value
      %for each row value
      for idx = 2:size(lof, 1)    
          lof(idx, col) = alpha * input(idx, col) + (1-alpha) * lof(idx-1, col);
      end
  end

  %get the difference
  difference = input - lof;
  spikes = zeros(size(input));
  for col = 1:size(input, 2)
      threshold = abs(std(difference(:, col)) * spike_threshold); %standard deviation 
      idx = find(abs(difference(:, col)) > threshold);
      spikes(idx, col) = difference(idx, col);
  end

  residual = difference - spikes;

  %add residual to lof
  lof = lof + residual;

  %%%% next step - compression (Incremental PCA) %%%%
  maxsteps = min(size(lof, 1), 1e6);
  reclog = zeros(size(lof)); % keep track of reconstruction
  numPClog = zeros(size(lof, 1), 1); %keep track of number of principal components
  hiddenVarlog = zeros(size(lof)); %keep track of values of hidden variables

  numPC = 8; % 8 hosts
  holdOffTime = 2; 
  
  f_E = 0.0; %energy threshold (lower bound)
  F_E = 1.1; %energy threshold (upper bound)
  W = eye(size(lof, 2)); % weight matrix
  d = 0.01 * ones(size(lof, 1), 1); % energy of eigenvalues
  lamda= 0.99;
  E_x = 0;
  E_y = 0;

  %for each tick
  for tick = 1:maxsteps
         if (tick == 100)
             holdOffTime = 100;
         end
      
      %get the data (i.e. value of each route)
      y_tp1 = lof(tick, :)';   %y_tp1 stands for t+1
      r = y_tp1;
      
      %update W, d
      for i = 1:numPC %
          d_i = d(i);
          %obtain the W_i
          W_i = W(:, i);
          z = W_i' * r;
          
          d_i = lamda * d_i + z^2;
          
          W_i = W_i + (z / d_i) * (r - z *W_i);
          r = r - z * W_i;
          
          %normalize W
          W_i = W_i ./ norm(W_i);
          
          %update W, d
          W(:, i) = W_i;
          d(i) = d_i;        
      end
      
      %orthonomalize W
      [Q, R] = qr(W(:, 1:numPC)); %orthogonal-triangular decomposition, Q - unitary matrix; R - upper triangular matrix
      W(:, 1:numPC) = Q(:, 1:numPC);    
       
      %projection the row data to new m-dimensional space (hidden variables)
      x_tp1 = W(:, 1:numPC)' * y_tp1; % tp1 stands for t+1
      
      %reconstruction
      yhat_tp1 = W(:, 1:numPC) * x_tp1;
      
      %calculate the energy
      E_x = lamda * E_x + sum(x_tp1.^2);
      E_y = lamda * E_y + sum(y_tp1.^2);
    
      
      if E_x < (f_E * E_y)        
          [last_change_at, numPC]  = changeNumPC(1, last_change_at, tick, holdOffTime, numPC, size(lof, 2), (E_x/ E_y));
      elseif E_y > (F_E * E_x)        
         [last_change_at, numPC] =  changeNumPC(-1, last_change_at, tick, holdOffTime, numPC, size(lof, 2), (E_x/ E_y));
      end
      
      %record the history
      reclog(tick, :) = yhat_tp1;
      numPClog(tick) = numPC;
      hiddenVarlog(tick, 1:size(x_tp1, 1)) = x_tp1;
  end
  
  %save the spikes
  %figure(1)
  figure(1,"visible","off");
  plot(t, spikes);
  xlabel('Unix Epoch Time');
  ylabel('');
  legend(hosts);
  titleStr= [strrep(strrep(filename, "_", " "), ".mat", "") ' - Spiky bursts detected [Potential Anomalies]'];
  title(titleStr);
  
  ofn = [strrep(filename, ".mat", "") "_spikes.png"];
  saveas(1, ofn, "png");

   %save the hidden variables (trend)
   %figure(2)
   figure(2,"visible","off");
   plot(t, hiddenVarlog(:, 1), 'b', t, hiddenVarlog(:, 2), 'r')
   legend(char('hv0', 'hv1'));
   xlabel('Unix Epoch Time')
   ylabel('Value')
   titleStr= [strrep(strrep(filename, "_", " "), ".mat", "") ' - Hidden Variables [Trend]'];
   title(titleStr)
   
   ofn = [strrep(filename, ".mat", "") "_trends.png"];
   saveas(2, ofn, "png");
   
  %save the W(:, 1) vs W(:, 2) graph
  % scatter legend does not work, it is the alternative
  %figure(3)
  figure(3,"visible","off");
  color = [1:8] ./8;
  x = W(:, 1)';
  x = mat2cell (x, 1, ones (size (x)));
  y = W(:, 2)';
  y = mat2cell (y, 1, ones (size (y)));
  m = repmat ({"s"}, size (x));
  h = plot ([x;y;m]{:});
  legend (hosts);
  map = colormap ();
  for n = 1:numel(h)
     idx = round (interp1 ([0, 1], [1, size(map,1)], color(n)));
     set (h(n), "color", map(idx,:))
  end
  xlabel("W_:_,_1");  
  ylabel("W_:_,_2");
  titleStr= [strrep(strrep(filename, "_", " "), ".mat", "") ' - Scatter Plot'];
  title(titleStr)
  
  ofn = [strrep(filename, ".mat", "") "_scatter.png"];
  saveas(3, ofn, "png");
  
  close all;
 
end