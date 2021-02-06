{{/*
Expand the name of the chart.
*/}}
{{- define "cas-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cas-service.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "cas-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cas-service.labels" -}}
helm.sh/chart: {{ include "cas-service.chart" . }}
{{ include "cas-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cas-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cas-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cas-service.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create }}
      {{- default (include "cas-service.fullname" .) .Values.serviceAccount.name }}
  {{- else }}
      {{- default "default" .Values.serviceAccount.name }}
  {{- end }}
{{- end }}

{{/*
Option for NodePort
*/}}
{{- define "cas-service.nodePort" -}}
  {{- if .Values.service.nodePort -}}
      nodePort: {{ .Values.service.nodePort }}
  {{- end -}}
{{- end -}}

{{/*
Add secretRef
*/}}
{{- define "cas-service.secret" -}}
  {{- if .Values.secrets }}
            - secretRef:
                name: {{ include "cas-service.fullname" . }}-secret
  {{- end -}}
{{- end -}}

{{/*
Add volumes
*/}}
{{- define "cas-service.volumes" -}}
  {{- if .Values.volumes }}
      volumes:
    {{- range .Values.volumes }}
      {{- if .hostPath }}
      - name: {{ coalesce .hostPath "???" | trim | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
        hostPath:
          path: {{ .hostPath }}
      {{- else }}
      - name: {{ coalesce (required "hostPath or vol required in volume" .vol)  "???" | trim | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
        flexVolume:
          driver: "fstab/cifs"
          fsType: "cifs"
          secretRef:
            name: {{ .secret }}
          options:
            networkPath: {{ .vol }}
            mountOptions: "dir_mode={{ .dmode }},file_mode={{ .fmode }}{{ empty .ver | not | ternary (cat ",vers=" .ver)  "" | nospace }}"
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Add volumeMounts
*/}}
{{- define "cas-service.volumeMounts" -}}
  {{- if .Values.volumes }}
          volumeMounts:
    {{- range .Values.volumes }}
      {{- if .hostPath }}
          - name: {{ trim .hostPath | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
            mountPath: {{ .hostPath }}
      {{- else }}
          - name: {{ trim .vol | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
            mountPath: {{ .path }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}