-- MIT 8103 Advanced Database Systems
-- Portfolio 1: AsterMart relational schema
-- Target: PostgreSQL 16+

BEGIN;

CREATE SCHEMA astermart;
SET search_path TO astermart, public;

CREATE TABLE branch (
    branch_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_code     VARCHAR(12) NOT NULL UNIQUE,
    name            VARCHAR(120) NOT NULL,
    phone           VARCHAR(20) NOT NULL,
    email           VARCHAR(254) NOT NULL UNIQUE,
    address_line    VARCHAR(200) NOT NULL,
    city            VARCHAR(80) NOT NULL,
    state           VARCHAR(80) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_branch_code_format
        CHECK (branch_code ~ '^AST-[A-Z0-9]{3,8}$'),
    CONSTRAINT ck_branch_email_normalized
        CHECK (email = LOWER(email))
);

CREATE TABLE category (
    category_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_category_name_not_blank
        CHECK (BTRIM(name) <> '')
);

CREATE TABLE product (
    product_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id     BIGINT NOT NULL REFERENCES category(category_id),
    sku             VARCHAR(32) NOT NULL UNIQUE,
    name            VARCHAR(160) NOT NULL,
    description     TEXT,
    current_price   NUMERIC(12, 2) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_product_sku_format
        CHECK (sku ~ '^AST-[A-Z0-9-]{4,24}$'),
    CONSTRAINT ck_product_name_not_blank
        CHECK (BTRIM(name) <> ''),
    CONSTRAINT ck_product_price_positive
        CHECK (current_price > 0)
);

CREATE TABLE inventory (
    branch_id        BIGINT NOT NULL REFERENCES branch(branch_id),
    product_id       BIGINT NOT NULL REFERENCES product(product_id),
    quantity_on_hand INTEGER NOT NULL DEFAULT 0,
    reorder_level    INTEGER NOT NULL DEFAULT 0,
    last_counted_at  TIMESTAMPTZ,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (branch_id, product_id),
    CONSTRAINT ck_inventory_quantity_nonnegative
        CHECK (quantity_on_hand >= 0),
    CONSTRAINT ck_inventory_reorder_level_nonnegative
        CHECK (reorder_level >= 0)
);

CREATE TABLE customer (
    customer_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name      VARCHAR(80) NOT NULL,
    last_name       VARCHAR(80) NOT NULL,
    email           VARCHAR(254) NOT NULL UNIQUE,
    phone           VARCHAR(20) NOT NULL UNIQUE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_customer_first_name_not_blank
        CHECK (BTRIM(first_name) <> ''),
    CONSTRAINT ck_customer_last_name_not_blank
        CHECK (BTRIM(last_name) <> ''),
    CONSTRAINT ck_customer_email_normalized
        CHECK (email = LOWER(email))
);

CREATE TABLE customer_address (
    address_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id     BIGINT NOT NULL REFERENCES customer(customer_id),
    label           VARCHAR(40) NOT NULL DEFAULT 'Home',
    address_line_1  VARCHAR(200) NOT NULL,
    address_line_2  VARCHAR(200),
    city            VARCHAR(80) NOT NULL,
    state           VARCHAR(80) NOT NULL,
    postal_code     VARCHAR(12),
    country         VARCHAR(80) NOT NULL DEFAULT 'Nigeria',
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_address_owner UNIQUE (address_id, customer_id),
    CONSTRAINT ck_customer_address_label_not_blank
        CHECK (BTRIM(label) <> '')
);

CREATE TABLE sales_order (
    order_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_number        VARCHAR(24) NOT NULL UNIQUE,
    customer_id         BIGINT NOT NULL REFERENCES customer(customer_id),
    branch_id           BIGINT NOT NULL REFERENCES branch(branch_id),
    delivery_address_id BIGINT,
    order_channel       VARCHAR(12) NOT NULL DEFAULT 'online',
    fulfilment_method   VARCHAR(10) NOT NULL,
    order_status        VARCHAR(16) NOT NULL DEFAULT 'pending',
    subtotal            NUMERIC(14, 2) NOT NULL DEFAULT 0,
    delivery_fee        NUMERIC(12, 2) NOT NULL DEFAULT 0,
    discount_amount     NUMERIC(12, 2) NOT NULL DEFAULT 0,
    grand_total         NUMERIC(14, 2) GENERATED ALWAYS AS
                            (subtotal + delivery_fee - discount_amount) STORED,
    placed_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_address_owner
        FOREIGN KEY (delivery_address_id, customer_id)
        REFERENCES customer_address(address_id, customer_id),
    CONSTRAINT ck_order_number_format
        CHECK (order_number ~ '^ORD-[0-9]{8}-[0-9]{6}$'),
    CONSTRAINT ck_order_channel
        CHECK (order_channel IN ('online', 'in_store')),
    CONSTRAINT ck_order_fulfilment_method
        CHECK (fulfilment_method IN ('delivery', 'pickup')),
    CONSTRAINT ck_order_status
        CHECK (order_status IN (
            'pending', 'confirmed', 'processing', 'ready',
            'dispatched', 'completed', 'cancelled'
        )),
    CONSTRAINT ck_order_amounts_nonnegative
        CHECK (
            subtotal >= 0
            AND delivery_fee >= 0
            AND discount_amount >= 0
            AND subtotal + delivery_fee - discount_amount >= 0
        ),
    CONSTRAINT ck_order_delivery_address
        CHECK (
            (fulfilment_method = 'delivery' AND delivery_address_id IS NOT NULL)
            OR (fulfilment_method = 'pickup' AND delivery_address_id IS NULL)
        )
);

CREATE TABLE order_item (
    order_item_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES sales_order(order_id),
    product_id      BIGINT NOT NULL REFERENCES product(product_id),
    quantity        INTEGER NOT NULL,
    unit_price      NUMERIC(12, 2) NOT NULL,
    line_total      NUMERIC(14, 2) GENERATED ALWAYS AS
                        (quantity * unit_price) STORED,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_order_item_product UNIQUE (order_id, product_id),
    CONSTRAINT ck_order_item_quantity_positive
        CHECK (quantity > 0),
    CONSTRAINT ck_order_item_price_positive
        CHECK (unit_price > 0)
);

CREATE TABLE payment (
    payment_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id           BIGINT NOT NULL REFERENCES sales_order(order_id),
    provider           VARCHAR(60) NOT NULL,
    provider_reference VARCHAR(100) NOT NULL UNIQUE,
    amount             NUMERIC(14, 2) NOT NULL,
    payment_status     VARCHAR(12) NOT NULL DEFAULT 'pending',
    payment_method     VARCHAR(20) NOT NULL,
    attempted_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at       TIMESTAMPTZ,
    CONSTRAINT ck_payment_amount_positive
        CHECK (amount > 0),
    CONSTRAINT ck_payment_status
        CHECK (payment_status IN ('pending', 'successful', 'failed', 'refunded')),
    CONSTRAINT ck_payment_method
        CHECK (payment_method IN ('card', 'transfer', 'cash', 'wallet')),
    CONSTRAINT ck_payment_completion
        CHECK (
            (payment_status IN ('pending', 'failed') AND completed_at IS NULL)
            OR (payment_status IN ('successful', 'refunded') AND completed_at IS NOT NULL)
        )
);

CREATE TABLE fulfilment (
    fulfilment_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id           BIGINT NOT NULL UNIQUE REFERENCES sales_order(order_id),
    fulfilment_status  VARCHAR(16) NOT NULL DEFAULT 'awaiting',
    tracking_reference VARCHAR(80) UNIQUE,
    ready_at           TIMESTAMPTZ,
    dispatched_at      TIMESTAMPTZ,
    completed_at       TIMESTAMPTZ,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_fulfilment_status
        CHECK (fulfilment_status IN (
            'awaiting', 'picking', 'ready', 'dispatched',
            'completed', 'cancelled'
        )),
    CONSTRAINT ck_fulfilment_timestamp_order
        CHECK (
            (dispatched_at IS NULL OR ready_at IS NOT NULL)
            AND (completed_at IS NULL OR ready_at IS NOT NULL)
            AND (completed_at IS NULL OR dispatched_at IS NULL OR completed_at >= dispatched_at)
        )
);

COMMIT;
