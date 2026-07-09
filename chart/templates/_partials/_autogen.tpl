{{/*
Secret generation methods from kodus-installer scripts/schema-vars.sh
(hex32 | base64-32 | base64url-32)
*/}}
{{- define "kodus.autogen.hex32" -}}
{{- sha256sum (randAlphaNum 32) -}}
{{- end -}}

{{- define "kodus.autogen.base64-32" -}}
{{- b64enc (randBytes 32) -}}
{{- end -}}

{{- define "kodus.autogen.base64url-32" -}}
{{- $encoded := b64enc (randBytes 32) -}}
{{- replace (replace (trimSuffix "=" (trimSuffix "=" $encoded)) "/" "_") "+" "-" -}}
{{- end -}}
