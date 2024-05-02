FROM postgres:16-alpine as build

RUN \
    apk update \
    && apk add git

RUN <<EOT cat > /entrypoint.sh
#!/bin/sh
set -eu

git clone \$PB__GITHUB_REPO_URL postgres-backuper
cd postgres-backuper
mkdir -p \$(dirname \$PB__BACKUP_PATH)
pg_dump --inserts \$PB__DB_URL > \$PB__BACKUP_PATH
git config --global user.email "\$PB__GIT_EMAIL"
git config --global user.name "\$PB__GIT_NAME"
git add -A
git commit -m "\$PB__GIT_COMMIT_MSG"
git push
EOT

RUN chmod +x /entrypoint.sh

WORKDIR /workdir
ENTRYPOINT [ "/entrypoint.sh" ]
