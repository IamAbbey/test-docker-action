FROM python:slim-bookworm
LABEL authors="abiodunsotunde"

RUN apt-get update

RUN apt-get install -y wget

RUN wget -q  https://api.github.com/repos/cli/cli/releases/latest \
    && wget -q $(cat latest | grep linux_amd64.tar.gz | grep browser_download_url | grep -v .asc | cut -d '"' -f 4) \
    && tar -xvzf gh*.tar.gz \
    && mv gh*/bin/gh /usr/local/bin/

RUN apt-get install -y git

RUN pip install poetry && \
    poetry config virtualenvs.create false

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]