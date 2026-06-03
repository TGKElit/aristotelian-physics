#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

struct cell {
    float earth;
    float water;
    float air;
    float fire;
    float wait_time;
};

// grid[x][y] = [earth, air, water, fire, wait_time]
layout(set = 0, binding = 0, std430) restrict buffer grid_buffer {
    
    float grid[];
    
}grid_1D;

layout (set = 0, binding = 1, std430) readonly buffer params {
    float index_parity;
    float earth_density;
    float water_density;
    float air_density;
    float fire_density;
    float delta;
};


float weight (cell cell) {
    return cell.earth * earth_density + cell.water * water_density + cell.air * air_density + cell.fire * fire_density;
}

cell[1][2] movement_check(cell grid[1][2]) {
    cell faller = grid[0][0];
    cell riser = grid[0][1];

    float speed = weight(grid[0][0])/weight(grid[0][1]);


    if (speed > 1 / min(grid[0][0].wait_time, grid[0][1].wait_time)) {
        grid[0][0] = riser;
        grid[0][1] = faller;

        grid[0][0].wait_time = 0.0;
        grid[0][1].wait_time = 0.0;
    }

    return grid;
}

void main() {

    cell grid[1][2];
    uint grid_width = gl_NumWorkGroups[0] * gl_WorkGroupSize[0];
    uint grid_height = 2 * gl_NumWorkGroups[1] * gl_WorkGroupSize[1];
    uint y = gl_GlobalInvocationID.y * 2 + uint(index_parity);
    uint x = gl_GlobalInvocationID.x;

    if (y + 1 < grid_height) {
        grid[0][0].earth = grid_1D.grid[x * grid_height * 5 + y * 5 + 0];
        grid[0][0].water = grid_1D.grid[x * grid_height * 5 + y * 5 + 1];
        grid[0][0].air = grid_1D.grid[x * grid_height * 5 + y * 5 + 2];
        grid[0][0].fire = grid_1D.grid[x * grid_height * 5 + y * 5 + 3];
        grid[0][0].wait_time = grid_1D.grid[x * grid_height * 5 + y * 5 + 4];

        grid[0][1].earth = grid_1D.grid[x * grid_height * 5 + (y + 1) * 5 + 0];
        grid[0][1].water = grid_1D.grid[x * grid_height * 5 + (y + 1) * 5 + 1];
        grid[0][1].air = grid_1D.grid[x * grid_height * 5 + (y + 1) * 5 + 2];
        grid[0][1].fire = grid_1D.grid[x * grid_height * 5 + (y + 1) * 5 + 3];
        grid[0][1].wait_time = grid_1D.grid[x * grid_height * 5 + (y + 1) * 5 + 4];
    

        grid[0][0].wait_time += delta;
        grid[0][1].wait_time += delta;

        grid = movement_check(grid);
        

        grid_1D.grid[x * grid_height * 5 + y * 5 + 0] = grid[0][0].earth;
        grid_1D.grid[x * grid_height * 5 + y * 5 + 1] = grid[0][0].water;
        grid_1D.grid[x * grid_height * 5 + y * 5 + 2] = grid[0][0].air;
        grid_1D.grid[x * grid_height * 5 + y * 5 + 3] = grid[0][0].fire;
        grid_1D.grid[x * grid_height * 5 + y * 5 + 4] = grid[0][0].wait_time;

        grid_1D.grid[x * grid_height * 5 + (y + 1) * 5 + 0] = grid[0][1].earth;
        grid_1D.grid[x * grid_height * 5 + (y + 1) * 5 + 1] = grid[0][1].water;
        grid_1D.grid[x * grid_height * 5 + (y + 1) * 5 + 2] = grid[0][1].air;
        grid_1D.grid[x * grid_height * 5 + (y + 1) * 5 + 3] = grid[0][1].fire;
        grid_1D.grid[x * grid_height * 5 + (y + 1) * 5 + 4] = grid[0][1].wait_time;
    }
}

