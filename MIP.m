function [x,obj_ip,time_ip] = MIP(max_hours,available_time_slots,available_regions)
T = readtable('Data/2018_Taxi_Processed.csv');
Weekday = T.weekday;
Hour = T.hour;
Region = T.region;
Duration = T.duration_sum./T.count;
Fare = T.total_amount_sum./T.count;
Count = T.count; 

%% Convert Count to a probablity
customer_probability = Customer_Probability(Count);
Avg_Trips = 3600./(Duration+240);

%% Adjust data from time_slot_available
weekday_choices = 1:7;
time_choices = 1:24;
num_weekdays = 7;
num_hours = 24;
removed_indices = zeros(size(Weekday));
for d = weekday_choices % Row
    for t = time_choices % Column
        if available_time_slots(d,t) == 0 
            removed_indices(Weekday == d-1 & Hour == t-1) = 1;
        end
    end
end


if sum(available_regions)<7
    unavail_region = find(available_regions==0);
    unavail_region_ind = ismember(Region, transpose(unavail_region));
    removed_indices(unavail_region_ind) = 1;
end

if sum(removed_indices) >0
    ind_to_be_removed = find(removed_indices == 1);
    for i = sum(removed_indices):-1:1
        ind = ind_to_be_removed(i);
        Weekday(ind) = [];
        Hour(ind) = [];
        Region(ind) = [];
        Avg_Trips(ind) = [];
        customer_probability(ind) = [];
        Fare(ind) = [];
    end
end

% Number of variables
n_x = size(Avg_Trips,1);
%% Formulate the MIP
f = transpose(customer_probability.*Avg_Trips.*Fare);
intcon = 1:n_x;

A1 = ones(1,n_x);
b1 = max_hours;

A2 = zeros(num_weekdays*num_hours,n_x);
b2 = ones(num_weekdays*num_hours,1); 

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
options = optimoptions(@intlinprog, 'CutGenMaxIter', 50);

tic;
[x,fval] = intlinprog(-f,intcon,A,b,[],[],lb,ub, options);
time_ip = toc;
obj_ip = -1*fval*0.87;

%% Present Solution
selected_list = find(x==1);

day_benchmark = datetime(2017,04,9);

timeslots = {'12AM'; '1AM'; '2AM'; '3AM'; '4AM'; '5AM'; '6AM'; '7AM'; '8AM'; 
    '9AM'; '10AM'; '11AM'; '12PM'; '1PM'; '2PM'; '3PM'; '4PM'; '5PM'; '6PM'; 
    '7PM'; '8PM'; '9PM'; '10PM'; '11PM'};

for i = 1:sum(x)
    select_time = Hour(selected_list(i));
    select_day = Weekday(selected_list(i));
    select_region = Region(selected_list(i));
    
    weekday_name = day(day_benchmark+select_day,'name');
    timeslot = timeslots(select_time +1);
    out = ['Recommendation ' num2str(i) ': Region ' num2str(select_region) ', ' timeslot ', ' weekday_name];
    
    disp(out)
end

out = ['Total Revenue Earned: ' num2str(obj_ip)];
disp(out)