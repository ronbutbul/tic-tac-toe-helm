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
The full ConfigMap payload for an MCP, as YAML.
Precedence: extraConfig > env > chart defaults. Building it as one dict (rather
than emitting three ranges) is what keeps duplicate keys out of the ConfigMap
and lets DO_NOT_TRACK actually be overridden.
*/}}
{{- define "mcp-tools.configmapData" -}}
{{- $data := dict "DO_NOT_TRACK" "1" -}}
{{- range $k, $v := (default dict .mcp.env) -}}
{{- $_ := set $data $k (toString $v) -}}
{{- end -}}
{{- range $k, $v := (default dict .mcp.extraConfig) -}}
{{- $_ := set $data $k (toString $v) -}}
{{- end -}}
{{- toYaml $data -}}
{{- end }}

{{/*
Configmap checksum for rollout on config change. Hashes exactly what the
ConfigMap contains, so any change to it restarts the pods.
*/}}
{{- define "mcp-tools.configmapChecksum" -}}
{{- include "mcp-tools.configmapData" . | sha256sum }}
{{- end }}

{{/*
Container port for an MCP. Defaults to 8000 when service.port is unset.
*/}}
{{- define "mcp-tools.mcpPort" -}}
{{- dig "service" "port" 8000 .mcp | int }}
{{- end }}

{{/*
Fully qualified image reference for an MCP. Registry is optional so that
plain "repo:tag" images (e.g. docker.io library images) still work.
*/}}
{{- define "mcp-tools.mcpImage" -}}
{{- $img := required (printf "mcps.%s.image is required" .mcpKey) .mcp.image -}}
{{- $repo := required (printf "mcps.%s.image.repository is required" .mcpKey) $img.repository -}}
{{- $tag := required (printf "mcps.%s.image.tag is required" .mcpKey) $img.tag -}}
{{- if $img.registry -}}
{{- printf "%s/%s:%s" $img.registry $repo (toString $tag) -}}
{{- else -}}
{{- printf "%s:%s" $repo (toString $tag) -}}
{{- end -}}
{{- end }}

{{/*
An agent's systemMessage, loaded from agents-rules/<agentKey>.md at the chart root.
Call with: (dict "root" $ "agentKey" "elasticsearch")
Fails loudly when the rules file is missing or empty, so a typo can never
silently ship an agent with no instructions.
*/}}
{{- define "mcp-tools.agentSystemMessage" -}}
{{- $path := printf "agents-rules/%s.md" .agentKey -}}
{{- $rules := .root.Files.Get $path -}}
{{- if not (trim $rules) -}}
{{- fail (printf "agent %q: rules file %q is missing or empty" .agentKey $path) -}}
{{- end -}}
{{- $block := $rules | trimSuffix "\n" | nindent (int .indent) -}}
{{- regexReplaceAll "[ \t]+\n" $block "\n" -}}
{{- end }}

{{/*
spec.declarative.memory for an agent. Gated on agents.<key>.memory.enabled.
Accepts modelConfigRef (kagent convention) or modelConfig. It must name a
ModelConfig backed by an EMBEDDING model -- it generates the memory vectors,
not the chat completions. Required by the CRD whenever memory is enabled.
Call with: (dict "agent" $agent "agentKey" $agentKey)
*/}}
{{- define "mcp-tools.agentMemory" -}}
{{- $m := dig "memory" dict .agent -}}
{{- if dig "enabled" false $m -}}
{{- $ref := $m.modelConfigRef | default $m.modelConfig -}}
memory:
  modelConfig: {{ required (printf "agents.%s.memory.modelConfigRef is required when memory is enabled" .agentKey) $ref }}
  ttlDays: {{ dig "ttlDays" 15 $m | int }}
{{- end -}}
{{- end }}

{{/*
spec.declarative.context.compaction for an agent.

Reads agents.<key>.compaction (kagent convention) and falls back to
agents.<key>.context.compaction. Presence of the block enables it, matching
upstream; set enabled: false to switch it off without deleting the config.
Only keys actually set are emitted, so the CRD's own defaults
(compactionInterval 5, overlapSize 2) apply to whatever is left out.
*/}}
{{- define "mcp-tools.agentContext" -}}
{{- $comp := default (dig "context" "compaction" dict .agent) .agent.compaction -}}
{{- if and $comp (dig "enabled" true $comp) -}}
{{- $summ := dig "summarizer" dict $comp -}}
context:
  compaction:
    {{- with $comp.compactionInterval }}
    compactionInterval: {{ . | int }}
    {{- end }}
    {{- with $comp.overlapSize }}
    overlapSize: {{ . | int }}
    {{- end }}
    {{- with $comp.eventRetentionSize }}
    eventRetentionSize: {{ . | int }}
    {{- end }}
    {{- with $comp.tokenThreshold }}
    tokenThreshold: {{ . | int }}
    {{- end }}
    {{- $sref := $summ.modelConfigRef | default $summ.modelConfig -}}
    {{- if or $sref $summ.promptTemplate }}
    summarizer:
      {{- with $sref }}
      modelConfig: {{ . }}
      {{- end }}
      {{- with $summ.promptTemplate }}
      promptTemplate: {{ . | quote }}
      {{- end }}
    {{- end }}
{{- end -}}
{{- end }}
