FROM postgres:16-alpine

RUN \
    apk update \
    && apk add --no-cache git \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/* /root/.cache

RUN <<EOT cat > /entrypoint.sh
#!/bin/sh
set -eu

git clone "\$PB__GITHUB_REPO_URL" postgres-backuper
cd postgres-backuper
mkdir -p \$(dirname "\$PB__BACKUP_PATH")
pg_dump --inserts "\$PB__DB_URL" > "\$PB__BACKUP_PATH"
git config --global user.email "\$PB__GIT_EMAIL"
git config --global user.name "\$PB__GIT_NAME"
git add -A
if git diff --cached --quiet; then
  echo "No changes to back up"
  exit 0
fi
git commit -m "\$PB__GIT_COMMIT_MSG"

# Other backup jobs may push to the same repo at the same time
for attempt in 1 2 3 4 5; do
  git pull --rebase && git push && exit 0
  sleep \$((attempt * 10))
done
exit 1
EOT

RUN chmod +x /entrypoint.sh

WORKDIR /workdir
ENTRYPOINT [ "/entrypoint.sh" ]
