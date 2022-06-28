FROM alpine:3.10@sha256:4ff3ca91275773af45cb4b0834e12b7eb47d1c18f770a0b151381cd227f4c253

ENV HCL2JSON_BIN /usr/bin/hcl2json
ENV HCL2JSON_VERSION v0.3.4
ENV HCL2JSON_MD5 f0246f19b894fb9d57afb13085948a87

ENV TFUPDATE_VERSION=0.6.5
ENV TFUPDATE_MD5 ed870ed3ea956b75f0f461707bb75b42

RUN apk add --no-cache \
        bash \
        jq \
        git \
        github-cli

RUN wget https://github.com/tmccombs/hcl2json/releases/download/${HCL2JSON_VERSION}/hcl2json_linux_amd64 \
        -O ${HCL2JSON_BIN} && \
        chmod +x ${HCL2JSON_BIN} && \
        md5sum ${HCL2JSON_BIN} | grep -qF -- "${HCL2JSON_MD5}"

RUN wget -O- https://github.com/minamijoyo/tfupdate/releases/download/v${TFUPDATE_VERSION}/tfupdate_${TFUPDATE_VERSION}_linux_amd64.tar.gz \
        | tar -zxvf - tfupdate -C /usr/bin \
        && md5sum /usr/bin/tfupdate | grep -qF -- "${TFUPDATE_MD5}"


COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]