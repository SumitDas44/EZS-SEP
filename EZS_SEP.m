tic
clear;

% PARAMETERS
xm = 100; ym = 100;
sink.x = 0.5 * xm; sink.y = 0.5 * ym;
Eo = 0.5;
ETX = 50e-9; ERX = 50e-9;
Efs = 10e-12; Emp = 0.0013e-12;
EDA = 5e-9;
do = sqrt(Efs/Emp);

n = 100; % Total nodes
m = 0.2; b1 = 0.3;
a = 3; b = 1.5;
rmax = 10000;
p = 0.1;
u = 0;
Packet = 4000;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   EZS-SEP                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(1); hold on;
i = 1;
normal_n = 50; intermediate_n = 30; advanced_n = 20;

%% === ONE SOM FOR ALL ZONES ===
input = rand(2, n);
net = selforgmap([10 10]);
net.trainParam.epochs = 300;
net = train(net, input);
positions = net.IW{1};  % size: [100 x 2]

% Shuffle to randomize zone assignments
perm = randperm(n);

%% === ASSIGN ZONES MANUALLY BASED ON INDEX ===

for q = 1:n
    idx = perm(q);
    x = positions(idx,1);
    y = positions(idx,2);

    % Zone mapping
    if q <= normal_n
        % Normal Zone: X 30–70, Y 30–70 (100,100)
        % Normal Zone: X 45–105, Y 45–105 (150,150)
        % Normal Zone: X 54–126, Y 54–126 (180,180)
        % Normal Zone: X 60–140, Y 60–140 (200,200)
        x = x * 40 + 30;
        y = y * 40 + 30;
        S(i).E = Eo;
        S(i).ENERGY = 0;
        S(i).type = 'N';
        plot(x, y, 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
        
    elseif q <= normal_n + intermediate_n
        % Intermediate: Left (X: 0–30) or Right (X: 70–100), Y: 0–100
        % Intermediate: Left (X: 0–45) or Right (X: 105–150), Y: 0–150
        % Intermediate: Left (X: 0–54) or Right (X: 126–180), Y: 0–180
        % Intermediate: Left (X: 0–60) or Right (X: 140–200), Y: 0–200
        if mod(q, 2) == 0
            x = x * 30;           % Left
        else
            x = x * 30 + 70;      % Right
        end
        y = y * 100;
        S(i).E = Eo * (1 + b);
        S(i).ENERGY = 0.5;
        S(i).type = 'I';
        plot(x, y, '*', 'Color', [1 0.65 0], 'MarkerSize', 7);
    else
        % Advanced: Bottom (Y: 0–30) or Top (Y: 70–100), X: 30–70
        % Advanced: Bottom (Y: 0–45) or Top (Y: 105–150), X: 45–105
        % Advanced: Bottom (Y: 0-54) or Top (Y: 126–180), X: 54–126
        % Advanced: Bottom (Y: 0–60) or Top (Y: 140–200), X: 60–140
        x = x * 40 + 30;
        if mod(q, 2) == 0
            y = y * 30;           % Bottom
        else
            y = y * 30 + 70;      % Top
        end
        S(i).E = Eo * (1 + a);
        S(i).ENERGY = 1;
        S(i).type = 'A';
        plot(x, y, 'd', 'Color', [1 1 0], 'MarkerSize', 8);
    end

    S(i).xd = x;
    S(i).yd = y;
    S(i).G = 0;
    i = i + 1;
end

%% === SINK NODE ===
S(n+1).xd = sink.x;
S(n+1).yd = sink.y;
plot(sink.x, sink.y, 'x', 'Color', 'k', 'MarkerSize', 10, 'LineWidth', 2);

%% === LEGEND & AXIS ===
h_norm = plot(NaN, NaN, 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
h_int  = plot(NaN, NaN, '*', 'Color', [1 0.65 0]);
h_adv  = plot(NaN, NaN, 'd', 'Color', [1 1 0]);
h_sink = plot(NaN, NaN, 'x', 'Color', 'k');
legend([h_norm h_int h_adv h_sink], {'Normal', 'Intermediate', 'Advanced', 'Sink'});

title('EZS-SEP (SOM) Deployment');
xlabel('X axis (meters)'); ylabel('Y axis (meters)');
axis([0 xm 0 ym]); grid on;

disp('Deployment complete using one SOM.');

%% === EZ-SEP ===
%figure(1);

flag_first_dead = 0;
allive = n;

packets_TO_BS_n=0;
packets_TO_BS_a=0;
packets_TO_BS_i=0;
packets_TO_BS_mh=0;
packets_TO_BS=0;
packets_TO_CH=0;

no_multihop = 0;
multihop = 0;

Eavg = 0;
Eavg_n = 0;
Eavg_a = 0;
Eavg_i = 0;
Davg = 0;
D_BS = 0;

for r=0:rmax
    r

    % === Compute E_avg(r) (average energy of alive nodes) ===
    alive_nodes = 0;
    alive_nodes_n = 0;
    alive_nodes_a = 0;
    alive_nodes_i = 0;
    total_energy_alive = 0;
    total_energy_alive_n = 0;
    total_energy_alive_a = 0;
    total_energy_alive_i = 0;
    total_distance_alive = 0;

    for j = 1:1:n
        D_BS(j) = sqrt( (S(j).xd-(S(n+1).xd) )^2 + (S(j).yd-(S(n+1).yd) )^2 );
        if S(j).E > 0
            distance = sqrt( (S(j).xd-(S(n+1).xd) )^2 + (S(j).yd-(S(n+1).yd) )^2 );
            total_energy_alive = total_energy_alive + S(j).E;
            total_distance_alive = total_distance_alive + distance;
            alive_nodes = alive_nodes + 1;

            if S(j).ENERGY == 0
                alive_nodes_n = alive_nodes_n + 1;
                total_energy_alive_n = total_energy_alive_n + S(j).E;
            elseif S(j).ENERGY == 1
                alive_nodes_a = alive_nodes_a + 1;
                total_energy_alive_a = total_energy_alive_a + S(j).E;
            else
                alive_nodes_i = alive_nodes_i + 1;
                total_energy_alive_i = total_energy_alive_i + S(j).E;
            end
        end
    end

    if alive_nodes > 0
        Eavg(r+1) = total_energy_alive / alive_nodes;
        Eavg_n(r+1) = total_energy_alive_n / alive_nodes_n;
        Eavg_i(r+1) = total_energy_alive_i / alive_nodes_i;
        Eavg_a(r+1) = total_energy_alive_a / alive_nodes_a;
        Davg(r+1) = total_distance_alive / alive_nodes;
    else
        Eavg(r+1) = 0;
        Eavg_n(r+1) = 0;
        Eavg_i(r+1) = 0;
        Eavg_a(r+1) = 0;
        Davg(r+1) = 0;
    end

    pint = ( p*(1+b)/(1+a*m+b*b1) )*(Eavg(r+1)/(Eo*(1+b)))*(Davg(r+1)/D_BS(j));
    padv = ( p*(1+a)/(1+a*m+b*b1) )*(Eavg(r+1)/(Eo*(1+a)))*(Davg(r+1)/D_BS(j));

    %Operations for sub-epochs
    if(mod(r, round(1/padv) )==0)
        for i=1:n
            if(S(i).ENERGY==1)
                S(i).G=0;
            end
        end
    end
    if(mod(r, round(1/pint) )==0)
        for i=1:n
            if(S(i).ENERGY==0.5)
                S(i).G=0;
            end
        end
    end

    dead=0;
    
    %Number of dead Advanced Nodes
    dead_a=0;
    %Number of dead Intermediate Nodes
    dead_i=0;
    %Number of dead Normal Nodes
    dead_n=0;
    
    for i=1:1:n
        %checking if there is a dead node
        if (S(i).E<=0)
            %%plot(S(i).xd,S(i).yd,'red .');  
            dead=dead+1;
            
            if(S(i).ENERGY==1)
                dead_a=dead_a+1;
            end
            if(S(i).ENERGY==0.5)
                dead_i=dead_i+1;
            end
            if(S(i).ENERGY==0)
                dead_n=dead_n+1;
            end
            %hold on;
        end
        if (S(i).E>0)
            S(i).type='N';
            if (S(i).ENERGY==0)
                %plot(S(i).xd,S(i).yd,'ob');
            end
            if (S(i).ENERGY==0.5)
                %plot(S(i).xd,S(i).yd,'or');
            end
            if (S(i).ENERGY==1)
                %plot(S(i).xd,S(i).yd,'og');
            end
            %hold on;
        end
        %plot(S(n+1).xd,S(n+1).yd,'green x');
        
        STATISTICS.DEAD(r+1)=dead;
        STATISTICS.ALLIVE(r+1)=allive-dead;
        
    end
    
    %When the first node dies
    if (dead==1)
        if(flag_first_dead==0)
            first_dead=r;
            flag_first_dead=1;
        end
    end

    % Normal node direct to sink
    for(i=1:1:n)
        if(S(i).E>=0)
            if(S(i).type=='N')
                distance=sqrt( (S(i).xd-(S(n+1).xd) )^2 + (S(i).yd-(S(n+1).yd) )^2 );
                if (distance>do)
                    S(i).E=S(i).E- ( (ETX+EDA)*(4000) + Emp*4000*( distance*distance*distance*distance ));
                end
                if (distance<=do)
                    S(i).E=S(i).E- ( (ETX+EDA)*(4000)  + Efs*4000*( distance * distance ));
                end
                packets_TO_BS_n=packets_TO_BS_n+1;
            end
        end        
    end

    % CH election for advanced nodes
    countCHs = 0;
    cluster = 1;
    for i = 1:1:n
        if S(i).E > 0 && S(i).ENERGY == 1 && S(i).G <= 0
            temp_rand = rand;
            threshold = padv*(Davg(r+1)/D_BS(i)) / ((1 - padv * mod(r, round(1/padv)))*(S(i).E/Eavg(r+1)));
            if temp_rand <= threshold
                countCHs = countCHs + 1;
                S(i).type = 'C';
                S(i).G = (1/padv) - 1;

                C(cluster).xd = S(i).xd;
                C(cluster).yd = S(i).yd;
                C(cluster).id = i;
                dCH = sqrt((S(i).xd - sink.x)^2 + (S(i).yd - sink.y)^2);
                C(cluster).distance = dCH;

                if dCH > do
                    S(i).E = S(i).E - ((ETX+EDA)*4000 + Emp*4000*(dCH^4));
                else
                    S(i).E = S(i).E - ((ETX+EDA)*4000 + Efs*4000*(dCH^2));
                end

                packets_TO_BS_a = packets_TO_BS_a + 1;
                cluster = cluster + 1;
            end
        end
    end

    % CH election for intermediate nodes
    for i = 1:1:n
        if S(i).E > 0 && S(i).ENERGY == 0.5 && S(i).G <= 0
            temp_rand = rand;
            threshold = pint*(S(i).E/Eavg(r+1))*(Davg(r+1)/D_BS(i)) / (1 - pint * mod(r, round(1/pint)));
            if temp_rand <= threshold
                countCHs = countCHs + 1;
                S(i).type = 'C';
                S(i).G = (1/pint) - 1;

                C(cluster).xd = S(i).xd;
                C(cluster).yd = S(i).yd;
                C(cluster).id = i;
                dCH = sqrt((S(i).xd - sink.x)^2 + (S(i).yd - sink.y)^2);
                C(cluster).distance = dCH;

                if dCH > do
                    S(i).E = S(i).E - ((ETX+EDA)*4000 + Emp*4000*(dCH^4));
                else
                    S(i).E = S(i).E - ((ETX+EDA)*4000 + Efs*4000*(dCH^2));
                end

                packets_TO_BS_i = packets_TO_BS_i + 1;
                cluster = cluster + 1;
            end
        end
    end

    % Cluster members transmit to nearest CH
            for i=1:1:n
                if ( S(i).type=='A' && S(i).E>0 )
                    if(cluster-1>=1)
                        min_dis=inf;
                        min_dis_cluster=1;
                        
                        for c=1:1:cluster-1
                            temp=min(min_dis,sqrt( (S(i).xd-C(c).xd)^2 + (S(i).yd-C(c).yd)^2 ) );
                            
                            if ( temp<min_dis )
                                min_dis=temp;
                                min_dis_cluster=c;
                            end           
                        end
                        
                        %Energy dissipated by  Cluster menmber for transmission of packet
                        %  min_dis;
                        if (min_dis>do)
                            S(i).E=S(i).E- ( ETX*(4000) + Emp*4000*( min_dis * min_dis * min_dis * min_dis));
                        end
                        if (min_dis<=do)
                            S(i).E=S(i).E- ( ETX*(4000) + Efs*4000*( min_dis * min_dis));
                        end
                        %Energy dissipated by clustre head in receving
                        if(min_dis>0)
                            S(C(min_dis_cluster).id).E = S(C(min_dis_cluster).id).E- ( (ERX + EDA)*4000 );
                            PACKETS_TO_CH(r+1)=n-dead-cluster+1;
                        end
                        
                        S(i).min_dis=min_dis;
                        S(i).min_dis_cluster=min_dis_cluster;
                        
                    end
                end
            end

            for i=1:1:n
                if ( S(i).type=='I' && S(i).E>0 )
                    if(cluster-1>=1)
                        min_dis=inf;
                        min_dis_cluster=1;
                        
                        for c=1:1:cluster-1
                            temp=min(min_dis,sqrt( (S(i).xd-C(c).xd)^2 + (S(i).yd-C(c).yd)^2 ) );
                            
                            if ( temp<min_dis )
                                min_dis=temp;
                                min_dis_cluster=c;
                            end           
                        end
                        
                        %Energy dissipated by  Cluster menmber for transmission of packet
                        %  min_dis;
                        if (min_dis>do)
                            S(i).E=S(i).E- ( ETX*(4000) + Emp*4000*( min_dis * min_dis * min_dis * min_dis));
                        end
                        if (min_dis<=do)
                            S(i).E=S(i).E- ( ETX*(4000) + Efs*4000*( min_dis * min_dis));
                        end
                        %Energy dissipated by clustre head in receving
                        if(min_dis>0)
                            S(C(min_dis_cluster).id).E = S(C(min_dis_cluster).id).E- ( (ERX + EDA)*4000 );
                            PACKETS_TO_CH(r+1)=n-dead-cluster+1;
                        end
                        
                        S(i).min_dis=min_dis;
                        S(i).min_dis_cluster=min_dis_cluster;
                        
                    end
                end
            end

sum=0;
for i=1:1:n
    if(S(i).E>0)
        sum=sum+S(i).E;
    end
end
avg=sum/n;
STATISTICS.Energy_per_round(r+1)=avg*100;

    packets_TO_BS = packets_TO_BS_mh + packets_TO_BS_n + packets_TO_BS_a + packets_TO_BS_i;
    STATISTICS.DEAD(r+1) = dead;
    STATISTICS.ALLIVE(r+1) = n - dead;
    STATISTICS.PACKETS_TO_BS(r+1) = packets_TO_BS;
    STATISTICS.CLUSTERHEADS(r+1) = cluster - 1;

    E_EZS_SEP = (n*m*Eo*(1+a) + n*b1*Eo*(1+b) + (n-n*m-n*b1)*Eo);
    % Percentage of total energy
    STATISTICS.Engery_percentage(r+1) = STATISTICS.Energy_per_round(r+1)*100/E_EZS_SEP;

end


figure(6);
r=0:rmax;
plot(r,STATISTICS.ALLIVE(r+1),'-g')
legend('EZS-SEP');
title('Alive Nodes Per Round');
xlabel('Rounds');
ylabel('Alive Nodes');

figure(7);
plot(r,STATISTICS.DEAD(r+1),'-g')
legend('EZS-SEP');
title('Dead Nodes Per Round');
xlabel('Rounds');
ylabel('Dead Nodes');

figure(8);
plot(r,STATISTICS.PACKETS_TO_BS(r+1),'-g')
legend('EZS-SEP');
title('Packets to BS throughout the simulation');
xlabel('Rounds');
ylabel('Packets to BS');

figure(9);
plot(r,STATISTICS.Energy_per_round(r+1),'-g')
legend('EZS-SEP');
title('Energy of the network Per Round');
xlabel('Rounds');
ylabel('Average Energy');

figure(10);
plot(r,STATISTICS.Engery_percentage(r+1),'-g')
legend('EZS-SEP');
title('Energy Percentage');
xlabel('Rounds');
ylabel('Energy Remaining');

elapsedTime = toc;
fprintf('Simulation took %.2f seconds.\n', elapsedTime);