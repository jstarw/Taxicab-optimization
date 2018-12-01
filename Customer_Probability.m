function P_new_customer = Customer_Probability(Count)
%% This function converts traffic amount into probability of getting new customers
% We assume the Avg_Traffic has uniform distribution 
% Avg_Traffic: a vertical vector of different traffic amount
% p_max: maximum probability that the driver can get new customers - best
% case scenario
% p_min: minimum probability that the driver can get new customers - worse
% case scenario

max_count = max(Count);
min_count = min(Count);

P_new_customer = (Count - min_count)./(2*(max_count - min_count)) + 0.5;