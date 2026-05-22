{{- define "rhacs.setExclusions" }}
  {{- $root := index . "root" -}}
  {{- $_exclusions := index . "exclusions" -}}
  {{- $_predefinedExclusions := $root.Files.Get "files/predefined-exclusions.yaml" | fromYaml -}}
  {{- range $key := $_exclusions }}
{{ get $_predefinedExclusions $key | toYaml }}
  {{- end }}
{{- end }}
