{{- define "excalidash.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "excalidash.fullname" -}}
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

{{- define "excalidash.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "excalidash.labels" -}}
helm.sh/chart: {{ include "excalidash.chart" . }}
app.kubernetes.io/name: {{ include "excalidash.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "excalidash.selectorLabels" -}}
app.kubernetes.io/name: {{ include "excalidash.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "excalidash.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "excalidash.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "excalidash.secretName" -}}
{{- if .Values.secret.create -}}
{{- default (printf "%s-secrets" (include "excalidash.fullname" .)) .Values.secret.name -}}
{{- else -}}
{{- .Values.secret.name -}}
{{- end -}}
{{- end -}}

{{- define "excalidash.frontendServiceName" -}}
{{- printf "%s-frontend" (include "excalidash.fullname" .) -}}
{{- end -}}

{{- define "excalidash.backendServiceName" -}}
{{- printf "%s-backend" (include "excalidash.fullname" .) -}}
{{- end -}}

{{- define "excalidash.backendPvcName" -}}
{{- printf "%s-backend-data" (include "excalidash.fullname" .) -}}
{{- end -}}

{{- define "excalidash.frontendImage" -}}
{{- $registry := .Values.frontend.image.registry -}}
{{- $repository := .Values.frontend.image.repository -}}
{{- $tag := default .Chart.AppVersion .Values.frontend.image.tag -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end -}}

{{- define "excalidash.backendImage" -}}
{{- $registry := .Values.backend.image.registry -}}
{{- $repository := .Values.backend.image.repository -}}
{{- $tag := default .Chart.AppVersion .Values.backend.image.tag -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end -}}

{{- define "excalidash.computedBackendUrl" -}}
{{- if .Values.frontend.env.BACKEND_URL -}}
{{- .Values.frontend.env.BACKEND_URL -}}
{{- else if eq .Values.deploymentMode "combined" -}}
{{- printf "127.0.0.1:%v" .Values.backend.service.port -}}
{{- else -}}
{{- printf "%s:%v" (include "excalidash.backendServiceName" .) .Values.backend.service.port -}}
{{- end -}}
{{- end -}}

{{- define "excalidash.secretEnvFrom" -}}
{{- if or .Values.secret.create .Values.secret.name }}
- secretRef:
    name: {{ include "excalidash.secretName" . }}
{{- end -}}
{{- end -}}

{{- define "excalidash.renderEnv" -}}
{{- $ctx := .context -}}
{{- $envMap := .envMap | default dict -}}
{{- range $key, $value := $envMap }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- range $item := (.extraEnv | default list) }}
{{ toYaml (list $item) }}
{{- end }}
{{- end -}}
