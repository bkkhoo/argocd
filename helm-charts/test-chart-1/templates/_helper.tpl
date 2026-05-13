{{- define "test-chart-1.setLabels" -}}
  {{- range $key, $val := . }}
{{ $key }}: {{ $val }}
  {{- end }}
{{- end }}
