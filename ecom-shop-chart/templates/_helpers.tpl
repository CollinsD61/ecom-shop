{{/*
Expand the name of the chart.
*/}}
{{- define "ecom-shop-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ecom-shop-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a fully qualified name for a service item.
Usage:
	include "ecom-shop-chart.serviceFullname" (dict "root" $ "name" "user-service")
*/}}
{{- define "ecom-shop-chart.serviceFullname" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- printf "%s-%s" (include "ecom-shop-chart.fullname" $root) $name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ecom-shop-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ecom-shop-chart.labels" -}}
helm.sh/chart: {{ include "ecom-shop-chart.chart" . }}
{{ include "ecom-shop-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels for per-service resources.
Usage:
	include "ecom-shop-chart.serviceLabels" (dict "root" $ "name" $serviceName)
*/}}
{{- define "ecom-shop-chart.serviceLabels" -}}
{{- $root := .root -}}
{{- $name := .name -}}
helm.sh/chart: {{ include "ecom-shop-chart.chart" $root }}
{{ include "ecom-shop-chart.serviceSelectorLabels" (dict "root" $root "name" $name) }}
{{- if $root.Chart.AppVersion }}
app.kubernetes.io/version: {{ $root.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $root.Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ecom-shop-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ecom-shop-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for per-service resources.
*/}}
{{- define "ecom-shop-chart.serviceSelectorLabels" -}}
{{- $root := .root -}}
{{- $name := .name -}}
app.kubernetes.io/name: {{ include "ecom-shop-chart.name" $root }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
app.kubernetes.io/component: {{ $name }}
{{- end }}

{{/*
Create the name of the per-service service account.
*/}}
{{- define "ecom-shop-chart.itemServiceAccountName" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $svc := .svc -}}
{{- if $svc.serviceAccount.create -}}
{{- default (include "ecom-shop-chart.serviceFullname" (dict "root" $root "name" $name)) $svc.serviceAccount.name -}}
{{- else -}}
{{- default "default" $svc.serviceAccount.name -}}
{{- end -}}
{{- end }}
