ALTER TABLE ride
    ADD distance_in_km DOUBLE PRECISION;

ALTER TABLE ride
    ADD duration BIGINT;

ALTER TABLE ride
    ADD vehicle_type SMALLINT;

ALTER TABLE ride
    ALTER COLUMN distance_in_km SET NOT NULL;

ALTER TABLE driver_profile
    ADD vehicle_type VARCHAR(255);

ALTER TABLE ride
DROP
COLUMN boarding_confirmed_at;

ALTER TABLE ride
DROP
COLUMN corridor_id;

ALTER TABLE ride
DROP
COLUMN dropoff_vbs_id;

ALTER TABLE ride
DROP
COLUMN no_show_marked_at;

ALTER TABLE ride
DROP
COLUMN pickup_vbs_id;

ALTER TABLE ride
DROP
COLUMN subscription_id;

DROP SEQUENCE fare_configs_seq CASCADE;

ALTER TABLE fare_configs
ALTER
COLUMN base_fare TYPE DECIMAL USING (base_fare::DECIMAL);

ALTER TABLE ride
ALTER
COLUMN estimated_fare TYPE DECIMAL USING (estimated_fare::DECIMAL);

ALTER TABLE ride
ALTER
COLUMN final_fare TYPE DECIMAL USING (final_fare::DECIMAL);

ALTER TABLE fare_configs
ALTER
COLUMN minimum_fare TYPE DECIMAL USING (minimum_fare::DECIMAL);

ALTER TABLE fare_configs
ALTER
COLUMN per_km_rate TYPE DECIMAL USING (per_km_rate::DECIMAL);

ALTER TABLE fare_configs
ALTER
COLUMN per_minute_rate TYPE DECIMAL USING (per_minute_rate::DECIMAL);

ALTER TABLE fare_configs
ALTER
COLUMN surge_multiplier TYPE DECIMAL USING (surge_multiplier::DECIMAL);

ALTER TABLE fare_configs
ALTER
COLUMN waiting_rate_per_minute TYPE DECIMAL USING (waiting_rate_per_minute::DECIMAL);

ALTER TABLE driver_profile
ALTER
COLUMN wallet_balance TYPE DECIMAL USING (wallet_balance::DECIMAL);
