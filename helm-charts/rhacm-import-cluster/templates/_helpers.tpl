{{- define "rhacm-import-cluster.labels" }}
cloud: auto-detect
vendor: auto-detect
name: {{ required "the value clusterName is required" .Values.clusterName }}
{{- if and (hasKey .Values "clusterSet") (not (empty .Values.clusterSet)) }}
cluster.open-cluster-management.io/clusterset: {{ .Values.clusterSet }}
{{- end }}
{{- range $key, $value := .Values.clusterLabels }}
{{ $key }}: "{{ $value }}"
{{- end }}
{{- end }}
