function P_new_customer = Customer_Probability(Count)
max_count = max(Count);
min_count = min(Count);
P_new_customer = (Count - min_count)./(2*(max_count - min_count)) + 0.5;