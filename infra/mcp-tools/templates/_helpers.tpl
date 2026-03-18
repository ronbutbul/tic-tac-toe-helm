{{/*
Create a default fully qualified app name.
*/}}
{{- define "mcp-tools.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- if not .Values.nameOverride }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mcp-tools.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "mcp-tools.selectorLabels" . }}
{{- if .Chart.Version }}
app.kubernetes.io/version: {{ .Chart.Version | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mcp-tools.selectorLabels" -}}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Compute the RemoteMCPServer name for each subchart.
These match the fullname produced by each subchart's _helpers.tpl.
*/}}
{{- define "mcp-tools.elasticsearch-mcp.remoteName" -}}
{{- if (index .Values "elasticsearch-mcp" "fullnameOverride") }}
{{- index .Values "elasticsearch-mcp" "fullnameOverride" | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-elasticsearch-mcp" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "mcp-tools.mongodb-mcp.remoteName" -}}
{{- if (index .Values "mongodb-mcp" "fullnameOverride") }}
{{- index .Values "mongodb-mcp" "fullnameOverride" | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-mongodb-mcp" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "mcp-tools.kafka-mcp.remoteName" -}}
{{- if (index .Values "kafka-mcp" "fullnameOverride") }}
{{- index .Values "kafka-mcp" "fullnameOverride" | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-kafka-mcp" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
