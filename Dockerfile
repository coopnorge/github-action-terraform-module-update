FROM alpine:3.10

ENV HCL2JSON_BIN /usr/bin/hcl2json
ENV HCL2JSON_VERSION v0.3.4
ENV HCL2JSON_MD5 f0246f19b894fb9d57afb13085948a87

RUN apk add --no-cache \
        bash \
        jq \
        git \
        github-cli

RUN wget https://github.com/tmccombs/hcl2json/releases/download/${HCL2JSON_VERSION}/hcl2json_linux_amd64 \
        -O ${HCL2JSON_BIN} && \
        chmod +x ${HCL2JSON_BIN} && \
        md5sum ${HCL2JSON_BIN} | grep -qF -- "${HCL2JSON_MD5}"

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]