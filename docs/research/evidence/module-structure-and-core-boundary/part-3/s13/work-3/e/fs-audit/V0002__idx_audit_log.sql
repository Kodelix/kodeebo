create index on app.audit_log(id);
insert into app.audit_log values (1, now());
