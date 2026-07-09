{{- define "rhacs.setLabels" -}}
  {{- range $key, $val := . }}
{{ $key }}: {{ $val }}
  {{- end }}
{{- end }}
