{{- define "kubelet.evictionProfile" }}
  {{- $root := index . "root" }}
  {{- $env := index . "env" }}
  {{- $profile := "" }}
  {{- if eq $env "lab" "dev" }}
    {{- $profile = $root.Files.Get "files/dev-profile.yaml" | fromYaml }}
  {{- else }}
    {{- $profile = $root.Files.Get "files/prod-profile.yaml" | fromYaml }}
  {{- end }}
{{ $profile | toYaml }}
{{- end }}
