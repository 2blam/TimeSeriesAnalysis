clear
clc
dataDir = 'D:\ROY\EEG Data for King & Toby\EEG data after IC removal_processed\';
outputDir = 'D:\ROY\EEG Data for King & Toby\EEG data after IC removal_result\';
%dirName = '1_Jul 22_Green_Walking_1';
eventTypeVal = [2, 4];

dirlist = dir(dataDir);
%for each tester
for n = 1:size(dirlist, 1)
    %if it is not . or ..
   if strcmp(dirlist(n).name, '.') == 0 & strcmp(dirlist(n).name, '..') == 0
       dirName = dirlist(n).name;
        %for each event
        for m = 1:length(eventTypeVal)
            event = num2str(eventTypeVal(m));
            
            %load data
            load([dataDir dirName '\' 'e' event '.mat']);


            input = data.input;
            channel_labels = data.channel_labels;
            numOfChannel = size(channel_labels, 1);
            dt = 0.002; % tick 0.002 seconds
            m = 60; % m - 60 seconds
            spike_threshold = 3;
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
            numPC = size(lof, 2);

            f_E = 0.0; %energy threshold (lower bound)
            F_E = 1.1; %energy threshold (upper bound)
            W = eye(size(lof, 2)); % weight matrix
            d = 0.01 * ones(size(lof, 1), 1); % energy of eigenvalues
            lamda= 0.99;
            E_x = 0;
            E_y = 0;

            %for each tick
            for tick = 1:maxsteps
                   %if (tick == 100)
                   %    holdOffTime = 100;
                   %end

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

            %save the result
            lscatter(W(:,1), W(:, 2), cellstr(channel_labels)');
            hold on
            xlabel('W_:_,_1');
            ylabel('W_:_,_2');
            title(strrep([dirName ' event: ' event ], '_', ' '));
            saveas(gcf, [outputDir '\' dirName '_e' event '_2D_scatter_lbl.png']);
            close 

            g = gscatter(W(:, 1), W(:, 2),channel_labels);
            hold on
            gridLegend(g,5);
            xlabel('W_:_,_1');
            ylabel('W_:_,_2');
            title(strrep([dirName ' event: ' event], '_', ' '));
            saveas(gcf, [outputDir '\' dirName '_e' event '_2D_scatter.png']);
            close

            lbls = cellstr(channel_labels)';
            s = scatter3(W(:, 1), W(:, 2), W(:, 3), 65, 1:numOfChannel, 'filled');
            hold on
            colormap(jet(numOfChannel));
            lcolorbar(lbls,'fontWeight', 'bold');
            xlabel('W_:_,_1');
            ylabel('W_:_,_2');
            zlabel('W_:_,_3');
            title(strrep([dirName ' event: ' event], '_', ' '));
            saveas(gcf, [outputDir '\' dirName '_e' event '_3D_scatter.png']);
            close
            
            %plot topoplot
            % form cluster - consider W(:, 1:2) only
            %  ** can consider more components e.g. (W:, 1:3)
            Z = linkage(squareform(pdist(W(:, 1:2))));
            T = cluster(Z, 'maxclust', 5); % consider 5 clusters
            %  can be increased or decreased

            % preprocess - updat the label with related cluster
            lbls = arrayfun(@(x) sprintf('%d',x),T,'uni',false).';
            for idx = 1:length(data.chanlocs)
                data.chanlocs(idx).labels = [data.chanlocs(idx).labels '(' char(lbls(idx)) ')'];
            end
            
            topoplot(T, data.chanlocs, 'style', 'fill','electrodes', 'labels' );
            title(strrep([dirName ' event: ' event], '_', ' '));
            saveas(gcf, [outputDir '\' dirName '_e' event '_topoplot.png']);
            close
        end

   end
end

