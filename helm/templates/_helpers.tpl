{{- define "bestrongapp.fullname" -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bestrongapp.deploymentName" -}}
{{- printf "%s-deploy" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bestrongapp.serviceName" -}}
{{- printf "%s-svc" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bestrongapp.ingressName" -}}
{{- printf "%s-ing" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}