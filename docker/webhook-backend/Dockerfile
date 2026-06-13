FROM registry.access.redhat.com/ubi10/ubi-minimal:10.2

LABEL product.description="Generic Webhook Backend" \
      product.display-name=GenericWebhookBackend \
      product.version=1.0

ENV HOME /opt/webhook-backend
ENV APP_ROOT $HOME
WORKDIR $HOME

USER root
COPY requirements.txt \
     webhook-backend.py \
     ./

RUN touch /etc/dnf/dnf.conf \
 && microdnf -y --setopt=tsflags=nodocs install python3.12 python3.12-pip procps \
 && microdnf -y clean all && rm -rf /var/cache/yum \
 && ln -sf /usr/bin/python3.12 /usr/bin/python3 \
 && pip3 install -r ./requirements.txt \
 && python3.12 -m py_compile ./*.py \
 && chown -R 8001:root $HOME \
 && chmod -R g+rw $HOME \
 && chmod ug+x ./webhook-backend.py

USER 8001
EXPOSE 8443/tcp
ENTRYPOINT ["python3.12", "./webhook-backend.py"]
