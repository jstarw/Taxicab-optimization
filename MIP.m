function [x,obj_ip,time_ip] = MIP(max_hours_per_week,time_slot_available,region_available)
% max_hours_per_week: Maximum number of hours the driver can contribute per
% week
% time_slot_available: a 7*24 matrix to indicate the driver's availablility
% in each hour of a week. 1 indicates available and 0 indicates not
% Region_available: a 1*5 vector indicates which region the driver likes
% to drive in; 1 indicates like and 0 indicates dislike
% weight_var_multiplier: multiplier used to adjust the weight of variability
% weight_demand_multiplier: multiplier used to adjust the weight of demand

%% Import Data
% Right click on the "Data_Demand_Variability.csv", select "Import Data"
T = readtable('Data/2018_Taxi_Processed.csv');
% Get Column Names
% T.Properties.VariableNames

% Store each column as a variable
Weekday = T.weekday;
Hour = T.hour;
Region = T.region;
Duration = T.duration_sum./T.count;
Fare = T.total_amount_sum./T.count;
Count = T.count; % we don't have this

%% Convert Traffic into Probability of Getting new Customers
% P_new_customer is a vertical vector of the same size with Avg_Traffic
P_new_customer = Customer_Probability(Count);

%% Convert Max_Duration to Minimum Trips per Hour
% Duration is the average Duration of Trips within that region &
% time slot. It is recorded on second. 
Min_Trips = 3600./(Duration+240);

%% Adjust the data based on the given parameters - driver's preference
weekday_choices = 1:7;
time_choices = 1:24;
n_weekdays_choices = 7;
n_timeslot_choices = 24;
% Initialize indices of element to be removed: all are 0 in the beginning
indices_to_be_rm = zeros(size(Weekday));
for d = weekday_choices % Row
    for t = time_choices % Column
        if time_slot_available(d,t) == 0 % Mark as un-available
            % Find the timeslot and weekday that cooresponding to that hour
            timeslot_to_be_rm = find(time_choices==t);
            weekday_to_be_rm = d;
            % Mark the indices of the elements to be removed
            indices_to_be_rm(Weekday == weekday_to_be_rm & Hour == timeslot_to_be_rm) = 1;
        end
    end
end


% Mark unavailable reigons
if sum(region_available)<7
    unavailable_region = find(region_available==0);
    % If the regions in the unavailable_region shows in Region, it will be
    % marked with 1
    unavailable_region_ind = ismember(Region, transpose(unavailable_region));
    indices_to_be_rm(unavailable_region_ind) = 1;
end

% Removed all marked instances
% We need to backwards
if sum(indices_to_be_rm) >0
    ind_to_be_removed = find(indices_to_be_rm == 1);
    %ind_to_be_removed
    for i = sum(indices_to_be_rm):-1:1
        ind = ind_to_be_removed(i);
        %size(Weekday)
        Weekday(ind) = [];
        Hour(ind) = [];
        Region(ind) = [];
        Min_Trips(ind) = [];
        P_new_customer(ind) = [];
        Fare(ind) = [];
    end
end

% Number of variables
n_x = size(Min_Trips,1);
%% Formulate the IP
%  A vector of cost coefficients
% Probability of Getting new Customer * Expected Trips * Avg Trip Fare
f = transpose(P_new_customer.*Min_Trips.*Fare);
% Integer Variables
intcon = 1:n_x;

% Constraint 1: Maximum number of hours per week
A1 = ones(1,n_x); % Lhs
b1 = max_hours_per_week;  % rhs

% Constraint 2: You cannot be in 2 regions during the same time
% Initialize A2 and b2
A2 = zeros(n_weekdays_choices*n_timeslot_choices,n_x);
b2 = ones(n_weekdays_choices*n_timeslot_choices,1); % Upper limit should be 1

row_count = 0;

for d = weekday_choices
    for t = time_choices
        row_count = row_count+1;
        ind_marked = (Weekday == d & Hour == t);
        A2(row_count,ind_marked) =1;
    end
end
    
A = [A1;A2];
b = [b1;b2];
lb = zeros(n_x,1); 
ub = ones(n_x,1);
tic;
[x,fval] = intlinprog(-f,intcon,A,b,[],[],lb,ub);
time_ip = toc;
obj_ip = -1*fval*0.87;

%% Present the Solution
select_list = find(x==1);

% Set a basis for the weekday
day_number_benchmark = datetime(2017,04,9);

% Set a list of our pre-defined timeslot
timeslots = {'12AM'; '1AM'; '2AM'; '3AM'; '4AM'; '5AM'; '6AM'; '7AM'; '8AM'; 
    '9AM'; '10AM'; '11AM'; '12PM'; '1PM'; '2PM'; '3PM'; '4PM'; '5PM'; '6PM'; 
    '7PM'; '8PM'; '9PM'; '10PM'; '11PM'};

for i = 1:sum(x)
    select_time = Hour(select_list(i));
    select_day = Weekday(select_list(i));
    select_region = Region(select_list(i));
    
    weekday_name = day(day_number_benchmark+select_day,'name');
    timeslot = timeslots(select_time +1);
%     string_output = ['Recommendation ' num2str(i) ': Region ' num2str(select_region) ', ' timeslot ', ' weekday_name];
    
    p_new = P_new_customer(select_list(i));
    min_trip = Min_Trips(select_list(i));
    string_output = ['Recommendation ' num2str(i) ': Region ' num2str(select_region) ', ' timeslot ', ' weekday_name ', ' p_new  ', ' min_trip];
    
    disp(string_output)
end

string_output = ['Total Revenue Earned: ' num2str(obj_ip)];
disp(string_output)