{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "maira.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "maira.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "maira.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "maira.labels" -}}
app.kubernetes.io/name: {{ include "maira.fullname" . }}
helm.sh/chart: {{ include "maira.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "maira.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "maira.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default (include "maira.fullname" .) .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified maira api full name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "maira.api.fullname" -}}
{{- $component := "api" -}}
{{- printf "%s-%s" (include "maira.fullname" . | trunc (sub 62 (len $component) | int) | trimSuffix "-" ) $component | trimSuffix "-" -}}
{{- end -}}

{{/*
Maira api labels
*/}}
{{- define "maira.api.labels" -}}
app.kubernetes.io/name: {{ include "maira.api.fullname" . }}
helm.sh/chart: {{ include "maira.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ include "maira.fullname" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create a fully qualified maira cloud worker full name.
Truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "maira.cloud_worker.fullname" -}}
{{- $component := "cloud-worker" -}}
{{- printf "%s-%s" (include "maira.fullname" . | trunc (sub 62 (len $component) | int) | trimSuffix "-" ) $component | trimSuffix "-" -}}
{{- end -}}

{{/*
Maira cloud worker labels
*/}}
{{- define "maira.cloud_worker.labels" -}}
app.kubernetes.io/name: {{ include "maira.cloud_worker.fullname" . }}
helm.sh/chart: {{ include "maira.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ include "maira.fullname" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create a fully qualified maira test app full name.
Truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "maira.testapp.fullname" -}}
{{- $component := "testapp" -}}
{{- printf "%s-%s" (include "maira.fullname" . | trunc (sub 62 (len $component) | int) | trimSuffix "-" ) $component | trimSuffix "-" -}}
{{- end -}}

{{/*
Maira testapp labels
*/}}
{{- define "maira.testapp.labels" -}}
app.kubernetes.io/name: {{ include "maira.testapp.fullname" . }}
helm.sh/chart: {{ include "maira.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ include "maira.fullname" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create a fully qualified maira ui full name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "maira.ui.fullname" -}}
{{- $component := "ui" -}}
{{- printf "%s-%s" (include "maira.fullname" . | trunc (sub 62 (len $component) | int) | trimSuffix "-" ) $component | trimSuffix "-" -}}
{{- end -}}

{{/*
Maira ui labels
*/}}
{{- define "maira.ui.labels" -}}
app.kubernetes.io/name: {{ include "maira.ui.fullname" . }}
helm.sh/chart: {{ include "maira.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ include "maira.fullname" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create a fully qualified maira site manager full name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "maira.sitemanager.fullname" -}}
{{- $component := "sitemanager" -}}
{{- printf "%s-%s" (include "maira.fullname" . | trunc (sub 62 (len $component) | int) | trimSuffix "-" ) $component | trimSuffix "-" -}}
{{- end -}}

{{/*
Maira sitemanager labels
*/}}
{{- define "maira.sitemanager.labels" -}}
app.kubernetes.io/name: {{ include "maira.sitemanager.fullname" . }}
helm.sh/chart: {{ include "maira.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ include "maira.fullname" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
