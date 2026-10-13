-- Trigger 1: Auto-update building count
CREATE OR REPLACE FUNCTION update_building_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE wards SET ward_id = ward_id WHERE ward_id = NEW.ward_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger 2: Audit log for hospitals
CREATE TABLE IF NOT EXISTS hospital_audit (
    audit_id SERIAL PRIMARY KEY,
    hospital_id INT,
    action VARCHAR(20),
    changed_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION log_hospital_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO hospital_audit (hospital_id, action) VALUES (NEW.hospital_id, 'INSERTED');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hospital_audit
AFTER INSERT ON hospitals
FOR EACH ROW EXECUTE FUNCTION log_hospital_change();

-- Trigger 3: Auto-update timestamp on wards
ALTER TABLE wards ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ward_updated
BEFORE UPDATE ON wards
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Trigger 4: Prevent negative population
CREATE OR REPLACE FUNCTION check_positive_population()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.total < 0 THEN
        RAISE EXCEPTION 'Population cannot be negative';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_positive_pop
BEFORE INSERT OR UPDATE ON population
FOR EACH ROW EXECUTE FUNCTION check_positive_population();
