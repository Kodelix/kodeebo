create table app.audit_log(id bigint generated always as identity primary key, tenant_id uuid not null);
