%% ============================================================
% VILLAGE ROAD AUTONOMOUS VEHICLE
% CATTLE + POTHOLE AVOIDANCE + TRAFFIC LIGHTS
% ============================================================
% MATLAB ONLY - NO SIMULINK
%
% FEATURES:
%   - Long continuous village road
%   - Autonomous vehicle
%   - Cattle crossing detection
%   - Vehicle stops for cattle
%   - Cattle completely crosses road
%   - Traffic lights
%   - Red = STOP
%   - Green = GO
%   - Pothole detection
%   - Automatic alternate path around pothole
%   - Vehicle returns to original lane
%   - Pedestrians
%   - Cyclists
%   - Houses
%   - Trees
%   - Approximately 90 seconds real-time
%% ============================================================

clear;
clc;
close all;

%% ============================================================
% SIMULATION PARAMETERS
%% ============================================================

simulationTime = 90;
dt = 0.10;
N = round(simulationTime/dt);

roadLength = 2200;
roadWidth = 14;

normalSpeed = 14;

egoX = 0;
egoY = 0;

egoSpeed = normalSpeed;

%% ============================================================
% FIGURE
%% ============================================================

figure( ...
    'Color',[0.70 0.88 1.00], ...
    'Name','Autonomous Village Road - Pothole Avoidance');

ax = axes;
hold(ax,'on');

xlim([0 180]);
ylim([-45 45]);

axis manual;

%% ============================================================
% GROUND
%% ============================================================

fill( ...
    [0 roadLength roadLength 0], ...
    [-45 -45 45 45], ...
    [0.55 0.78 0.40], ...
    'EdgeColor','none');

%% ============================================================
% ROAD
%% ============================================================

fill( ...
    [0 roadLength roadLength 0], ...
    [-7 -7 7 7], ...
    [0.25 0.25 0.25], ...
    'EdgeColor','none');

% Road boundaries
plot([0 roadLength],[7 7], ...
    'w','LineWidth',2);

plot([0 roadLength],[-7 -7], ...
    'w','LineWidth',2);

%% ============================================================
% CENTER LINE
%% ============================================================

for x = 0:20:roadLength

    plot([x x+10],[0 0], ...
        'w','LineWidth',1.5);

end

%% ============================================================
% HOUSES
%% ============================================================

houseX = [100 280 450 670 850 1040 ...
          1240 1430 1630 1830 2050];

houseY = [22 -24 23 -24 23 -24 ...
          22 -23 23 -24 22];

for i = 1:length(houseX)

    x = houseX(i);
    y = houseY(i);

    rectangle( ...
        'Position',[x y 20 13], ...
        'FaceColor',[0.90 0.70 0.45], ...
        'EdgeColor','k');

    patch( ...
        [x-3 x+10 x+23], ...
        [y+13 y+21 y+13], ...
        [0.65 0.20 0.15]);

    rectangle( ...
        'Position',[x+8 y 4 7], ...
        'FaceColor',[0.35 0.20 0.10]);

    rectangle( ...
        'Position',[x+2 y+5 5 4], ...
        'FaceColor',[0.50 0.80 1.00], ...
        'EdgeColor','k');

end

%% ============================================================
% TREES
%% ============================================================

treeX = [50 150 220 340 410 530 610 750 ...
         820 930 1010 1130 1210 1330 ...
         1410 1530 1610 1730 1810 1930 ...
         2010 2150];

treeY = [28 -30 30 -29 31 -30 29 -30 ...
         30 -30 29 -31 30 -29 31 -30 ...
         29 -31 30 -29 28 -30];

for i = 1:length(treeX)

    x = treeX(i);
    y = treeY(i);

    plot([x x],[y y+7], ...
        'Color',[0.35 0.20 0.10], ...
        'LineWidth',4);

    plot(x,y+9,'o', ...
        'MarkerSize',18, ...
        'MarkerFaceColor',[0.10 0.50 0.15], ...
        'MarkerEdgeColor',[0.05 0.30 0.05]);

end

%% ============================================================
% VILLAGE SIGN
%% ============================================================

plot([180 180],[14 25], ...
    'k','LineWidth',3);

text(180,28,'VILLAGE', ...
    'HorizontalAlignment','center', ...
    'FontWeight','bold');

%% ============================================================
% CATTLE CROSSING
%% ============================================================

cattleX = 540;
cattleY = -25;

cattleSpeed = 3.5;

cattleStarted = false;
cattleCleared = false;

%% ============================================================
% CATTLE GRAPHICS
%% ============================================================

cattleBody = rectangle( ...
    'Position',[cattleX-5 cattleY-2.5 10 5], ...
    'Curvature',0.35, ...
    'FaceColor',[0.70 0.50 0.25], ...
    'EdgeColor','k', ...
    'LineWidth',1.5);

cattleHead = plot( ...
    cattleX+5,cattleY+1,'o', ...
    'MarkerSize',7, ...
    'MarkerFaceColor',[0.60 0.40 0.20], ...
    'MarkerEdgeColor','k');

cattleLeg1 = plot( ...
    [cattleX-3 cattleX-3], ...
    [cattleY-2.5 cattleY-6], ...
    'k','LineWidth',2);

cattleLeg2 = plot( ...
    [cattleX+2 cattleX+2], ...
    [cattleY-2.5 cattleY-6], ...
    'k','LineWidth',2);

cattleLabel = text( ...
    cattleX,cattleY+7,'CATTLE', ...
    'HorizontalAlignment','center', ...
    'FontWeight','bold');

%% ============================================================
% TRAFFIC LIGHTS
%% ============================================================

trafficLightX = [330 900 1510 1960];

lightOffset = [0 5 11 16];

lightLamp = gobjects(1,length(trafficLightX));

for i = 1:length(trafficLightX)

    x = trafficLightX(i);

    plot([x x],[10 28], ...
        'k','LineWidth',3);

    rectangle( ...
        'Position',[x-3 25 6 10], ...
        'FaceColor',[0.08 0.08 0.08], ...
        'EdgeColor','k');

    lightLamp(i) = plot( ...
        x,31,'o', ...
        'MarkerSize',8, ...
        'MarkerFaceColor',[0.9 0 0], ...
        'MarkerEdgeColor','k');

end

%% ============================================================
% ============================================================
% POTHOLES
% ============================================================
% Potholes are positioned on the normal driving lane.
%
% Vehicle will:
%
%   DETECT
%      ↓
%   SLOW DOWN
%      ↓
%   MOVE TO ALTERNATE LANE
%      ↓
%   PASS POTHOLE
%      ↓
%   RETURN TO ORIGINAL LANE
%
%% ============================================================

potholeX = [720 1120 1660 2020];

% Potholes on the center of the vehicle path
potholeY = [0 0 0 0];

potholeHandled = false(1,length(potholeX));

potholeObject = gobjects(1,length(potholeX));
potholeCrack1 = gobjects(1,length(potholeX));
potholeCrack2 = gobjects(1,length(potholeX));

for i = 1:length(potholeX)

    x = potholeX(i);
    y = potholeY(i);

    potholeObject(i) = plot( ...
        x,y,'o', ...
        'MarkerSize',13, ...
        'MarkerFaceColor',[0.03 0.03 0.03], ...
        'MarkerEdgeColor',[0.01 0.01 0.01], ...
        'LineWidth',2);

    potholeCrack1(i) = plot( ...
        [x-6 x-3 x-1], ...
        [y+3 y+1 y+2], ...
        'k','LineWidth',1.5);

    potholeCrack2(i) = plot( ...
        [x+2 x+5 x+7], ...
        [y-2 y-4 y-2], ...
        'k','LineWidth',1.5);

end

%% ============================================================
% POTHOLE AVOIDANCE VARIABLES
%% ============================================================

avoidPothole = false;

activePothole = 0;

avoidPhase = 0;

% Lateral target for alternate path
alternateLaneY = 4.5;

% Detection distance
potholeDetectionDistance = 55;

% Distance before pothole to begin lane change
laneChangeStart = 40;

% Distance after pothole before returning
laneChangeEnd = 35;

%% ============================================================
% PEDESTRIANS
%% ============================================================

pedX = [250 780 1260 1780];
pedY = [18 -20 20 -18];

pedSpeed = [1.0 -0.8 0.7 -0.9];

pedObject = gobjects(1,length(pedX));

for i = 1:length(pedX)

    pedObject(i) = plot( ...
        pedX(i),pedY(i),'o', ...
        'MarkerSize',7, ...
        'MarkerFaceColor',[0.20 0.30 0.80], ...
        'MarkerEdgeColor','k');

end

%% ============================================================
% CYCLISTS
%% ============================================================

cycleX = [400 1000 1450 1900];
cycleY = [-4 4 -4 4];

cycleSpeed = [4 3.5 4 3];

cycleObject = gobjects(1,length(cycleX));

for i = 1:length(cycleX)

    cycleObject(i) = plot( ...
        cycleX(i),cycleY(i),'o', ...
        'MarkerSize',6, ...
        'MarkerFaceColor',[0.80 0.10 0.70], ...
        'MarkerEdgeColor','k');

end

%% ============================================================
% AUTONOMOUS VEHICLE
%% ============================================================

carLength = 8;
carWidth = 4;

carBody = rectangle( ...
    'Position',[egoX-carLength/2 ...
                egoY-carWidth/2 ...
                carLength ...
                carWidth], ...
    'Curvature',0.2, ...
    'FaceColor',[0.10 0.40 0.90], ...
    'EdgeColor','k', ...
    'LineWidth',1.5);

carWindow = rectangle( ...
    'Position',[egoX+0.5 ...
                egoY-1.4 ...
                2.5 ...
                2.8], ...
    'FaceColor',[0.70 0.90 1.00], ...
    'EdgeColor','k');

%% ============================================================
% STATUS
%% ============================================================

timeText = text( ...
    0,40,'', ...
    'FontSize',11, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');

statusText = text( ...
    0,35,'', ...
    'FontSize',10, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');

%% ============================================================
% REAL-TIME CLOCK
%% ============================================================

startClock = tic;

%% ============================================================
% MAIN LOOP
%% ============================================================

for k = 1:N

    simTime = (k-1)*dt;

    %% ========================================================
    % CATTLE START
    %% ========================================================

    if ~cattleStarted && ...
       ~cattleCleared && ...
       egoX >= cattleX-90

        cattleStarted = true;

    end

    %% ========================================================
    % MOVE CATTLE
    %% ========================================================

    if cattleStarted && ~cattleCleared

        cattleY = cattleY + cattleSpeed*dt;

        if cattleY >= 25

            cattleY = 25;

            cattleCleared = true;
            cattleStarted = false;

        end

    end

    %% ========================================================
    % UPDATE CATTLE
    %% ========================================================

    set(cattleBody, ...
        'Position',[cattleX-5 cattleY-2.5 10 5]);

    set(cattleHead, ...
        'XData',cattleX+5, ...
        'YData',cattleY+1);

    set(cattleLeg1, ...
        'XData',[cattleX-3 cattleX-3], ...
        'YData',[cattleY-2.5 cattleY-6]);

    set(cattleLeg2, ...
        'XData',[cattleX+2 cattleX+2], ...
        'YData',[cattleY-2.5 cattleY-6]);

    set(cattleLabel, ...
        'Position',[cattleX cattleY+7 0]);

    %% ========================================================
    % CATTLE DETECTION
    %% ========================================================

    cattleAhead = ...
        cattleX > egoX && ...
        cattleX-egoX < 75;

    cattleBlocking = ...
        cattleAhead && ...
        cattleY >= -10 && ...
        cattleY <= 10;

    %% ========================================================
    % TRAFFIC LIGHT STATES
    %% ========================================================

    lightState = zeros(1,length(trafficLightX));

    for i = 1:length(trafficLightX)

        cycleTime = mod( ...
            simTime+lightOffset(i),20);

        if cycleTime < 10

            lightState(i) = 1;

        else

            lightState(i) = 0;

        end

    end

    %% ========================================================
    % UPDATE TRAFFIC LIGHTS
    %% ========================================================

    for i = 1:length(trafficLightX)

        if lightState(i) == 1

            set(lightLamp(i), ...
                'MarkerFaceColor',[0 0.8 0]);

        else

            set(lightLamp(i), ...
                'MarkerFaceColor',[0.9 0 0]);

        end

    end

    %% ========================================================
    % RED LIGHT DETECTION
    %% ========================================================

    redLightAhead = false;

    for i = 1:length(trafficLightX)

        if trafficLightX(i) > egoX && ...
           trafficLightX(i)-egoX < 60 && ...
           lightState(i) == 0

            redLightAhead = true;

            break;

        end

    end

    %% ========================================================
    % FIND NEXT POTHOLE
    %% ========================================================

    nextPothole = 0;
    nearestDistance = inf;

    for i = 1:length(potholeX)

        if ~potholeHandled(i)

            distance = potholeX(i)-egoX;

            if distance > 0 && ...
               distance < nearestDistance

                nearestDistance = distance;
                nextPothole = i;

            end

        end

    end

    %% ========================================================
    % START POTHOLE AVOIDANCE
    %% ========================================================

    if ~avoidPothole && ...
       nextPothole ~= 0 && ...
       nearestDistance < potholeDetectionDistance

        avoidPothole = true;

        activePothole = nextPothole;

        avoidPhase = 1;

    end

    %% ========================================================
    % POTHOLE AVOIDANCE
    %% ========================================================

    if avoidPothole

        px = potholeX(activePothole);

        distanceToPothole = px-egoX;

        %% ----------------------------------------------------
        % PHASE 1: APPROACH
        %% ----------------------------------------------------

        if avoidPhase == 1

            % Slow down before pothole
            egoSpeed = 9;

            % Begin steering toward alternate lane
            if distanceToPothole < laneChangeStart

                avoidPhase = 2;

            end

        %% ----------------------------------------------------
        % PHASE 2: MOVE TO ALTERNATE PATH
        %% ----------------------------------------------------

        elseif avoidPhase == 2

            egoSpeed = 9;

            % Smooth lateral movement
            if egoY < alternateLaneY

                egoY = egoY + 1.2*dt;

            end

            % Once lateral position is achieved
            if egoY >= alternateLaneY-0.1

                egoY = alternateLaneY;

                avoidPhase = 3;

            end

        %% ----------------------------------------------------
        % PHASE 3: PASS POTHOLE
        %% ----------------------------------------------------

        elseif avoidPhase == 3

            egoSpeed = 10;

            % Stay in alternate lane while passing
            egoY = alternateLaneY;

            if egoX > px+laneChangeEnd

                avoidPhase = 4;

            end

        %% ----------------------------------------------------
        % PHASE 4: RETURN TO ORIGINAL LANE
        %% ----------------------------------------------------

        elseif avoidPhase == 4

            egoSpeed = normalSpeed;

            % Smoothly return to center
            if egoY > 0

                egoY = egoY - 1.2*dt;

            end

            if egoY <= 0.1

                egoY = 0;

                potholeHandled(activePothole) = true;

                avoidPothole = false;

                activePothole = 0;

                avoidPhase = 0;

            end

        end

    end

    %% ========================================================
    % AUTONOMOUS PRIORITY SYSTEM
    %% ========================================================

    % Cattle has highest priority.
    if cattleBlocking

        egoSpeed = 0;

        currentStatus = ...
            'CATTLE DETECTED - STOPPING';

    elseif redLightAhead

        egoSpeed = 0;

        currentStatus = ...
            'RED LIGHT DETECTED - STOPPING';

    elseif avoidPothole

        switch avoidPhase

            case 1
                currentStatus = ...
                    'POTHOLE DETECTED - SLOWING';

            case 2
                currentStatus = ...
                    'POTHOLE - TAKING ALTERNATE PATH';

            case 3
                currentStatus = ...
                    'PASSING POTHOLE - ALTERNATE PATH';

            case 4
                currentStatus = ...
                    'POTHOLE CLEARED - RETURNING TO LANE';

            otherwise
                currentStatus = ...
                    'ROAD CLEAR';

        end

    else

        egoSpeed = normalSpeed;

        currentStatus = ...
            'ROAD CLEAR - AUTONOMOUS DRIVING';

    end

    %% ========================================================
    % MOVE VEHICLE
    %% ========================================================

    egoX = egoX + egoSpeed*dt;

    %% ========================================================
    % UPDATE VEHICLE GRAPHICS
    %% ========================================================

    set(carBody, ...
        'Position',[egoX-carLength/2 ...
                    egoY-carWidth/2 ...
                    carLength ...
                    carWidth]);

    set(carWindow, ...
        'Position',[egoX+0.5 ...
                    egoY-1.4 ...
                    2.5 ...
                    2.8]);

    %% ========================================================
    % MOVE PEDESTRIANS
    %% ========================================================

    for i = 1:length(pedX)

        pedX(i) = pedX(i)+pedSpeed(i)*dt;

        if pedX(i) > roadLength
            pedX(i) = 0;
        end

        if pedX(i) < 0
            pedX(i) = roadLength;
        end

        set(pedObject(i), ...
            'XData',pedX(i), ...
            'YData',pedY(i));

    end

    %% ========================================================
    % MOVE CYCLISTS
    %% ========================================================

    for i = 1:length(cycleX)

        cycleX(i) = cycleX(i)+cycleSpeed(i)*dt;

        if cycleX(i) > roadLength
            cycleX(i) = 0;
        end

        set(cycleObject(i), ...
            'XData',cycleX(i), ...
            'YData',cycleY(i));

    end

    %% ========================================================
    % STATUS DISPLAY
    %% ========================================================

    set(timeText, ...
        'Position',[egoX 40 0], ...
        'String',sprintf( ...
        'AUTONOMOUS VILLAGE ROAD  |  %.1f / 90.0 s', ...
        simTime));

    set(statusText, ...
        'Position',[egoX 35 0], ...
        'String',currentStatus);

    %% ========================================================
    % CAMERA
    %% ========================================================

    leftView = max(0,egoX-60);
    rightView = min(roadLength,egoX+120);

    if rightView-leftView < 180

        rightView = leftView+180;

    end

    xlim([leftView rightView]);
    ylim([-45 45]);

    %% ========================================================
    % DISPLAY
    %% ========================================================

    drawnow;

    %% ========================================================
    % REAL-TIME PACING
    %% ========================================================

    targetElapsed = k*dt;
    actualElapsed = toc(startClock);

    waitTime = targetElapsed-actualElapsed;

    if waitTime > 0

        pause(waitTime);

    end

end

%% ============================================================
% END
%% ============================================================

disp(' ');
disp('============================================================');
disp('VILLAGE ROAD SIMULATION COMPLETE');
disp('============================================================');
disp('Cattle detection       : ENABLED');
disp('Traffic light detection: ENABLED');
disp('Pothole detection      : ENABLED');
disp('Alternate path         : ENABLED');
disp('Continuous driving     : ENABLED');
disp('============================================================');
