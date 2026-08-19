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
Resource name for an MCP: <release>-<mcpKey>
*/}}
{{- define "mcp-tools.resourceName" -}}
{{- printf "%s-%s" .releaseName .mcpKey | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for an MCP resource
*/}}
{{- define "mcp-tools.mcpLabels" -}}
helm.sh/chart: {{ printf "%s-%s" .chartName .chartVersion | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ .mcpKey }}
app.kubernetes.io/instance: {{ .releaseName }}
app.kubernetes.io/managed-by: {{ .releaseService }}
app.kubernetes.io/component: {{ .mcpKey }}
{{- end }}

{{/*
Selector labels for an MCP resource
*/}}
{{- define "mcp-tools.mcpSelectorLabels" -}}
app.kubernetes.io/name: {{ .mcpKey }}
app.kubernetes.io/instance: {{ .releaseName }}
{{- end }}

{{/*
Configmap checksum for rollout on config change
*/}}
{{- define "mcp-tools.configmapChecksum" -}}
{{- toYaml .mcp.env | sha256sum }}
{{- end }}
