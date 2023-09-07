FROM python:alpine
LABEL authors="abiodunsotunde"

RUN wget -q  https://api.github.com/repos/cli/cli/releases/latest \
    && wget -q $(cat latest | grep linux_amd64.tar.gz | grep browser_download_url | grep -v .asc | cut -d '"' -f 4) \
    && tar -xvzf gh*.tar.gz \
    && mv gh*/bin/gh /usr/local/bin/ \
    && rm -fr *

RUN apt-get install git

RUN pip install poetry && \
    poetry config virtualenvs.create false

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]