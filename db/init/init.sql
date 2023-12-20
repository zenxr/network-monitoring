create schema if not exists timescale;

create extension if not exists timescaledb;

-- turn off timescale telemetry
alter database timescale set timescaledb.telemetry_level = 'off';

create table timescale.latency_metric (
    address varchar(150) not null,
    latency_ms integer,
    created_on timestamp default now() not null
);

-- transform the latency_metric into a hypertable
select create_hypertable('timescale.latency_metric', by_range('created_on'));

create table timescale.bandwidth_metric (
    source varchar(100) not null,
    latency_ms integer,
    download_mbs integer,
    upload_mbs integer,
    created_on timestamp default now() not null
);

-- transform the bandwidth_metric into a hypertable
select create_hypertable('timescale.bandwidth_metric', by_range('created_on'));

