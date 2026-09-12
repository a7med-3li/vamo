ALTER TABLE ride
    ADD distance_in_km DOUBLE PRECISION;

ALTER TABLE ride
    ADD duration BIGINT;

ALTER TABLE ride
    ADD vehicle_type SMALLINT;

ALTER TABLE ride
    ALTER COLUMN distance_in_km SET NOT NULL;

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

ALTER TABLE ride
ALTER
COLUMN estimated_fare TYPE DECIMAL USING (estimated_fare::DECIMAL);

ALTER TABLE ride
ALTER
COLUMN final_fare TYPE DECIMAL USING (final_fare::DECIMAL);

ALTER TABLE ride
ALTER
COLUMN status TYPE VARCHAR(255) USING (status::VARCHAR(255));

ALTER TABLE ride
    ALTER COLUMN status DROP NOT NULL;
