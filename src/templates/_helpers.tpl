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
{{- required "Supply service name" .Values.serviceName }}
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
app.kubernetes.io/name: {{ include "cas-service.fullname" . }}
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
Add volumes, allow empty hostpath and vol
*/}}
{{- define "cas-service.volumesJson" -}}
  {{- if .Values.volumesJson }}
      volumes:
    {{- range .Values.volumesJson }}
      {{- if hasKey . "hostPath" }}
      {{- if .hostPath }}
      - name: {{ coalesce .hostPath "???" | trim | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
        hostPath:
          path: {{ .hostPath }}
      {{- end -}}
      {{- else if hasKey . "vol" -}}
      {{- if .vol }}
      - name: {{ coalesce .vol.networkPath "???" | trim | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
        flexVolume:
          driver: "fstab/cifs"
          fsType: "cifs"
          secretRef:
            name: "{{ .vol.secret }}"
          options:
            networkPath: {{ .vol.networkPath }}
            mountOptions: "dir_mode={{ .vol.dirMode }},file_mode={{ .vol.fileMode }}{{ empty .vol.ver | not | ternary (cat ",vers=" .vol.smbVersion)  "" | nospace }}"
      {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Add volumeMounts
*/}}
{{- define "cas-service.volumeMountsJson" -}}
  {{- if .Values.volumesJson }}
          volumeMounts:
    {{- range .Values.volumesJson }}
      {{- if hasKey . "hostPath" }}
      {{- if .hostPath }}
          - name: {{ trim .hostPath | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
            mountPath: {{ .hostPath }}
      {{- end -}}
      {{- else if hasKey . "vol"}}
          - name: {{ trim .vol.networkPath | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
            mountPath: {{ .vol.mountPath }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}