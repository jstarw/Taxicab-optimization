%% Set Parameters
max_hours_per_week = 8; % Maximum number of hours a driver can work per week
time_slot_available = zeros(7,24); % Represent the timeslot when the driver is available
region_available = [1;1;1;1;1;1;1]; % Indicate which of the 7 regions the driver is avilable to go

arr = 1:5:168;
% Slowly increase the times available
times = zeros(size(arr,2),1);
speed = zeros(size(arr,2),1);
idx = 1;
for i = arr
    % average of 5 iterations
    curr_speeds = zeros(5,1);
    for j = 1:5
        % Adjust the availble time
        random_indices = randperm(168,i);
        time_slot_available(random_indices) = 1;
        [x,obj_ip,time_ip] = MIP(max_hours_per_week,time_slot_available,region_available);
        curr_speeds(j) = time_ip;
        % reset times
        time_slot_available(:) = 0;
    end
    
    times(idx) = i;
    speed(idx) = sum(curr_speeds)/5;
    idx = idx + 1;
end

%% plot the resulting graph

figure;
plot(times, speed);
title('Computational Time');
xlabel('Hours available');
ylabel('Average speed');

%% see if max hours changes computational time
time_slot_available = ones(7,24);
arr = 0:50;
times = zeros(size(arr,2),1);
speed = zeros(size(arr,2),1);
idx = 1;
for i = arr
    % average of 5 iterations
    curr_speeds = zeros(5,1);
    for j = 1:5
        % Adjust the availble time
        [x,obj_ip,time_ip] = MIP(i,time_slot_available,region_available);
        curr_speeds(j) = time_ip;
    end
    
    times(idx) = i;
    speed(idx) = sum(curr_speeds)/5;
    idx = idx + 1;
end

%% plot the resulting graph

figure;
plot(times(30:end), speed(30:end));
title('Computational Time');
xlabel('Max Hours available');
ylabel('Average speed');