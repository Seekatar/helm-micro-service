# apiVersion: logging.banzaicloud.io/v1beta1
# kind: Flow
# metadata:
#   name: {{ include "cas-service.fullname" . }}
# spec:
#   filters:
#     - dedot:
#         de_dot_nested: true
#         de_dot_separator: '-'
#   outputRefs:
#     - clusteroutput-elasticsearch
#   match:
#     - select:
#         labels:
#           run: {{ include "cas-service.fullname" . }}