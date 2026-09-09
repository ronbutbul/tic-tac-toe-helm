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
Fully qualified image reference. Registry is optional so that plain "repo:tag"
images (e.g. docker.io library images) still work. Pass "section" to name the
values block in the error messages; it defaults to "mcps".
*/}}
{{- define "mcp-tools.mcpImage" -}}
{{- $section := default "mcps" .section -}}
{{- $img := required (printf "%s.%s.image is required" $section .mcpKey) .mcp.image -}}
{{- $repo := required (printf "%s.%s.image.repository is required" $section .mcpKey) $img.repository -}}
{{- $tag := required (printf "%s.%s.image.tag is required" $section .mcpKey) $img.tag -}}
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

{{/*
Resource name for a proxy: proxies.<key>.name, defaulting to the key.

Deliberately NOT release-prefixed like "mcp-tools.resourceName". A proxy is
addressed from outside the chart -- a ModelConfig baseUrl points at its Service
DNS name -- so the name is part of its contract, exactly like a ModelConfig's.
Call with: (dict "proxy" $proxy "proxyKey" $key)
*/}}
{{- define "mcp-tools.proxyName" -}}
{{- default .proxyKey .proxy.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Listen/container/Service port for a proxy. Defaults to 8080 when unset.
*/}}
{{- define "mcp-tools.proxyPort" -}}
{{- dig "service" "port" 8080 .proxy | int }}
{{- end }}

{{/*
Container args for an aws-sigv4-proxy, built from proxies.<key>.sigv4.

Set proxies.<key>.args to bypass this entirely and pass raw args instead.
--port is derived from the same value as the containerPort and the Service
target, so the three can never drift apart.
Call with: (dict "proxy" $proxy "proxyKey" $key)
*/}}
{{- define "mcp-tools.proxyArgs" -}}
{{- $sig := dig "sigv4" dict .proxy -}}
{{- $host := required (printf "proxies.%s.sigv4.host is required (the upstream AWS endpoint)" .proxyKey) $sig.host -}}
- --port={{ dig "listenAddress" "0.0.0.0" $sig }}:{{ include "mcp-tools.proxyPort" (dict "proxy" .proxy) }}
- --name={{ required (printf "proxies.%s.sigv4.name is required (the AWS service to sign for, e.g. bedrock)" .proxyKey) $sig.name }}
- --region={{ required (printf "proxies.%s.sigv4.region is required" .proxyKey) $sig.region }}
- --host={{ $host }}
- --sign-host={{ default $host $sig.signHost }}
{{- range $header := (default list $sig.strip) }}
- --strip={{ $header }}
{{- end }}
{{- if dig "verbose" false $sig }}
- --verbose
{{- end }}
{{- if dig "logFailedRequests" false $sig }}
- --log-failed-requests
{{- end }}
{{- if dig "logSigningProcess" false $sig }}
- --log-signing-process
{{- end }}
{{- range $arg := (default list .proxy.extraArgs) }}
- {{ $arg | quote }}
{{- end }}
{{- end }}
