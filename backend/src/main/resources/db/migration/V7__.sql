ALTER TABLE corridor
    ADD destination_address VARCHAR(255);

ALTER TABLE corridor
    ADD start_address VARCHAR(255);

ALTER TABLE ride
    ADD dropoff_address VARCHAR(255);

ALTER TABLE ride
    ADD pickup_address VARCHAR(255);

ALTER TABLE vbs
    ADD vbs_address VARCHAR(255);

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
