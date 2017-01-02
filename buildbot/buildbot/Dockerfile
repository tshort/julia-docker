FROM python:2

RUN mkdir -p /buildbot
WORKDIR /buildbot

ARG buildbot_branch=master

# First, grab builddeps and buildbot itself
RUN apt update && apt install -y git libsqlite3-dev libssl-dev
RUN pip install --upgrade pip
RUN pip install buildbot[tls] buildbot-www buildbot-waterfall-view \
                buildbot-console-view urllib3[secure] requests ipython

# Clone/configure buildbot
RUN git clone -b ${buildbot_branch} https://github.com/staticfloat/julia-buildbot.git .
RUN buildbot create-master master

# Install secret files (Note, you must have unlocked this repo, as these are all
# encrypted, and failing to do so will give strange unicode errors!)
COPY buildbot_secret.py /buildbot/master
COPY julia.gpg /root/
COPY awssecret /root/.awssecret
RUN mkdir -p /root/.gnupg
RUN gpg --import /root/julia.gpg

ENTRYPOINT []
CMD (while true; do sleep 1; tail -f master/twistd.log 2>/dev/null; done &) && buildbot start --nodaemon master