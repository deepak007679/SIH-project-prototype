%% =========================================================
% HIGHWAY MERGE - AUTONOMOUS VEHICLE
% Vehicle Dynamics + Control
% MATLAB ONLY - NO SIMULINK
%
% Features:
% 1. Main highway
% 2. Separate physical alternate connecting road
% 3. Road construction detection
% 4. Slow -> Stop -> 5 second wait
% 5. Alternate route
% 6. Reconnects with highway
% 7. Pure Pursuit style lateral control
% 8. PID style longitudinal control
% 9. Traffic light
% 10. Buildings and trees
% 11. Camera follows vehicle
% 12. Stops at road end
%% =========================================================

clear;
clc;
close all;

%% =========================================================
% SIMULATION SETTINGS
%% =========================================================

dt = 0.05;
simulationTime = 180;

%% =========================================================
% VEHICLE PARAMETERS
%% =========================================================

x = 10;
y = 0;

yaw = 0;

speed = 0;

wheelbase = 2.8;

maxSteer = deg2rad(28);

normalSpeed = 9;
slowSpeed = 4.5;

maxAcceleration = 2.0;
maxBraking = 4.5;

%% =========================================================
% CONTROLLER PARAMETERS
%% =========================================================

lookAhead = 8;

Kp_speed = 1.5;
Ki_speed = 0.08;
Kd_speed = 0.15;

speedIntegral = 0;
previousSpeedError = 0;

%% =========================================================
% MAIN HIGHWAY
%% =========================================================

roadWidth = 10;

roadStart = 0;
roadEnd = 300;

%% =========================================================
% ALTERNATE CONNECTING ROAD
%
% This is an actual separate road.
% It starts from the main highway,
% goes downward,
% travels around the construction,
% and reconnects to the main highway.
%% =========================================================

routeX = [145 152 160 172 190 215 240 265 285 300];

routeY = [0 -3 -7 -10 -10 -9 -7 -5 -3 0];

alternateRoadWidth = 6;

routeIndex = 2;

alternateRoute = false;

%% =========================================================
% CONSTRUCTION AREA
%% =========================================================

constructionX = 155;

constructionWidth = 12;

constructionDetected = false;

constructionStopped = false;

constructionWaitStart = NaN;

constructionWaitTime = 5;

detourActive = false;

%% =========================================================
% TRAFFIC LIGHT
%% =========================================================

lightX = 85;

greenTime = 12;
redTime = 7;

lightTimer = 0;

lightState = "GREEN";

lightStopped = false;

lightWaitStart = NaN;

lightWaitTime = 5;

%% =========================================================
% VEHICLE STATUS
%% =========================================================

statusText = "NORMAL";

%% =========================================================
% BUILDINGS
%% =========================================================

buildingX = [25 48 72 105 130 185 215 245 275];
buildingY = [15 17 14 18 16 17 14 18 15];

buildingW = [12 10 14 11 13 12 15 11 13];
buildingH = [9 10 8 11 9 10 8 11 9];

%% =========================================================
% TREES
%% =========================================================

treeX = [15 35 58 78 112 145 175 205 235 265 292];
treeY = [-14 -15 -13 -16 -14 -17 -15 -16 -14 -15 -13];

%% =========================================================
% FIGURE
%% =========================================================

figure('Color','w');

hold on;
grid on;

axis manual;

xlim([-10 320]);
ylim([-22 25]);

xlabel('X Position (m)');
ylabel('Y Position (m)');

title('HIGHWAY MERGE - AUTONOMOUS VEHICLE');

%% =========================================================
% MAIN HIGHWAY
%% =========================================================

fill([roadStart roadEnd roadEnd roadStart], ...
     [-roadWidth/2 -roadWidth/2 roadWidth/2 roadWidth/2], ...
     [0.25 0.25 0.25], ...
     'EdgeColor','none');

%% Highway lane markings

plot([roadStart roadEnd], [0 0], ...
     '--', ...
     'Color',[0.8 0.8 0.8], ...
     'LineWidth',1.5);

plot([roadStart roadEnd], ...
     [roadWidth/2 roadWidth/2], ...
     'w', ...
     'LineWidth',2);

plot([roadStart roadEnd], ...
     [-roadWidth/2 -roadWidth/2], ...
     'w', ...
     'LineWidth',2);

%% =========================================================
% ALTERNATE ROAD - PHYSICAL ROAD SURFACE
%% =========================================================

% Draw road edges first

plot(routeX, routeY + alternateRoadWidth/2, ...
     'k', ...
     'LineWidth',4);

plot(routeX, routeY - alternateRoadWidth/2, ...
     'k', ...
     'LineWidth',4);

% Road surface approximation

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
         [0.3 0.3 0.3], ...
         'EdgeColor','none');

end

%% Alternate road center line

plot(routeX,routeY, ...
     '--', ...
     'Color',[0.85 0.85 0.85], ...
     'LineWidth',1.5);

%% Redraw alternate road edges

plot(routeX, routeY + alternateRoadWidth/2, ...
     'k', ...
     'LineWidth',3);

plot(routeX, routeY - alternateRoadWidth/2, ...
     'k', ...
     'LineWidth',3);

%% =========================================================
% ROAD CONNECTION MARKINGS
%% =========================================================

plot([145 145],[-5 5], ...
     'w', ...
     'LineWidth',2);

plot([300 300],[-5 5], ...
     'w', ...
     'LineWidth',2);

text(175,-14, ...
     'ALTERNATE CONNECTING ROAD', ...
     'FontWeight','bold');

%% =========================================================
% CONSTRUCTION AREA
%% =========================================================

constructionLeft = constructionX - constructionWidth/2;
constructionRight = constructionX + constructionWidth/2;

fill([constructionLeft constructionRight constructionRight constructionLeft], ...
     [-5 -5 5 5], ...
     [1 0.7 0.1], ...
     'EdgeColor','k', ...
     'LineWidth',2);

%% Construction stripes

for xx = constructionLeft:2:constructionRight

    plot([xx xx+2],[-5 5], ...
         'r', ...
         'LineWidth',2);

end

text(constructionX-7,7, ...
     'ROAD CONSTRUCTION', ...
     'Color','r', ...
     'FontWeight','bold');

%% =========================================================
% TRAFFIC LIGHT
%% =========================================================

plot([lightX lightX], [5 10], ...
     'k', ...
     'LineWidth',4);

plot(lightX,10, ...
     'ko', ...
     'MarkerSize',10, ...
     'MarkerFaceColor','g');

text(lightX+2,10, ...
     'TRAFFIC LIGHT', ...
     'FontWeight','bold');

plot([lightX lightX],[-5 5], ...
     'k', ...
     'LineWidth',2);

%% Stop line

plot([lightX lightX],[-5 5], ...
     'w', ...
     'LineWidth',3);

%% =========================================================
% BUILDINGS
%% =========================================================

for i = 1:length(buildingX)

    bx = buildingX(i);
    by = buildingY(i);
    bw = buildingW(i);
    bh = buildingH(i);

    fill([bx-bw/2 bx+bw/2 bx+bw/2 bx-bw/2], ...
         [by-bh/2 by-bh/2 by+bh/2 by+bh/2], ...
         [0.65 0.65 0.7], ...
         'EdgeColor','k');

end

%% =========================================================
% TREES
%% =========================================================

for i = 1:length(treeX)

    plot(treeX(i),treeY(i), ...
         'o', ...
         'MarkerSize',12, ...
         'MarkerFaceColor',[0.1 0.6 0.1], ...
         'MarkerEdgeColor','k');

end

%% =========================================================
% VEHICLE GRAPHICS
%% =========================================================

carLength = 5;
carWidth = 2.2;

carX = [ ...
    -carLength/2 ...
     carLength/2 ...
     carLength/2 ...
    -carLength/2];

carY = [ ...
    -carWidth/2 ...
    -carWidth/2 ...
     carWidth/2 ...
     carWidth/2];

vehiclePatch = patch( ...
    x + carX, ...
    y + carY, ...
    'b', ...
    'EdgeColor','k', ...
    'LineWidth',1.5);

%% Vehicle heading indicator

headingLine = plot( ...
    [x x+3], ...
    [y y], ...
    'b', ...
    'LineWidth',2);

%% =========================================================
% SIMULATION LOOP
%% =========================================================

for t = 0:dt:simulationTime

    %% -----------------------------------------------------
    % TRAFFIC LIGHT TIMER
    %% -----------------------------------------------------

    lightTimer = lightTimer + dt;

    if strcmp(lightState,"GREEN")

        if lightTimer >= greenTime

            lightState = "RED";
            lightTimer = 0;

        end

    else

        if lightTimer >= redTime

            lightState = "GREEN";
            lightTimer = 0;

        end

    end

    %% -----------------------------------------------------
    % DISTANCE TO TRAFFIC LIGHT
    %% -----------------------------------------------------

    distanceLight = lightX - x;

    %% -----------------------------------------------------
    % TRAFFIC LIGHT CONTROL
    %
    % Vehicle only reacts when close to the light.
    %% -----------------------------------------------------

    if strcmp(lightState,"RED") && ...
            distanceLight > 0 && ...
            distanceLight < 12 && ...
            ~detourActive

        targetSpeed = 0;

        statusText = "RED LIGHT - STOPPING";

        if speed < 0.3 && ~lightStopped

            lightStopped = true;
            lightWaitStart = t;

        end

    elseif lightStopped

        targetSpeed = 0;

        statusText = "RED LIGHT - WAITING";

        if t - lightWaitStart >= lightWaitTime

            lightStopped = false;
            lightWaitStart = NaN;

            lightState = "GREEN";
            lightTimer = 0;

            statusText = "GREEN - RESUMING";

        end

    end

    %% -----------------------------------------------------
    % CONSTRUCTION DETECTION
    %% -----------------------------------------------------

    distanceConstruction = constructionX - x;

    if ~constructionDetected && ...
            distanceConstruction > 0 && ...
            distanceConstruction < 35

        constructionDetected = true;

    end

    %% -----------------------------------------------------
    % CONSTRUCTION RESPONSE
    %
    % IMPORTANT:
    % Vehicle slows first and does NOT set speed to zero
    % until it is actually close to the construction.
    %% -----------------------------------------------------

    if constructionDetected && ...
            ~detourActive && ...
            ~lightStopped

        if distanceConstruction > 8

            targetSpeed = slowSpeed;

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

    %% -----------------------------------------------------
    % CONSTRUCTION 5 SECOND WAIT
    %% -----------------------------------------------------

    if constructionStopped && ~detourActive

        targetSpeed = 0;

        statusText = "CONSTRUCTION - WAITING 5 SEC";

        if t - constructionWaitStart >= constructionWaitTime

            detourActive = true;
            routeIndex = 2;

            statusText = "ALTERNATE ROUTE";

        end

    end

    %% -----------------------------------------------------
    % NORMAL DRIVING
    %% -----------------------------------------------------

    if ~constructionDetected && ~lightStopped

        targetSpeed = normalSpeed;
        statusText = "NORMAL";

    end

    %% -----------------------------------------------------
    % ALTERNATE ROUTE NAVIGATION
    %% -----------------------------------------------------

    if detourActive

        %% Current route waypoint

        targetX = routeX(routeIndex);
        targetY = routeY(routeIndex);

        %% Drive slower on alternate road

        targetSpeed = normalSpeed * 0.7;

        %% Waypoint distance

        distanceWaypoint = sqrt( ...
            (targetX-x)^2 + ...
            (targetY-y)^2);

        %% Advance waypoint

        if distanceWaypoint < 3 && ...
                routeIndex < length(routeX)

            routeIndex = routeIndex + 1;

        end

        %% Finished alternate route

        if routeIndex >= length(routeX)

            detourActive = false;

            constructionDetected = false;
            constructionStopped = false;
            constructionWaitStart = NaN;

            statusText = "MERGED BACK TO HIGHWAY";

        end

    else

        %% Main highway target

        targetX = x + lookAhead;
        targetY = 0;

    end

    %% -----------------------------------------------------
    % PURE PURSUIT STYLE LATERAL CONTROL
    %% -----------------------------------------------------

    dx = targetX - x;
    dy = targetY - y;

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

    %% -----------------------------------------------------
    % LONGITUDINAL PID CONTROLLER
    %% -----------------------------------------------------

    speedError = targetSpeed - speed;

    speedIntegral = speedIntegral + ...
        speedError*dt;

    speedDerivative = ...
        (speedError-previousSpeedError)/dt;

    control = ...
        Kp_speed*speedError + ...
        Ki_speed*speedIntegral + ...
        Kd_speed*speedDerivative;

    previousSpeedError = speedError;

    %% -----------------------------------------------------
    % ACCELERATION / BRAKING LIMITS
    %% -----------------------------------------------------

    if control >= 0

        acceleration = min(control,maxAcceleration);

    else

        acceleration = max(control,-maxBraking);

    end

    %% Stop condition

    if targetSpeed == 0 && speed < 0.2

        speed = 0;

    else

        speed = speed + acceleration*dt;

        if speed < 0

            speed = 0;

        end

    end

    %% -----------------------------------------------------
    % KINEMATIC BICYCLE MODEL
    %% -----------------------------------------------------

    if speed > 0.05

        yaw = yaw + ...
            (speed/wheelbase)*tan(steeringAngle)*dt;

    end

    x = x + speed*cos(yaw)*dt;

    y = y + speed*sin(yaw)*dt;

    %% -----------------------------------------------------
    % LIMIT VEHICLE TO ROAD REGION
    %% -----------------------------------------------------

    if ~detourActive

        if y > 4

            y = 4;

        elseif y < -4

            y = -4;

        end

    end

    %% -----------------------------------------------------
    % UPDATE VEHICLE GRAPHICS
    %% -----------------------------------------------------

    rotatedX = ...
        carX*cos(yaw) - ...
        carY*sin(yaw);

    rotatedY = ...
        carX*sin(yaw) + ...
        carY*cos(yaw);

    set(vehiclePatch, ...
        'XData',x+rotatedX, ...
        'YData',y+rotatedY);

    set(headingLine, ...
        'XData',[x x+3*cos(yaw)], ...
        'YData',[y y+3*sin(yaw)]);

    %% -----------------------------------------------------
    % UPDATE TRAFFIC LIGHT GRAPHICS
    %% -----------------------------------------------------

    if strcmp(lightState,"GREEN")

        set(findobj(gca,'Marker','o','MarkerSize',10), ...
            'MarkerFaceColor','g');

    else

        set(findobj(gca,'Marker','o','MarkerSize',10), ...
            'MarkerFaceColor','r');

    end

    %% -----------------------------------------------------
    % STATUS DISPLAY
    %% -----------------------------------------------------

    if detourActive

        modeText = "ALTERNATE ROAD";

    else

        modeText = "MAIN HIGHWAY";

    end

    title(sprintf( ...
        'HIGHWAY MERGE | %.1f m/s | %.1f km/h | %s | %s', ...
        speed, ...
        speed*3.6, ...
        lightState, ...
        statusText));

    %% -----------------------------------------------------
    % FOLLOW CAMERA
    %% -----------------------------------------------------

    xlim([x-35 x+45]);

    ylim([-22 25]);

    %% -----------------------------------------------------
    % ANIMATION
    %% -----------------------------------------------------

    if mod(round(t/dt),4) == 0

        drawnow limitrate;

    end

    pause(0.01);

    %% -----------------------------------------------------
    % ROAD END
    %% -----------------------------------------------------

    if x >= roadEnd-2

        speed = 0;

        statusText = "ROAD END - VEHICLE STOPPED";

        title(sprintf( ...
            'HIGHWAY MERGE | %.1f km/h | ROAD END - COMPLETE', ...
            speed*3.6));

        drawnow;

        pause(2);

        break;

    end

end

%% =========================================================
% SIMULATION COMPLETE
%% =========================================================

disp(' ');
disp('==============================================');
disp(' HIGHWAY MERGE SIMULATION COMPLETE');
disp('==============================================');
disp('Vehicle successfully reached the end of road.');
disp('Construction detection completed.');
disp('Vehicle slowed and stopped before construction.');
disp('Vehicle waited 5 seconds.');
disp('Vehicle used the alternate connecting road.');
disp('Vehicle merged back onto the main highway.');
disp('==============================================');
