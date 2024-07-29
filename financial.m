% Load data (handling mixed data types)
fid = fopen('delivery_data.csv');
data = textscan(fid, '%s %f %f %s', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fid);

addresses = data{1};
latitudes = data{2};
longitudes = data{3};
order_times = data{4};

% Handle missing values (if any)
valid_rows = ~cellfun('isempty', addresses) & ~cellfun('isempty', num2cell(latitudes)) & ~cellfun('isempty', num2cell(longitudes)) & ~cellfun('isempty', order_times);
latitudes = latitudes(valid_rows);
longitudes = longitudes(valid_rows);

% Function to calculate the Haversine distance between two coordinates
function d = haversine(lat1, lon1, lat2, lon2)
    R = 6371; % Earth radius in km
    dlat = deg2rad(lat2 - lat1);
    dlon = deg2rad(lon2 - lon1);
    a = sin(dlat/2)^2 + cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dlon/2)^2;
    c = 2 * atan2(sqrt(a), sqrt(1-a));
    d = R * c;
end

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
% For example purposes, we'll assume traffic_data.csv exists and has the proper format
% Columns: [source_latitude, source_longitude, dest_latitude, dest_longitude, delay]
traffic_data = csvread('traffic_data.csv');

% Adjust distance matrix based on traffic data
for i = 1:num_locations
    for j = 1:num_locations
        if i ~= j
            delay = mean(traffic_data(traffic_data(:, 1) == latitudes(i) & traffic_data(:, 2) == longitudes(i) & ...
                                     traffic_data(:, 3) == latitudes(j) & traffic_data(:, 4) == longitudes(j), 5));
            if ~isnan(delay)
                distance_matrix(i, j) = distance_matrix(i, j) + delay;
            end
        end
    end
end

% Save the adjusted distance matrix
csvwrite('distance_matrix_with_traffic.csv', distance_matrix);

% Nearest Neighbor Algorithm
function route = nearest_neighbor(distance_matrix, start_point)
    num_locations = size(distance_matrix, 1);
    unvisited = 1:num_locations;
    unvisited(start_point) = [];
    route = start_point;
    current = start_point;

    while ~isempty(unvisited)
        [~, nearest] = min(distance_matrix(current, unvisited));
        current = unvisited(nearest);
        route = [route, current];
        unvisited(nearest) = [];
    end
end

% Example usage of Nearest Neighbor
start_point = 1; % Starting from the first location
route = nearest_neighbor(distance_matrix, start_point);

% Visualization
function plot_route(latitudes, longitudes, route)
    figure;
    plot(latitudes(route), longitudes(route), '-o');
    title('Optimized Delivery Route');
    xlabel('Latitude');
    ylabel('Longitude');
    grid on;
end

% Plot the optimized route
plot_route(latitudes, longitudes, route);
