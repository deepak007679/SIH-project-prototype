%% =========================================================
% URBAN INTERSECTION AUTONOMOUS VEHICLE
%
% Features:
%   - Autonomous blue vehicle
%   - Urban intersection
%   - 3 cars passing from alternate/intersecting road
%   - Vehicle detects approaching cars
%   - Vehicle stops for the cars
%   - Cars pass through the intersection
%   - Vehicle resumes after all cars clear
%   - Road construction detection
%   - Slow -> Stop -> 5 second wait
%   - Forward alternate route around construction
%   - Buildings and trees
%   - Kinematic bicycle model
%   - Pure Pursuit style steering
%   - PID longitudinal control
%   - MATLAB only / NO SIMULINK
%% =========================================================

clear;
clc;
close all;

%% =========================================================
% SIMULATION SETTINGS
%% =========================================================

dt = 0.05;
simulationTime = 220;

%% =========================================================
% VEHICLE PARAMETERS
%% =========================================================

x = 10;
y = 0;

yaw = 0;
speed = 0;

wheelbase = 2.8;

maxSteer = deg2rad(25);

normalSpeed = 6.5;
intersectionSpeed = 4.5;
constructionSpeed = 3.5;

maxAcceleration = 1.5;
maxBraking = 4.0;

%% =========================================================
% PURE PURSUIT PARAMETERS
%% =========================================================

lookAhead = 7;

%% =========================================================
% PID PARAMETERS
%% =========================================================

Kp_speed = 1.5;
Ki_speed = 0.05;
Kd_speed = 0.10;

speedIntegral = 0;
previousSpeedError = 0;

%% =========================================================
% MAIN ROAD
%% =========================================================

roadStart = 0;
roadEnd = 300;

roadWidth = 9;

%% =========================================================
% URBAN INTERSECTION
%
% This road crosses the main road vertically.
%
% Your vehicle travels along:
%       X direction
%
% Other cars travel along:
%       Y direction
%% =========================================================

intersectionX = 125;

intersectionRoadWidth = 8;

intersectionRoadTop = 25;
intersectionRoadBottom = -25;

%% =========================================================
% THREE OTHER CARS
%% =========================================================

numberOfCars = 3;

otherCarX = [intersectionX ...
             intersectionX ...
             intersectionX];

otherCarY = [19 13 7];

otherCarSpeed = [5.0 5.2 4.8];

otherCarsStarted = false;

otherCarsFinished = false;

otherCarHandles = gobjects(numberOfCars,1);

%% Detection distance

carDetectionDistance = 18;

carsDetected = false;

%% =========================================================
% ROAD CONSTRUCTION
%% =========================================================

constructionX = 205;

constructionWidth = 14;

constructionDetected = false;
constructionStopped = false;

constructionWaitStart = NaN;
constructionWaitTime = 5;

detourActive = false;

%% =========================================================
% FORWARD ALTERNATE ROAD
%
% This road branches around construction and reconnects
% to the main road.
%% =========================================================

routeX = [193 200 210 223 240 260 280 300];

routeY = [0 -3 -6 -8 -8 -6 -3 0];

routeIndex = 2;

alternateRoadWidth = 6;

%% =========================================================
% BUILDINGS
%% =========================================================

buildingX = [18 45 75 105 150 175 230 270];

buildingY = [14 16 15 17 15 17 15 16];

buildingW = [12 14 11 13 12 13 14 12];

buildingH = [9 10 8 10 9 10 9 10];

%% =========================================================
% TREES
%% =========================================================

treeX = [10 32 58 88 112 145 165 190 225 250 285];

treeY = [-14 -16 -14 -15 -14 -15 -13 -16 -14 -16 -14];

%% =========================================================
% FIGURE
%% =========================================================

figure('Color','w');

hold on;
grid on;

axis manual;

xlim([-10 315]);
ylim([-25 30]);

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

%% Road center line

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
% INTERSECTION / ALTERNATE ROAD
%% =========================================================

fill([intersectionX-intersectionRoadWidth/2 ...
      intersectionX+intersectionRoadWidth/2 ...
      intersectionX+intersectionRoadWidth/2 ...
      intersectionX-intersectionRoadWidth/2], ...
     [intersectionRoadBottom ...
      intersectionRoadBottom ...
      intersectionRoadTop ...
      intersectionRoadTop], ...
     [0.28 0.28 0.28], ...
     'EdgeColor','none');

%% Intersection road center

plot([intersectionX intersectionX], ...
     [intersectionRoadBottom intersectionRoadTop], ...
     '--', ...
     'Color',[0.85 0.85 0.85], ...
     'LineWidth',1.5);

%% Intersection road edges

plot([intersectionX-intersectionRoadWidth/2 ...
      intersectionX-intersectionRoadWidth/2], ...
     [intersectionRoadBottom intersectionRoadTop], ...
     'w', ...
     'LineWidth',2);

plot([intersectionX+intersectionRoadWidth/2 ...
      intersectionX+intersectionRoadWidth/2], ...
     [intersectionRoadBottom intersectionRoadTop], ...
     'w', ...
     'LineWidth',2);

text(intersectionX-13,23, ...
     'ALTERNATE / INTERSECTION ROAD', ...
     'FontWeight','bold');

%% =========================================================
% ALTERNATE ROUTE AROUND CONSTRUCTION
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

%% =========================================================
% CONSTRUCTION AREA
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
% BUILDINGS
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
         [0.72 0.58 0.40], ...
         'EdgeColor','k');

    %% Roof

    plot([bx-bw/2 bx bx+bw/2], ...
         [by+bh/2 by+bh/2+4 by+bh/2], ...
         'k', ...
         'LineWidth',2);

end

%% =========================================================
% TREES
%% =========================================================

for i = 1:length(treeX)

    plot(treeX(i),treeY(i), ...
         'o', ...
         'MarkerSize',12, ...
         'MarkerFaceColor',[0.10 0.60 0.10], ...
         'MarkerEdgeColor','k');

end

%% =========================================================
% OTHER CAR GRAPHICS
%% =========================================================

for i = 1:numberOfCars

    otherCarHandles(i) = plot( ...
        otherCarX(i), ...
        otherCarY(i), ...
        's', ...
        'MarkerSize',11, ...
        'MarkerFaceColor',[0.85 0.15 0.15], ...
        'MarkerEdgeColor','k');

end

text(intersectionX+5,17, ...
     '3 CARS CROSSING', ...
     'Color','r', ...
     'FontWeight','bold');

%% =========================================================
% AUTONOMOUS VEHICLE GRAPHICS
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

    %% Default target speed

    targetSpeed = normalSpeed;

    statusText = "NORMAL";

    %% =====================================================
    % START THE THREE CARS
    %
    % They begin crossing when the autonomous vehicle gets
    % reasonably close to the intersection.
    %% =====================================================

    if ~otherCarsStarted && x >= intersectionX-30

        otherCarsStarted = true;

    end

    %% =====================================================
    % MOVE THE THREE OTHER CARS
    %
    % They travel from the upper side of the intersection
    % toward the lower side.
    %% =====================================================

    if otherCarsStarted && ~otherCarsFinished

        for i = 1:numberOfCars

            if otherCarY(i) > intersectionRoadBottom

                otherCarY(i) = otherCarY(i) ...
                    - otherCarSpeed(i)*dt;

            end

        end

        %% Check if every car has passed

        if all(otherCarY <= -10)

            otherCarsFinished = true;

        end

    end

    %% =====================================================
    % DETECT CROSSING CARS
    %
    % The autonomous vehicle checks distance to each car.
    %% =====================================================

    if otherCarsStarted && ...
            ~otherCarsFinished

        nearestCarDistance = inf;

        for i = 1:numberOfCars

            if otherCarY(i) > -10

                distanceToCar = sqrt( ...
                    (otherCarX(i)-x)^2 + ...
                    (otherCarY(i)-y)^2);

                if distanceToCar < nearestCarDistance

                    nearestCarDistance = distanceToCar;

                end

            end

        end

        %% Stop if a crossing car is close

        if nearestCarDistance < carDetectionDistance && ...
                x < intersectionX+10

            targetSpeed = 0;

            carsDetected = true;

            statusText = "3 CARS DETECTED - STOPPING";

        end

    end

    %% =====================================================
    % WAIT UNTIL ALL THREE CARS HAVE PASSED
    %% =====================================================

    if carsDetected && ~otherCarsFinished

        targetSpeed = 0;

        statusText = "CARS CROSSING - WAITING";

    end

    %% =====================================================
    % RESUME AFTER ALL CARS PASS
    %% =====================================================

    if carsDetected && otherCarsFinished

        targetSpeed = intersectionSpeed;

        statusText = "CARS CLEAR - RESUMING";

        %% Reset so this event is handled only once

        carsDetected = false;

    end

    %% =====================================================
    % CONSTRUCTION DETECTION
    %% =====================================================

    distanceConstruction = constructionX-x;

    if ~constructionDetected && ...
            distanceConstruction > 0 && ...
            distanceConstruction < 35

        constructionDetected = true;

    end

    %% =====================================================
    % CONSTRUCTION RESPONSE
    %% =====================================================

    if constructionDetected && ...
            ~detourActive && ...
            ~carsDetected

        if distanceConstruction > 8

            targetSpeed = constructionSpeed;

            statusText = "CONSTRUCTION DETECTED - SLOWING";

        else

            targetSpeed = 0;

            statusText = "CONSTRUCTION - STOPPING";

        end

        %% Actual vehicle stop

        if distanceConstruction <= 8 && speed < 0.3

            constructionStopped = true;

            if isnan(constructionWaitStart)

                constructionWaitStart = t;

            end

        end

    end

    %% =====================================================
    % 5 SECOND CONSTRUCTION WAIT
    %% =====================================================

    if constructionStopped && ~detourActive

        targetSpeed = 0;

        statusText = "CONSTRUCTION - WAITING 5 SEC";

        if t-constructionWaitStart >= constructionWaitTime

            detourActive = true;

            routeIndex = 2;

            statusText = "TAKING ALTERNATE ROAD";

        end

    end

    %% =====================================================
    % ALTERNATE ROUTE
    %% =====================================================

    if detourActive

        %% Move through forward route waypoints

        while routeIndex < length(routeX) && ...
                x >= routeX(routeIndex)-1

            routeIndex = routeIndex+1;

        end

        targetX = routeX(routeIndex);
        targetY = routeY(routeIndex);

        targetSpeed = normalSpeed*0.65;

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

            statusText = "MERGED BACK TO MAIN ROAD";

        end

    else

        %% Main road target

        targetX = x+lookAhead;
        targetY = 0;

    end

    %% =====================================================
    % PURE PURSUIT STYLE STEERING
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

    speedDerivative = ...
        (speedError-previousSpeedError)/dt;

    control = ...
        Kp_speed*speedError + ...
        Ki_speed*speedIntegral + ...
        Kd_speed*speedDerivative;

    previousSpeedError = speedError;

    %% =====================================================
    % ACCELERATION / BRAKING LIMIT
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

    if targetSpeed == 0 && speed < 0.2

        speed = 0;

    end

    %% =====================================================
    % KINEMATIC BICYCLE MODEL
    %% =====================================================

    if speed > 0.05

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
    % UPDATE OTHER CARS
    %% =====================================================

    for i = 1:numberOfCars

        set(otherCarHandles(i), ...
            'XData',otherCarX(i), ...
            'YData',otherCarY(i));

    end

    %% =====================================================
    % UPDATE AUTONOMOUS VEHICLE
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
    % TITLE / STATUS
    %% =====================================================

    title(sprintf( ...
        'URBAN INTERSECTION | %.1f m/s | %.1f km/h | %s', ...
        speed, ...
        speed*3.6, ...
        statusText));

    %% =====================================================
    % CAMERA FOLLOW
    %% =====================================================

    xlim([x-35 x+45]);

    ylim([-25 30]);

    %% =====================================================
    % ANIMATION
    %% =====================================================

    if mod(round(t/dt),4) == 0

        drawnow limitrate;

    end

    pause(0.01);

    %% =====================================================
    % ROAD END
    %% =====================================================

    if x >= roadEnd-2

        speed = 0;

        title('URBAN INTERSECTION | ROAD END - SIMULATION COMPLETE');

        drawnow;

        pause(2);

        break;

    end

end

%% =========================================================
% COMPLETION MESSAGE
%% =========================================================

disp(' ');
disp('================================================');
disp(' URBAN INTERSECTION SIMULATION COMPLETE');
disp('================================================');
disp('Autonomous vehicle: COMPLETED');
disp('Three crossing cars: DETECTED');
disp('Vehicle stopping behavior: COMPLETED');
disp('Cars cleared intersection: COMPLETED');
disp('Vehicle resumed: COMPLETED');
disp('Construction detection: COMPLETED');
disp('5-second construction stop: COMPLETED');
disp('Alternate route: COMPLETED');
disp('Vehicle reached road end.');
disp('================================================');
