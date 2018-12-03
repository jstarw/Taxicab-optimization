max_hours = 8; 
available_times = ones(7,24); 
% Adjust the availble time

available_regions = [1;1;1;1;1;1;1]; 


%% Launch the IP Solver
[x,obj_ip,time_ip] = MIP(max_hours,available_times,available_regions);