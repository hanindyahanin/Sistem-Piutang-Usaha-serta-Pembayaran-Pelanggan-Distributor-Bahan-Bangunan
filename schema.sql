-- SQL untuk Supabase PostgreSQL
-- Entitas utama: pelanggan, invoice, pembayaran
-- Detail invoice dan produk dapat dibuat sebagai tabel pendukung

CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    customer_name VARCHAR(150) NOT NULL,
    address TEXT,
    phone VARCHAR(30),
    credit_limit NUMERIC(18,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'Aktif' CHECK (status IN ('Aktif', 'Waspada', 'NonAktif')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    product_code VARCHAR(30) UNIQUE NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(50),
    unit VARCHAR(20),
    unit_price NUMERIC(18,2) NOT NULL,
    stock_qty NUMERIC(18,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoices (
    id SERIAL PRIMARY KEY,
    invoice_code VARCHAR(30) UNIQUE NOT NULL,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    total_value NUMERIC(18,2) NOT NULL DEFAULT 0,
    discount_value NUMERIC(18,2) DEFAULT 0,
    net_value NUMERIC(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) DEFAULT 'Belum Dibayar' CHECK (status IN ('Belum Dibayar', 'Sebagian Dibayar', 'Lunas', 'Overdue')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    qty NUMERIC(18,2) NOT NULL,
    unit_price NUMERIC(18,2) NOT NULL,
    subtotal NUMERIC(18,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    payment_code VARCHAR(30) UNIQUE NOT NULL,
    invoice_id INT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    payment_date DATE NOT NULL,
    amount NUMERIC(18,2) NOT NULL,
    discount_applied NUMERIC(18,2) DEFAULT 0,
    payment_method VARCHAR(30) DEFAULT 'Transfer',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_payments_invoice_id ON payments(invoice_id);

-- View ringkasan piutang untuk dashboard
CREATE OR REPLACE VIEW invoice_summary AS
SELECT
    i.id,
    i.invoice_code,
    c.customer_name,
    i.invoice_date,
    i.due_date,
    i.total_value,
    COALESCE(SUM(p.amount), 0) AS total_paid,
    (i.total_value - COALESCE(SUM(p.amount), 0)) AS remaining_balance,
    CASE
        WHEN (i.total_value - COALESCE(SUM(p.amount), 0)) <= 0 THEN 'Lunas'
        WHEN COALESCE(SUM(p.amount), 0) > 0 THEN 'Sebagian Dibayar'
        WHEN CURRENT_DATE > i.due_date THEN 'Overdue'
        ELSE 'Belum Dibayar'
    END AS status
FROM invoices i
LEFT JOIN customers c ON c.id = i.customer_id
LEFT JOIN payments p ON p.invoice_id = i.id
GROUP BY i.id, c.customer_name, i.invoice_code, i.invoice_date, i.due_date, i.total_value;

-- Trigger untuk menghitung status otomatis invoice berdasarkan pembayaran
CREATE OR REPLACE FUNCTION update_invoice_status()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE invoices
    SET status = CASE
        WHEN (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE invoice_id = NEW.invoice_id) >= total_value THEN 'Lunas'
        WHEN (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE invoice_id = NEW.invoice_id) > 0 THEN 'Sebagian Dibayar'
        WHEN CURRENT_DATE > due_date THEN 'Overdue'
        ELSE 'Belum Dibayar'
    END
    WHERE id = NEW.invoice_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_invoice_status ON payments;
CREATE TRIGGER trg_update_invoice_status
AFTER INSERT OR UPDATE OF amount ON payments
FOR EACH ROW
EXECUTE FUNCTION update_invoice_status();

-- Diskon akuntansi 2/10, n/30
-- Jika pelanggan membayar dalam 10 hari sejak tanggal invoice, maka diskon 2% diterapkan.
-- Logika dapat dihitung di aplikasi frontend maupun backend sesuai kebutuhan.
