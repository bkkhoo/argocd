{{- define "log-receiver.setLabels" -}}
  {{- range $key, $val := . }}
{{ $key }}: {{ $val }}
  {{- end }}
{{- end }}
