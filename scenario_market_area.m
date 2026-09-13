%% =========================================================
% DENSE MARKET AUTONOMOUS VEHICLE
%
% MATLAB ONLY - NO SIMULINK
%
% FEATURES:
%   - Dense market environment
%   - Roadside vending machines / stalls
%   - Vendors crossing the road
%   - Pedestrians crossing the road
%   - Pedestrian/vendor detection
%   - Automatic stopping and resuming
%   - Traffic light detection
%   - GREEN / RED traffic light
%   - Red-light stopping near stop line
%   - 5-second red-light waiting
%   - Road construction detection
%   - Slow -> Stop -> 5 second wait
%   - Forward alternate road
%   - Kinematic bicycle model
%   - Pure Pursuit lateral control
%   - PID longitudinal control
%   - Longer animation
%% =========================================================

clear;
clc;
close all;

%% =========================================================
% SIMULATION SETTINGS
%% =========================================================

dt = 0.05;

% Long animation
simulationTime = 350;

%% =========================================================
% VEHICLE PARAMETERS
%% =========================================================

x = 10;
y = 0;

yaw = 0;
speed = 0;

wheelbase = 2.8;

maxSteer = deg2rad(25);

% Normal market speed
normalSpeed = 4.8;

% Reduced speed near crossing
crossingSpeed = 3.5;

% Construction approach speed
constructionSpeed = 2.7;

% Alternate road speed
alternateSpeed = 3.5;

maxAcceleration = 1.1;
maxBraking = 3.5;

%% =========================================================
% PURE PURSUIT
%% =========================================================

lookAhead = 7;

%% =========================================================
% PID CONTROLLER
%% =========================================================

Kp_speed = 1.4;
Ki_speed = 0.04;
Kd_speed = 0.08;

speedIntegral = 0;
previousSpeedError = 0;

%% =========================================================
% MAIN MARKET ROAD
%% =========================================================

roadStart = 0;
roadEnd = 320;

roadWidth = 9;

%% =========================================================
% TRAFFIC LIGHT
%% =========================================================

trafficLightX = 115;

stopLine = trafficLightX - 12;

lightState = "GREEN";

greenTime = 20;
redTime = 12;

lightTimer = 0;

redDetected = false;
redStopped = false;

redStopStart = NaN;

redWaitTime = 5;

%% =========================================================
% INTERSECTION ROAD
%% =========================================================

intersectionRoadWidth = 8;

intersectionBottom = -23;
intersectionTop = 25;

%% =========================================================
% VENDORS CROSSING
%% =========================================================

numberOfVendors = 3;

vendorX = [145 153 161];

% Start below the road
vendorY = [-12 -13 -11];

vendorMoveSpeed = 2.3;

vendorStarted = false;
vendorFinished = false;
vendorDetected = false;

vendorDetectionDistance = 16;

vendorHandles = gobjects(numberOfVendors,1);

%% =========================================================
% PEDESTRIANS CROSSING
%% =========================================================

numberOfPedestrians = 4;

pedX = [185 191 197 203];

% Start above the road
pedY = [12 13 11 12];

pedMoveSpeed = 2.0;

pedestriansStarted = false;
pedestriansFinished = false;
pedestriansDetected = false;

pedestrianDetectionDistance = 16;

pedHandles = gobjects(numberOfPedestrians,1);

%% =========================================================
% CONSTRUCTION
%% =========================================================

constructionX = 245;

constructionWidth = 14;

constructionDetected = false;
constructionStopped = false;

constructionWaitStart = NaN;

constructionWaitTime = 5;

detourActive = false;

%% =========================================================
% ALTERNATE ROAD
%% =========================================================

routeX = [233 240 250 263 280 298 315];

routeY = [0 -3 -6 -8 -7 -4 0];

routeIndex = 2;

alternateRoadWidth = 6;

%% =========================================================
% MARKET BUILDINGS
%% =========================================================

buildingX = [15 34 53 72 92 ...
             135 155 175 205 225 ...
             270 290 310];

buildingY = [15 17 15 18 16 ...
             16 18 15 17 15 ...
             17 15 17];

buildingW = [14 15 13 14 15 ...
             12 14 13 14 12 ...
             14 13 12];

buildingH = [9 10 9 11 10 ...
             9 10 8 10 9 ...
             10 9 10];

%% =========================================================
% TREES
%% =========================================================

treeX = [10 28 48 68 88 105 ...
         135 175 215 265 300];

treeY = [-14 -16 -14 -15 -13 -15 ...
         -14 -16 -14 -16 -14];

%% =========================================================
% VENDING MACHINES / MARKET STALLS
%% =========================================================

vendingX = [22 42 62 82 102 ...
            135 155 175 205 225 ...
            270 292 310];

vendingY = [7 7 7 7 7 ...
            -7 -7 -7 -7 -7 ...
            7 7 7];

vendingHandles = gobjects(length(vendingX),1);

%% =========================================================
% FIGURE
%% =========================================================

figure('Color','w');

hold on;
grid on;

axis manual;

xlim([-10 340]);
ylim([-25 28]);

xlabel('X Position (m)');
ylabel('Y Position (m)');

%% =========================================================
% MAIN ROAD
%% =========================================================

fill([roadStart roadEnd roadEnd roadStart], ...
     [-roadWidth/2 -roadWidth/2 ...
       roadWidth/2 roadWidth/2], ...
     [0.30 0.30 0.30], ...
     'EdgeColor','none');

%% Road center

plot([roadStart roadEnd], ...
     [0 0], ...
     '--', ...
     'Color',[0.85 0.85 0.85], ...
     'LineWidth',1.5);

%% Road edges

plot([roadStart roadEnd], ...
     [roadWidth/2 roadWidth/2], ...
     'w', ...
     'LineWidth',2);

plot([roadStart roadEnd], ...
     [-roadWidth/2 -roadWidth/2], ...
     'w', ...
     'LineWidth',2);

%% =========================================================
% INTERSECTION ROAD
%% =========================================================

fill([trafficLightX-4 ...
      trafficLightX+4 ...
      trafficLightX+4 ...
      trafficLightX-4], ...
     [intersectionBottom ...
      intersectionBottom ...
      intersectionTop ...
      intersectionTop], ...
     [0.27 0.27 0.27], ...
     'EdgeColor','none');

%% Intersection center line

plot([trafficLightX trafficLightX], ...
     [intersectionBottom intersectionTop], ...
     '--', ...
     'Color',[0.85 0.85 0.85], ...
     'LineWidth',1.3);

%% Intersection edges

plot([trafficLightX-4 trafficLightX-4], ...
     [intersectionBottom intersectionTop], ...
     'w', ...
     'LineWidth',2);

plot([trafficLightX+4 trafficLightX+4], ...
     [intersectionBottom intersectionTop], ...
     'w', ...
     'LineWidth',2);

text(trafficLightX-14,23, ...
     'MARKET INTERSECTION', ...
     'FontWeight','bold');

%% =========================================================
% STOP LINE
%% =========================================================

plot([stopLine stopLine], ...
     [-4.5 4.5], ...
     'w', ...
     'LineWidth',4);

text(stopLine-7,5.5, ...
     'STOP LINE', ...
     'FontWeight','bold');

%% =========================================================
% TRAFFIC LIGHT POLE
%% =========================================================

plot([trafficLightX-8 trafficLightX-8], ...
     [5 14], ...
     'k', ...
     'LineWidth',3);

%% Traffic light housing

fill([trafficLightX-10 ...
      trafficLightX-6 ...
      trafficLightX-6 ...
      trafficLightX-10], ...
     [9 9 15 15], ...
     [0.10 0.10 0.10], ...
     'EdgeColor','k');

%% Lamps

greenLamp = plot(trafficLightX-8,13.5, ...
     'o', ...
     'MarkerSize',11, ...
     'MarkerFaceColor','g', ...
     'MarkerEdgeColor','k');

yellowLamp = plot(trafficLightX-8,12, ...
     'o', ...
     'MarkerSize',11, ...
     'MarkerFaceColor',[0.5 0.5 0.5], ...
     'MarkerEdgeColor','k');

redLamp = plot(trafficLightX-8,10.5, ...
     'o', ...
     'MarkerSize',11, ...
     'MarkerFaceColor',[0.5 0.5 0.5], ...
     'MarkerEdgeColor','k');

text(trafficLightX-18,17, ...
     'TRAFFIC LIGHT', ...
     'FontWeight','bold');

%% =========================================================
% ALTERNATE ROAD AROUND CONSTRUCTION
%% =========================================================

for i = 1:length(routeX)-1

    x1 = routeX(i);
    x2 = routeX(i+1);

    y1 = routeY(i);
    y2 = routeY(i+1);

    fill([x1 x2 x2 x1], ...
         [y1-alternateRoadWidth/2 ...
          y2-alternateRoadWidth/2 ...
          y2+alternateRoadWidth/2 ...
          y1+alternateRoadWidth/2], ...
         [0.27 0.27 0.27], ...
         'EdgeColor','none');

end

plot(routeX,routeY, ...
     '--', ...
     'Color',[0.85 0.85 0.85], ...
     'LineWidth',1.5);

plot(routeX, ...
     routeY+alternateRoadWidth/2, ...
     'k', ...
     'LineWidth',2);

plot(routeX, ...
     routeY-alternateRoadWidth/2, ...
     'k', ...
     'LineWidth',2);

text(255,-13, ...
     'ALTERNATE MARKET ROAD', ...
     'FontWeight','bold');

%% =========================================================
% CONSTRUCTION
%% =========================================================

constructionLeft = constructionX-constructionWidth/2;
constructionRight = constructionX+constructionWidth/2;

fill([constructionLeft constructionRight ...
      constructionRight constructionLeft], ...
     [-4.5 -4.5 4.5 4.5], ...
     [1 0.70 0.10], ...
     'EdgeColor','k', ...
     'LineWidth',2);

for xx = constructionLeft:2:constructionRight

    plot([xx xx+2], ...
         [-4.5 4.5], ...
         'r', ...
         'LineWidth',2);

end

text(constructionX-14,7, ...
     'ROAD UNDER CONSTRUCTION', ...
     'Color','r', ...
     'FontWeight','bold');

%% =========================================================
% MARKET BUILDINGS
%% =========================================================

for i = 1:length(buildingX)

    bx = buildingX(i);
    by = buildingY(i);

    bw = buildingW(i);
    bh = buildingH(i);

    fill([bx-bw/2 bx+bw/2 ...
          bx+bw/2 bx-bw/2], ...
         [by-bh/2 by-bh/2 ...
          by+bh/2 by+bh/2], ...
         [0.72 0.55 0.35], ...
         'EdgeColor','k');

    %% Roof

    plot([bx-bw/2 bx bx+bw/2], ...
         [by+bh/2 ...
          by+bh/2+4 ...
          by+bh/2], ...
         'k', ...
         'LineWidth',2);

    %% Door

    plot([bx bx], ...
         [by-bh/2 by-bh/2+3], ...
         'k', ...
         'LineWidth',2);

end

%% =========================================================
% TREES
%% =========================================================

for i = 1:length(treeX)

    plot(treeX(i),treeY(i), ...
         'o', ...
         'MarkerSize',11, ...
         'MarkerFaceColor',[0.10 0.60 0.10], ...
         'MarkerEdgeColor','k');

end

%% =========================================================
% VENDING MACHINES / STALLS
%% =========================================================

for i = 1:length(vendingX)

    vendingHandles(i) = plot( ...
        vendingX(i), ...
        vendingY(i), ...
        's', ...
        'MarkerSize',9, ...
        'MarkerFaceColor',[0.95 0.55 0.10], ...
        'MarkerEdgeColor','k');

end

text(15,-9, ...
     'VENDING MACHINES / MARKET STALLS', ...
     'Color',[0.80 0.35 0.05], ...
     'FontWeight','bold');

%% =========================================================
% VENDORS
%% =========================================================

for i = 1:numberOfVendors

    vendorHandles(i) = plot( ...
        vendorX(i), ...
        vendorY(i), ...
        's', ...
        'MarkerSize',10, ...
        'MarkerFaceColor',[0.85 0.20 0.20], ...
        'MarkerEdgeColor','k');

end

text(137,-17, ...
     'VENDORS CROSSING', ...
     'Color',[0.70 0.10 0.10], ...
     'FontWeight','bold');

%% =========================================================
% PEDESTRIANS
%% =========================================================

for i = 1:numberOfPedestrians

    pedHandles(i) = plot( ...
        pedX(i), ...
        pedY(i), ...
        'o', ...
        'MarkerSize',9, ...
        'MarkerFaceColor',[0.65 0.10 0.75], ...
        'MarkerEdgeColor','k');

end

text(180,17, ...
     'PEDESTRIANS CROSSING', ...
     'Color',[0.55 0.05 0.65], ...
     'FontWeight','bold');

%% =========================================================
% AUTONOMOUS VEHICLE
%% =========================================================

carLength = 5;
carWidth = 2.2;

carX = [-carLength/2 ...
         carLength/2 ...
         carLength/2 ...
        -carLength/2];

carY = [-carWidth/2 ...
        -carWidth/2 ...
         carWidth/2 ...
         carWidth/2];

vehiclePatch = patch( ...
    x+carX, ...
    y+carY, ...
    'b', ...
    'EdgeColor','k', ...
    'LineWidth',1.5);

headingLine = plot( ...
    [x x+3], ...
    [y y], ...
    'b', ...
    'LineWidth',2);

%% =========================================================
% SIMULATION LOOP
%% =========================================================

for t = 0:dt:simulationTime

    %% Default

    targetSpeed = normalSpeed;

    statusText = "NORMAL";

    %% =====================================================
    % TRAFFIC LIGHT TIMER
    %% =====================================================

    lightTimer = lightTimer + dt;

    %% GREEN -> RED

    if strcmp(lightState,"GREEN")

        if lightTimer >= greenTime

            lightState = "RED";

            lightTimer = 0;

        end

    %% RED -> GREEN

    elseif strcmp(lightState,"RED")

        if lightTimer >= redTime

            lightState = "GREEN";

            lightTimer = 0;

        end

    end

    %% =====================================================
    % TRAFFIC LIGHT GRAPHICS
    %% =====================================================

    if strcmp(lightState,"GREEN")

        set(greenLamp, ...
            'MarkerFaceColor','g');

        set(yellowLamp, ...
            'MarkerFaceColor',[0.5 0.5 0.5]);

        set(redLamp, ...
            'MarkerFaceColor',[0.5 0.5 0.5]);

    else

        set(greenLamp, ...
            'MarkerFaceColor',[0.5 0.5 0.5]);

        set(yellowLamp, ...
            'MarkerFaceColor',[0.5 0.5 0.5]);

        set(redLamp, ...
            'MarkerFaceColor','r');

    end

    %% =====================================================
    % RED LIGHT DETECTION
    %
    % The vehicle reacts only when the red light is close.
    %% =====================================================

    distanceToStopLine = stopLine-x;

    if strcmp(lightState,"RED") && ...
            distanceToStopLine > 0 && ...
            distanceToStopLine < 12 && ...
            ~detourActive

        redDetected = true;

    end

    %% =====================================================
    % RED LIGHT STOP
    %% =====================================================

    if redDetected && ...
            ~redStopped && ...
            ~detourActive

        targetSpeed = 0;

        statusText = "RED LIGHT DETECTED - STOPPING";

        %% Start timer only after actual stop

        if speed < 0.25

            redStopped = true;

            redStopStart = t;

        end

    end

    %% =====================================================
    % RED LIGHT 5 SECOND WAIT
    %% =====================================================

    if redStopped && ~detourActive

        targetSpeed = 0;

        statusText = "RED LIGHT - WAITING 5 SEC";

        if t-redStopStart >= redWaitTime

            redStopped = false;

            redDetected = false;

            redStopStart = NaN;

            statusText = "RED LIGHT CLEAR - RESUMING";

        end

    end

    %% =====================================================
    % START VENDORS
    %% =====================================================

    if ~vendorStarted && ...
            x >= 125

        vendorStarted = true;

    end

    %% =====================================================
    % MOVE VENDORS
    %% =====================================================

    if vendorStarted && ...
            ~vendorFinished

        for i = 1:numberOfVendors

            if vendorY(i) < 11

                vendorY(i) = vendorY(i) ...
                    + vendorMoveSpeed*dt;

            end

        end

        if all(vendorY >= 10)

            vendorFinished = true;

        end

    end

    %% =====================================================
    % DETECT VENDORS
    %% =====================================================

    if vendorStarted && ...
            ~vendorFinished && ...
            ~detourActive

        nearestVendor = inf;

        for i = 1:numberOfVendors

            if vendorY(i) < 10

                d = sqrt( ...
                    (vendorX(i)-x)^2 + ...
                    (vendorY(i)-y)^2);

                if d < nearestVendor

                    nearestVendor = d;

                end

            end

        end

        if nearestVendor < vendorDetectionDistance && ...
                x < 175

            vendorDetected = true;

        end

    end

    %% =====================================================
    % STOP FOR VENDORS
    %% =====================================================

    if vendorDetected && ...
            ~vendorFinished && ...
            ~detourActive

        targetSpeed = 0;

        statusText = "VENDORS DETECTED - STOPPING";

    end

    %% =====================================================
    % VENDORS CLEAR
    %% =====================================================

    if vendorDetected && vendorFinished

        vendorDetected = false;

        targetSpeed = crossingSpeed;

        statusText = "VENDORS CLEAR - RESUMING";

    end

    %% =====================================================
    % START PEDESTRIANS
    %% =====================================================

    if ~pedestriansStarted && ...
            x >= 165 && ...
            vendorFinished

        pedestriansStarted = true;

    end

    %% =====================================================
    % MOVE PEDESTRIANS
    %% =====================================================

    if pedestriansStarted && ...
            ~pedestriansFinished

        for i = 1:numberOfPedestrians

            if pedY(i) > -10

                pedY(i) = pedY(i) ...
                    - pedMoveSpeed*dt;

            end

        end

        if all(pedY <= -10)

            pedestriansFinished = true;

        end

    end

    %% =====================================================
    % DETECT PEDESTRIANS
    %% =====================================================

    if pedestriansStarted && ...
            ~pedestriansFinished && ...
            ~detourActive

        nearestPedestrian = inf;

        for i = 1:numberOfPedestrians

            if pedY(i) > -10

                d = sqrt( ...
                    (pedX(i)-x)^2 + ...
                    (pedY(i)-y)^2);

                if d < nearestPedestrian

                    nearestPedestrian = d;

                end

            end

        end

        if nearestPedestrian < pedestrianDetectionDistance && ...
                x < 225

            pedestriansDetected = true;

        end

    end

    %% =====================================================
    % STOP FOR PEDESTRIANS
    %% =====================================================

    if pedestriansDetected && ...
            ~pedestriansFinished && ...
            ~detourActive

        targetSpeed = 0;

        statusText = "PEDESTRIANS DETECTED - STOPPING";

    end

    %% =====================================================
    % PEDESTRIANS CLEAR
    %% =====================================================

    if pedestriansDetected && pedestriansFinished

        pedestriansDetected = false;

        targetSpeed = crossingSpeed;

        statusText = "PEDESTRIANS CLEAR - RESUMING";

    end

    %% =====================================================
    % CONSTRUCTION DETECTION
    %% =====================================================

    distanceConstruction = constructionX-x;

    if ~constructionDetected && ...
            distanceConstruction > 0 && ...
            distanceConstruction < 38

        constructionDetected = true;

    end

    %% =====================================================
    % CONSTRUCTION RESPONSE
    %% =====================================================

    if constructionDetected && ...
            ~detourActive && ...
            ~redStopped && ...
            ~vendorDetected && ...
            ~pedestriansDetected

        if distanceConstruction > 8

            targetSpeed = constructionSpeed;

            statusText = "CONSTRUCTION DETECTED - SLOWING";

        else

            targetSpeed = 0;

            statusText = "CONSTRUCTION - STOPPING";

        end

        %% Actual stop

        if distanceConstruction <= 8 && ...
                speed < 0.25

            constructionStopped = true;

            if isnan(constructionWaitStart)

                constructionWaitStart = t;

            end

        end

    end

    %% =====================================================
    % CONSTRUCTION 5 SECOND WAIT
    %% =====================================================

    if constructionStopped && ~detourActive

        targetSpeed = 0;

        statusText = "CONSTRUCTION - WAITING 5 SEC";

        if t-constructionWaitStart >= constructionWaitTime

            detourActive = true;

            routeIndex = 2;

            statusText = "TAKING ALTERNATE MARKET ROAD";

        end

    end

    %% =====================================================
    % ALTERNATE ROAD
    %% =====================================================

    if detourActive

        while routeIndex < length(routeX) && ...
                x >= routeX(routeIndex)-1

            routeIndex = routeIndex+1;

        end

        targetX = routeX(routeIndex);
        targetY = routeY(routeIndex);

        targetSpeed = alternateSpeed;

        statusText = "ALTERNATE ROAD - MOVING";

        %% Rejoin main road

        if routeIndex == length(routeX) && ...
                x >= routeX(end)-2

            detourActive = false;

            constructionDetected = false;
            constructionStopped = false;
            constructionWaitStart = NaN;

            targetX = x+lookAhead;
            targetY = 0;

            statusText = "MERGED BACK TO MARKET ROAD";

        end

    else

        %% Main road target

        targetX = x+lookAhead;
        targetY = 0;

    end

    %% =====================================================
    % PURE PURSUIT STEERING
    %% =====================================================

    dx = targetX-x;
    dy = targetY-y;

    targetHeading = atan2(dy,dx);

    headingError = atan2( ...
        sin(targetHeading-yaw), ...
        cos(targetHeading-yaw));

    steeringAngle = atan2( ...
        2*wheelbase*sin(headingError), ...
        lookAhead);

    %% Steering limit

    if steeringAngle > maxSteer

        steeringAngle = maxSteer;

    elseif steeringAngle < -maxSteer

        steeringAngle = -maxSteer;

    end

    %% =====================================================
    % PID LONGITUDINAL CONTROL
    %% =====================================================

    speedError = targetSpeed-speed;

    speedIntegral = speedIntegral + ...
        speedError*dt;

    %% Anti-windup

    if speedIntegral > 10

        speedIntegral = 10;

    elseif speedIntegral < -10

        speedIntegral = -10;

    end

    speedDerivative = ...
        (speedError-previousSpeedError)/dt;

    control = ...
        Kp_speed*speedError + ...
        Ki_speed*speedIntegral + ...
        Kd_speed*speedDerivative;

    previousSpeedError = speedError;

    %% =====================================================
    % ACCELERATION / BRAKING
    %% =====================================================

    if control >= 0

        acceleration = min( ...
            control, ...
            maxAcceleration);

    else

        acceleration = max( ...
            control, ...
            -maxBraking);

    end

    %% =====================================================
    % UPDATE SPEED
    %% =====================================================

    speed = speed + acceleration*dt;

    if speed < 0

        speed = 0;

    end

    %% Force complete stop

    if targetSpeed == 0 && speed < 0.18

        speed = 0;

    end

    %% =====================================================
    % KINEMATIC BICYCLE MODEL
    %% =====================================================

    if speed > 0.03

        yaw = yaw + ...
            (speed/wheelbase)*tan(steeringAngle)*dt;

    end

    x = x + speed*cos(yaw)*dt;

    y = y + speed*sin(yaw)*dt;

    %% =====================================================
    % KEEP VEHICLE ON MAIN ROAD
    %% =====================================================

    if ~detourActive

        if y > 3.8

            y = 3.8;

        elseif y < -3.8

            y = -3.8;

        end

    end

    %% =====================================================
    % UPDATE VENDORS
    %% =====================================================

    for i = 1:numberOfVendors

        set(vendorHandles(i), ...
            'XData',vendorX(i), ...
            'YData',vendorY(i));

    end

    %% =====================================================
    % UPDATE PEDESTRIANS
    %% =====================================================

    for i = 1:numberOfPedestrians

        set(pedHandles(i), ...
            'XData',pedX(i), ...
            'YData',pedY(i));

    end

    %% =====================================================
    % UPDATE VEHICLE
    %% =====================================================

    rotatedX = ...
        carX*cos(yaw)- ...
        carY*sin(yaw);

    rotatedY = ...
        carX*sin(yaw)+ ...
        carY*cos(yaw);

    set(vehiclePatch, ...
        'XData',x+rotatedX, ...
        'YData',y+rotatedY);

    set(headingLine, ...
        'XData',[x x+3*cos(yaw)], ...
        'YData',[y y+3*sin(yaw)]);

    %% =====================================================
    % STATUS TITLE
    %% =====================================================

    title(sprintf( ...
        'DENSE MARKET | %.1f m/s | %.1f km/h | %s | LIGHT: %s', ...
        speed, ...
        speed*3.6, ...
        statusText, ...
        lightState));

    %% =====================================================
    % CAMERA FOLLOW
    %% =====================================================

    xlim([x-35 x+45]);

    ylim([-25 28]);

    %% =====================================================
    % LONGER SMOOTH ANIMATION
    %% =====================================================

    if mod(round(t/dt),3) == 0

        drawnow limitrate;

    end

    pause(0.018);

    %% =====================================================
    % ROAD END
    %% =====================================================

    if x >= roadEnd-2

        speed = 0;

        title('DENSE MARKET | ROAD END - SIMULATION COMPLETE');

        drawnow;

        pause(3);

        break;

    end

end

%% =========================================================
% COMPLETION MESSAGE
%% =========================================================

disp(' ');
disp('======================================================');
disp(' DENSE MARKET SIMULATION COMPLETE');
disp('======================================================');
disp('Vending machines / stalls: PRESENT');
disp('Vendors crossing: DETECTED');
disp('Vendor stopping: COMPLETED');
disp('Pedestrians crossing: DETECTED');
disp('Pedestrian stopping: COMPLETED');
disp('Traffic light detection: COMPLETED');
disp('Red-light stopping: COMPLETED');
disp('5-second red-light wait: COMPLETED');
disp('Construction detection: COMPLETED');
disp('5-second construction wait: COMPLETED');
disp('Alternate route: COMPLETED');
disp('Vehicle reached road end.');
disp('======================================================');
