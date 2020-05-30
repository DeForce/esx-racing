create table racing
(
    id    int auto_increment
        primary key,
    name varchar(50) not null,
    owner_id  varchar(50) not null,
    default_lap_count int default 1 not null,
    type  varchar(50) not null,
    start_x float not null,
    start_y float not null,
    start_z float not null,
    heading float not null
);

create table racing_checkpoints
(
	id int auto_increment,
	race_id int not null,
	checkpoint_order int not null,
	x float not null,
	y float not null,
	z float not null,
	radius int not null,
	constraint racing_checkpoints_pk
		primary key (id)
);

