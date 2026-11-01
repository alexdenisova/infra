# Postgres Backuper Helm Chart

Creates one CronJob per entry in `backups`. Each job dumps a database with `pg_dump`
and commits the dump to a git repository. See `values.yaml` for the available options.
