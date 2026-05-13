{{- define "test-chart-2.setLabels" -}}
  {{- range $key, $val := . }}
{{ $key }}: {{ $val }}
  {{- end }}
{{- end }}
