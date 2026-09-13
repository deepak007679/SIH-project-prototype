%% LONG ROAD AUTONOMOUS VEHICLE - CATTLE CROSSING
% Long continuously travelling road
% Approx. 90 seconds simulation
% No road reset / no teleportation

clear;
clc;
close all;

%% ---------------- SIMULATION ----------------
dt = 0.08;
simulationTime = 90;
N = round(simulationTime/dt);

roadLength = 1800;       % 1.8 km road
vehicleSpeed = 17;       % m/s

egoX = 20;
egoY = 0;

%% ---------------- FIGURE ----------------
figure('Color','w','Position',[80 80 1300 700]);

%% ---------------- ROAD ----------------
axis([0 140 -45 45]);
axis equal;
hold on;

title('AUTONOMOUS VEHICLE - LONG RURAL ROAD / CATTLE CROSSING');
xlabel('Road distance');
ylabel('Environment');

%% Draw road
fill([0 roadLength roadLength 0], ...
    [-7 -7 7 7], ...
    [0.32 0.32 0.32], ...
    'EdgeColor','none');

% Road edges
plot([0 roadLength],[7 7],'w','LineWidth',2);
plot([0 roadLength],[-7 -7],'w','LineWidth',2);

% Centre line
plot([0 roadLength],[0 0],'w--','LineWidth',2);

%% Fields
fill([0 roadLength roadLength 0], ...
    [7 7 45 45], ...
    [0.55 0.75 0.40], ...
    'EdgeColor','none');

fill([0 roadLength roadLength 0], ...
    [-7 -7 -45 -45], ...
    [0.55 0.75 0.40], ...
    'EdgeColor','none');

%% ---------------- EGO VEHICLE ----------------
ego = rectangle( ...
    'Position',[egoX-5 egoY-1.6 10 3.2], ...
    'Curvature',0.2, ...
    'FaceColor',[0 0.4 0.9]);

%% ---------------- CATTLE ----------------
cattlePositions = [260 620 1010 1450];
cattleY = [25 30 -25 27];

cows = gobjects(1,length(cattlePositions));

for i = 1:length(cattlePositions)

    cows(i) = rectangle( ...
        'Position',[cattlePositions(i)-3 cattleY(i)-2 6 4], ...
        'Curvature',0.3, ...
        'FaceColor',[0.65 0.45 0.25], ...
        'Visible','off');

end

%% ---------------- TREES ----------------
treePositions = 100:90:1750;

trees = gobjects(1,length(treePositions));

for i = 1:length(treePositions)

    trees(i) = plot( ...
        treePositions(i), ...
        18 + 8*mod(i,2), ...
        'o', ...
        'MarkerSize',20, ...
        'MarkerFaceColor',[0.15 0.5 0.15], ...
        'MarkerEdgeColor','none', ...
        'Visible','off');

end

%% ---------------- HOUSES ----------------
housePositions = [400 850 1250 1650];

houses = gobjects(1,length(housePositions));

for i = 1:length(housePositions)

    houses(i) = rectangle( ...
        'Position',[housePositions(i) 16 18 12], ...
        'FaceColor',[0.85 0.68 0.48], ...
        'EdgeColor','k', ...
        'Visible','off');

end

%% ---------------- STATUS ----------------
status = text(5,38, ...
    'SYSTEM: SCANNING ROAD', ...
    'FontSize',14, ...
    'FontWeight','bold');

%% ---------------- ANIMATION ----------------
for k = 1:N

    t = (k-1)*dt;

    %% Vehicle continuously travels forward
    egoX = egoX + vehicleSpeed*dt;

    %% Camera follows vehicle
    xMin = egoX - 50;
    xMax = egoX + 90;

    xMin = max(0,xMin);
    xMax = min(roadLength,xMax);

    xlim([xMin xMax]);

    %% CATTLE CROSSING
    for i = 1:length(cattlePositions)

        distance = cattlePositions(i) - egoX;

        % Cattle becomes visible near vehicle
        if abs(distance) < 90

            set(cows(i),'Visible','on');

            % Cross road when vehicle approaches
            if distance > 0 && distance < 45

                if cattleY(i) > 0
                    cattleY(i) = cattleY(i) - 0.25;
                else
                    cattleY(i) = cattleY(i) + 0.25;
                end

            end

            set(cows(i),'Position', ...
                [cattlePositions(i)-3 cattleY(i)-2 6 4]);

        else
            set(cows(i),'Visible','off');
        end

    end

    %% TREES APPEAR AS VEHICLE APPROACHES
    for i = 1:length(treePositions)

        if abs(treePositions(i)-egoX) < 100
            set(trees(i),'Visible','on');
        else
            set(trees(i),'Visible','off');
        end

    end

    %% HOUSES
    for i = 1:length(housePositions)

        if abs(housePositions(i)-egoX) < 100
            set(houses(i),'Visible','on');
        else
            set(houses(i),'Visible','off');
        end

    end

    %% ---------------- DETECTION ----------------

    closestCattle = min(abs(cattlePositions-egoX));

    if closestCattle < 45

        set(status,'String', ...
            sprintf('WARNING: CATTLE DETECTED | %.1f m', ...
            closestCattle));

        vehicleSpeed = max(4,vehicleSpeed-0.08);

    elseif closestCattle < 90

        set(status,'String','CAUTION: CATTLE AHEAD');

    else

        set(status,'String','ROAD CLEAR - AUTONOMOUS CRUISING');

        vehicleSpeed = min(17,vehicleSpeed+0.03);

    end

    %% Update vehicle
    set(ego,'Position', ...
        [egoX-5 egoY-1.6 10 3.2]);

    drawnow;

    pause(0.01);

end
