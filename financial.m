% Load data (handling mixed data types)
fid = fopen('delivery_data.csv');
data = textscan(fid, '%s %f %f %s', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fid);

addresses = data{1};
latitudes = data{2};
longitudes = data{3};
order_times = data{4};

% Handle missing values (if any)
valid_rows = ~any(cellfun(@isempty, data), 2);
latitudes = latitudes(valid_rows);
longitudes = longitudes(valid_rows);

% Calculate the distance matrix
num_locations = length(latitudes);
distance_matrix = zeros(num_locations);

for i = 1:num_locations
    for j = 1:num_locations
        if i ~= j
            distance_matrix(i, j) = haversine(latitudes(i), longitudes(i), latitudes(j), longitudes(j));
        end
    end
end

% Save the distance matrix
csvwrite('distance_matrix.csv', distance_matrix);

% Load historical traffic data (if available)
traffic_data = csvread('traffic_data.csv');

% Adjust distance matrix based on traffic data
for i = 1:num_locations
    for j = 1:num_locations
        if i ~= j
            delay = mean(traffic_data(traffic_data(:, 2) == latitudes(i) & traffic_data(:, 3) == longitudes(i) & ...
                                     traffic_data(:, 4) == latitudes(j) & traffic_data(:, 5) == longitudes(j), 6));
            distance_matrix(i, j) = distance_matrix(i, j) + delay;
        end
    end
end

% Save the adjusted distance matrix
csvwrite('distance_matrix_with_traffic.csv', distance_matrix);

% Example usage of Nearest Neighbor
start_point = 1; % Starting from the first location
route = nearest_neighbor(distance_matrix, start_point);

% Visualization
plot_route(latitudes, longitudes, route);

% Save the optimized route
csvwrite('optimized_route.csv', route);

