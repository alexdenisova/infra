{{/*
Common labels
*/}}
{{- define "postgres-backuper.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ .Chart.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Name of a single backup's resources. CronJob names are limited to 52 characters.
Usage: include "postgres-backuper.fullname" (list $ $name)
*/}}
{{- define "postgres-backuper.fullname" -}}
{{- $root := index . 0 -}}
{{- $name := index . 1 -}}
{{- printf "%s-%s" $root.Values.postgresBackuper.name $name | trunc 52 | trimSuffix "-" -}}
{{- end }}
