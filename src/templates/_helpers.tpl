{{/*
Expand the name of the chart.
*/}}
{{- define "test-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "test-service.fullname" -}}
{{- required "Supply service name" .Values.serviceName }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "test-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "test-service.labels" -}}
helm.sh/chart: {{ include "test-service.chart" . }}
{{ include "test-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "test-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "test-service.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "test-service.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create -}}
      serviceAccountName: {{ default (include "test-service.fullname" .) .Values.serviceAccount.name }}
  {{- else if .Values.serviceAccount.name -}}
      serviceAccountName: {{ .Values.serviceAccount.name }}
  {{- end }}
{{- end }}

{{/*
Option for NodePort
*/}}
{{- define "test-service.nodePort" -}}
  {{- if .Values.service.nodePort -}}
      nodePort: {{ .Values.service.nodePort }}
  {{- end -}}
{{- end -}}

{{/*
Add secretRef
*/}}
{{- define "test-service.secret" -}}
  {{- if .Values.secrets }}
            - secretRef:
                name: {{ include "test-service.fullname" . }}-secret
  {{- end -}}
{{- end -}}

{{/*
Add volumes, allow empty hostpath and vol
*/}}
{{- define "test-service.volumesJson" -}}
  {{- if .Values.volumesJson }}
      volumes:
    {{- range .Values.volumesJson }}
      {{- if hasKey . "hostPath" }}
      {{- if .hostPath }}
      - name: {{ coalesce .hostPath "???" | trim | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
        hostPath:
          path: {{ .hostPath }}
      {{- end -}}
      {{- else if and (hasKey . "vol") .vol.networkPath }}
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
{{- define "test-service.volumeMountsJson" -}}
  {{- if .Values.volumesJson }}
          volumeMounts:
    {{- range .Values.volumesJson }}
      {{- if hasKey . "hostPath" }}
      {{- if .hostPath }}
          - name: {{ trim .hostPath | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
            mountPath: {{ .hostPath }}
      {{- end -}}
      {{- else if and (hasKey . "vol") .vol.networkPath }}
          - name: {{ trim .vol.networkPath | replace "\\" "/" | replace "/" "-" | replace "." "-" | trimAll "-" | lower}}
            mountPath: {{ .vol.mountPath }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Add host path volumes from comma-delimited string
*/}}
{{- define "test-service.volumesHostPath" -}}
  {{- if and .Values.hostPaths }}
    {{- if and .Values.hostPaths.volumes }}
      volumes:
    {{- range $index, $v := splitList "," .Values.hostPaths.volumes }}
        - hostPath:
            path: {{ $v }}
          name: {{ printf "volume-%d" (add $index 1) }}
    {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Add host path volumeMounts from comma-delimited string
*/}}
{{- define "test-service.volumeMountsHostPath" -}}
  {{- if .Values.hostPaths }}
    {{- if .Values.hostPaths.mounts }}
          volumeMounts:
    {{- range $index, $v :=splitList "," .Values.hostPaths.mounts }}
            - mountPath: {{ . }}
              name: {{ printf "volume-%d" (add $index 1) }}
    {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
